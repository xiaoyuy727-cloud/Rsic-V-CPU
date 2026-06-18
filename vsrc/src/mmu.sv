`ifdef VERILATOR
`include "include/common.sv"
`endif

module mmu import common::*;(
    input  logic clk,
    input  logic reset,
    input  logic flush,

    input  dbus_req_t  cpu_req,
    output dbus_resp_t cpu_resp,

    output dbus_req_t  mem_req,
    input  dbus_resp_t mem_resp,

    input  logic [1:0]  privil_mode,
    input  logic [63:0] satp,
    input  access_type_t access_type,

    output logic        page_fault,
    output logic [63:0] fault_addr,
    output logic [3:0]  fault_cause
);

    typedef struct packed {
        logic valid;

        logic [26:0] vpn;
        logic [43:0] ppn;

        logic [1:0] page_level;
            // 0 = 4KB
            // 1 = 2MB
            // 2 = 1GB

        logic r;
        logic w;
        logic x;
        logic u;

    } tlb_entry_t;

    typedef enum logic [3:0] {
        IDLE   = 4'd0,
        REQ_2  = 4'd1,
        WAIT_2 = 4'd2,
        REQ_1  = 4'd3,
        WAIT_1 = 4'd4,
        REQ_0  = 4'd5,
        WAIT_0 = 4'd6,
        REQ_P  = 4'd7,
        WAIT_P = 4'd8,
        RESP   = 4'd9
    } state_t;


    task automatic raise_page_fault;
        input logic [63:0] badaddr;
        begin
            page_fault <= 1'b1;
            fault_addr <= badaddr;

            case (access_type)
                FETCH: fault_cause <= 4'd12;
                LOAD:  fault_cause <= 4'd13;
                STORE: fault_cause <= 4'd15;
                default:      fault_cause <= 4'd13;
            endcase

            saved_req  <= '0;
            saved_resp <= '0;
            paddr      <= 64'b0;
            pt_addr    <= 64'b0;
            cur        <= RESP;
        end
    endtask

    tlb_entry_t tlb[8];

    state_t cur;

    dbus_req_t  saved_req;
    dbus_resp_t saved_resp;

    logic [8:0]  vpn2, vpn1, vpn0;
    logic [63:0] root_addr;
    logic [63:0] pt_addr;
    logic [63:0] pte;
    logic [63:0] paddr;

    // ---- TLB 信号 ----
    logic        tlb_hit;
    logic [63:0] tlb_paddr;
    logic [2:0]  tlb_replace_ptr;

    logic translate;

    logic pte_v;
    logic pte_r;
    logic pte_w;
    logic pte_x;
    logic pte_u;
    logic pte_a;
    logic pte_d;
    logic pte_invalid;
    logic pte_leaf;
    logic perm_fault;
    logic us_fault;
    logic ad_fault;
    logic superpage_misaligned_l2;
    logic superpage_misaligned_l1;

    assign translate =
        cpu_req.valid &&
        (privil_mode != 2'b11) &&
        (satp[63:60] == 4'd8);

    assign pte_v = mem_resp.data[0];
    assign pte_r = mem_resp.data[1];
    assign pte_w = mem_resp.data[2];
    assign pte_x = mem_resp.data[3];
    assign pte_u = mem_resp.data[4];
    assign pte_a = mem_resp.data[6];
    assign pte_d = mem_resp.data[7];

    // V 位 + W/R 合法性检查
    assign pte_invalid = !pte_v || (pte_w && !pte_r);

    // leaf = R or X set
    assign pte_leaf = pte_r || pte_x;

    // ---- 权限检查 ----
    always_comb begin
        perm_fault = 1'b0;

        if (pte_leaf) begin
            case (access_type)
                FETCH: perm_fault = !pte_x;
                LOAD:  perm_fault = !pte_r;
                STORE: perm_fault = !pte_w;
                default:      perm_fault = 1'b1;
            endcase
        end
    end

    // ---- U/S 权限检查 ----
    always_comb begin
        us_fault = 1'b0;

        if (pte_leaf) begin
            // U-mode 只能访问 U=1 的页
            if (privil_mode == 2'b00 && !pte_u)
                us_fault = 1'b1;

            // S-mode 不能访问 U=1 的页（暂不考虑 SUM/MXR）
            if (privil_mode == 2'b01 && pte_u)
                us_fault = 1'b1;
        end
    end

//    // ---- A/D 位检查 ----
//    // A=0 的页不能被访问，D=0 的页不能被写入
//    always_comb begin
//        ad_fault = 1'b0;
//
//        if (pte_leaf) begin
//            if (!pte_a)
//                ad_fault = 1'b1;
//            else if (access_type == STORE && !pte_d)
//                ad_fault = 1'b1;
//        end
//    end


    // ---- A/D 位检查（暂不启用，xv6 不设置 A/D，依赖硬件自动写回）----
    // 如需启用，检查 !pte_a（读/取指时）或 !pte_d（写时）
    assign ad_fault = 1'b0;

    // ---- huge page PPN 低位对齐检查（必须全0）----
    // L2 leaf (1GB): PPN[1:0] 必须为 0
    assign superpage_misaligned_l2 = pte_leaf && (mem_resp.data[27:10] != 18'b0);
    // L1 leaf (2MB): PPN[0] 必须为 0
    assign superpage_misaligned_l1 = pte_leaf && (mem_resp.data[18:10] != 9'b0);

    //========================================================
    // TLB hit 检测（组合逻辑，直接使用 cpu_req.addr）
    //========================================================
    always_comb begin
        tlb_hit   = 1'b0;
        tlb_paddr = 64'b0;

        for (int i = 0; i < 8; i++) begin
            if (tlb[i].valid) begin
                logic [26:0] req_vpn;
                logic        match;

                req_vpn = {cpu_req.addr[38:30], cpu_req.addr[29:21], cpu_req.addr[20:12]};

                unique case (tlb[i].page_level)
                    2'b10: match = (tlb[i].vpn[26:18] == req_vpn[26:18]); // 1GB: VPN[2] only
                    2'b01: match = (tlb[i].vpn[26:9]  == req_vpn[26:9]);  // 2MB: VPN[2:1]
                    default: match = (tlb[i].vpn == req_vpn);             // 4KB: full VPN
                endcase

                if (match) begin
                    tlb_hit = 1'b1;

                    unique case (tlb[i].page_level)
                        2'b10: tlb_paddr = {8'b0, tlb[i].ppn[43:18], cpu_req.addr[29:0]};
                        2'b01: tlb_paddr = {8'b0, tlb[i].ppn[43:9],  cpu_req.addr[20:0]};
                        default: tlb_paddr = {8'b0, tlb[i].ppn[43:0], cpu_req.addr[11:0]};
                    endcase
                end
            end
        end
    end

    //========================================================
    // CPU response
    //
    // flush 表示事务取消，不向上游返回假 addr_ok/data_ok。
    // 只有真正完成的 saved_resp 可以返回给 CPU/arbiter。
    //========================================================
    always_comb begin
        cpu_resp = '0;

        if (!flush && cur == RESP) begin
            cpu_resp = saved_resp;
        end

        // Page fault: 强制返回 data_ok 以释放下游 stall
        if (!flush && page_fault) begin
            cpu_resp.data_ok = 1'b1;
            cpu_resp.data    = 64'b0;
        end
    end

    //========================================================
    // Memory request
    //
    // flush 当拍不允许任何旧 walk / 旧 translated request 继续出 MMU。
    //========================================================
    always_comb begin
        mem_req = '0;

        if (!flush) begin
            case (cur)
                REQ_2, WAIT_2: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = root_addr + ({55'b0, vpn2} << 3);
                    mem_req.size   = MSIZE8;
                    mem_req.strobe = 8'b0;
                    mem_req.data   = 64'b0;
                end

                REQ_1, WAIT_1: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = pt_addr + ({55'b0, vpn1} << 3);
                    mem_req.size   = MSIZE8;
                    mem_req.strobe = 8'b0;
                    mem_req.data   = 64'b0;
                end

                REQ_0, WAIT_0: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = pt_addr + ({55'b0, vpn0} << 3);
                    mem_req.size   = MSIZE8;
                    mem_req.strobe = 8'b0;
                    mem_req.data   = 64'b0;
                end

                REQ_P, WAIT_P: begin
                    mem_req      = saved_req;
                    mem_req.addr = paddr;
                end

                default: begin
                    mem_req = '0;
                end
            endcase
        end
    end

    //========================================================
    // Main FSM
    //========================================================
    always_ff @(posedge clk) begin
        if (reset) begin
            cur        <= IDLE;

            saved_req  <= '0;
            saved_resp <= '0;

            vpn2       <= 9'b0;
            vpn1       <= 9'b0;
            vpn0       <= 9'b0;
            root_addr  <= 64'b0;
            pt_addr    <= 64'b0;
            pte        <= 64'b0;
            paddr      <= 64'b0;

            page_fault  <= 1'b0;
            fault_addr  <= 64'b0;
            fault_cause <= 4'b0;

            tlb_replace_ptr <= 3'b0;
            for (int i = 0; i < 8; i++) tlb[i] <= '0;
        end
        else if (flush) begin
            // 事务级取消 + TLB 全清
            cur        <= IDLE;

            saved_req  <= '0;
            saved_resp <= '0;

            vpn2       <= 9'b0;
            vpn1       <= 9'b0;
            vpn0       <= 9'b0;
            root_addr  <= 64'b0;
            pt_addr    <= 64'b0;
            pte        <= 64'b0;
            paddr      <= 64'b0;

            page_fault  <= 1'b0;
            fault_addr  <= 64'b0;
            fault_cause <= 4'b0;

            for (int i = 0; i < 8; i++) tlb[i] <= '0;


        end
        else begin
            case (cur)

                IDLE: begin
                    saved_resp <= '0;
                    page_fault <= 1'b0;
                    fault_addr <= 64'b0;
                    fault_cause <= 4'b0;

                    if (cpu_req.valid) begin
                        saved_req <= cpu_req;

                        vpn2      <= cpu_req.addr[38:30];
                        vpn1      <= cpu_req.addr[29:21];
                        vpn0      <= cpu_req.addr[20:12];
                        root_addr <= {8'b0, satp[43:0], 12'b0};

                        if (translate) begin
                            if (tlb_hit) begin
                                paddr <= tlb_paddr;
                                cur <= REQ_P;
                            end
                            else begin
                                cur <= REQ_2;
                            end
                        end
                        else begin
                            paddr <= cpu_req.addr;
                            cur   <= REQ_P;
                        end


                    end
                end

                REQ_2: begin
                    cur <= WAIT_2;
                end

                WAIT_2: begin
                    if (mem_resp.data_ok) begin
                        pte <= mem_resp.data;

                        if (pte_invalid) begin
                            raise_page_fault(saved_req.addr);
                        end
                        else if (pte_leaf) begin

                            if (perm_fault || us_fault || ad_fault || superpage_misaligned_l2) begin
                                raise_page_fault(saved_req.addr);
                            end 
                            else begin
                                paddr <= {
                                    8'b0,
                                    mem_resp.data[53:28],
                                    saved_req.addr[29:0]
                                };
                                // TLB write (1GB huge page)
                                tlb[tlb_replace_ptr] <= '{
                                    valid: 1'b1,
                                    vpn: {vpn2, vpn1, vpn0},
                                    ppn: {mem_resp.data[53:28], 18'b0},
                                    page_level: 2'b10,
                                    r: pte_r, w: pte_w, x: pte_x, u: pte_u
                                };
                                tlb_replace_ptr <= tlb_replace_ptr + 1'b1;
                                cur <= REQ_P;
                            end


                        end
                        else begin
                            pt_addr <= {8'b0, mem_resp.data[53:10], 12'b0};
                            cur     <= REQ_1;


                        end
                    end
                end

                REQ_1: begin
                    cur <= WAIT_1;
                end

                WAIT_1: begin
                    if (mem_resp.data_ok) begin
                        pte <= mem_resp.data;

                        if (pte_invalid) begin
                            raise_page_fault(saved_req.addr);
                        end
                        else if (pte_leaf) begin
                            if (perm_fault || us_fault || ad_fault || superpage_misaligned_l1) begin
                                raise_page_fault(saved_req.addr);
                            end
                            else begin
                                paddr <= {
                                    8'b0,
                                    mem_resp.data[53:19],
                                    saved_req.addr[20:0]
                                };
                                // TLB write (2MB huge page)
                                tlb[tlb_replace_ptr] <= '{
                                    valid: 1'b1,
                                    vpn: {vpn2, vpn1, vpn0},
                                    ppn: {mem_resp.data[53:19], 9'b0},
                                    page_level: 2'b01,
                                    r: pte_r, w: pte_w, x: pte_x, u: pte_u
                                };
                                tlb_replace_ptr <= tlb_replace_ptr + 1'b1;
                                cur <= REQ_P;
                            end
                        end
                        else begin
                            pt_addr <= {8'b0, mem_resp.data[53:10], 12'b0};
                            cur     <= REQ_0;
                        end
                    end
                end

                REQ_0: begin
                    cur <= WAIT_0;
                end

                WAIT_0: begin
                    if (mem_resp.data_ok) begin
                        pte <= mem_resp.data;

                        if (pte_invalid) begin
                            raise_page_fault(saved_req.addr);
                        end
                        else if (!pte_leaf) begin
                            raise_page_fault(saved_req.addr);
                        end
                        else if (perm_fault || us_fault || ad_fault) begin
                            raise_page_fault(saved_req.addr);
                        end
                        else begin
                            paddr <= {
                                8'b0,
                                mem_resp.data[53:10],
                                saved_req.addr[11:0]
                            };
                            // TLB write (4KB page)
                            tlb[tlb_replace_ptr] <= '{
                                valid: 1'b1,
                                vpn: {vpn2, vpn1, vpn0},
                                ppn: mem_resp.data[53:10],
                                page_level: 2'b00,
                                r: pte_r, w: pte_w, x: pte_x, u: pte_u
                            };
                            tlb_replace_ptr <= tlb_replace_ptr + 1'b1;
                            cur <= REQ_P;
                        end
                    end
                end


                REQ_P: begin
                    cur <= WAIT_P;
                end

                WAIT_P: begin
                    if (mem_resp.data_ok) begin
                        saved_resp <= mem_resp;
                        cur        <= RESP;


                    end
                end

                RESP: begin
                    // page_fault/fault_addr/fault_cause 不清零，保留到 IDLE
                    // 让下游有足够时间捕获

                    saved_req  <= '0;
                    saved_resp <= '0;
                    pte        <= 64'b0;
                    paddr      <= 64'b0;
                    cur        <= IDLE;
                end

                default: begin
                    cur        <= IDLE;
                    saved_req  <= '0;
                    saved_resp <= '0;
                    pte        <= 64'b0;
                    paddr      <= 64'b0;
                end

            endcase
        end
    end



endmodule