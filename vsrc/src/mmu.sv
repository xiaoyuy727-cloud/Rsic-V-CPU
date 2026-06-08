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
    input  logic [63:0] satp
);

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

    state_t cur;

    dbus_req_t  saved_req;
    dbus_resp_t saved_resp;

    logic [8:0]  vpn2, vpn1, vpn0;
    logic [63:0] root_addr;
    logic [63:0] pt_addr;
    logic [63:0] pte;
    logic [63:0] paddr;

    logic translate;

    logic pte_v;
    logic pte_r;
    logic pte_w;
    logic pte_x;
    logic pte_invalid;
    logic pte_leaf;

    assign translate =
        cpu_req.valid &&
        (privil_mode != 2'b11) &&
        (satp[63:60] == 4'd8);

    assign pte_v = mem_resp.data[0];
    assign pte_r = mem_resp.data[1];
    assign pte_w = mem_resp.data[2];
    assign pte_x = mem_resp.data[3];

    assign pte_invalid = !pte_v || (pte_w && !pte_r);
    assign pte_leaf    = pte_r || pte_x;

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
        end
        else if (flush) begin
            // 事务级取消：
            // 丢弃当前 saved_req、page walk、translated physical request、saved_resp。
            // 不产生任何 cpu_resp。
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

`ifdef DEBUG
            $display("[MMU_FLUSH] cur=%0d cpu_valid=%b cpu_addr=%h saved_valid=%b saved_addr=%h priv=%0d satp=%h",
                     cur, cpu_req.valid, cpu_req.addr,
                     saved_req.valid, saved_req.addr,
                     privil_mode, satp);
`endif
        end
        else begin
            case (cur)

                IDLE: begin
                    saved_resp <= '0;

                    if (cpu_req.valid) begin
                        saved_req <= cpu_req;

                        vpn2      <= cpu_req.addr[38:30];
                        vpn1      <= cpu_req.addr[29:21];
                        vpn0      <= cpu_req.addr[20:12];
                        root_addr <= {8'b0, satp[43:0], 12'b0};

                        if (translate) begin
                            cur <= REQ_2;
                        end
                        else begin
                            paddr <= cpu_req.addr;
                            cur   <= REQ_P;
                        end

`ifdef DEBUG
                        $display("[MMU_ACCEPT] cpu_addr=%h valid=%b strobe=%h data=%h translate=%b priv=%0d satp=%h root_addr=%h",
                                 cpu_req.addr,
                                 cpu_req.valid,
                                 cpu_req.strobe,
                                 cpu_req.data,
                                 translate,
                                 privil_mode,
                                 satp,
                                 {8'b0, satp[43:0], 12'b0});
`endif
                    end
                end

                REQ_2: begin
                    cur <= WAIT_2;
                end

                WAIT_2: begin
                    if (mem_resp.data_ok) begin
                        pte <= mem_resp.data;

                        if (pte_invalid) begin
                            // 测试中不应出现 page fault。
                            // 如果出现，说明上游送来了错误地址或页表内容被污染。
                            // 这里必须停止 walk，不能继续用非法 PTE 计算下一级地址。
                            cur        <= IDLE;
                            saved_req  <= '0;
                            saved_resp <= '0;
                            pt_addr    <= 64'b0;
                            paddr      <= 64'b0;

`ifdef DEBUG
                            $display("[MMU_BAD_L2_PTE] vaddr=%h pte_addr=%h pte=%h satp=%h root_addr=%h vpn2=%h",
                                     saved_req.addr,
                                     root_addr + ({55'b0, vpn2} << 3),
                                     mem_resp.data,
                                     satp,
                                     root_addr,
                                     vpn2);
`endif
                        end
                        else if (pte_leaf) begin
                            // Sv39 gigapage leaf at level 2.
                            // 这里保留正确语义，虽然你的测试可能不用。
                            paddr <= {
                                8'b0,
                                mem_resp.data[53:28],
                                saved_req.addr[29:0]
                            };
                            cur <= REQ_P;

`ifdef DEBUG
                            $display("[MMU_L2_LEAF] vaddr=%h pte=%h paddr=%h",
                                     saved_req.addr,
                                     mem_resp.data,
                                     {8'b0, mem_resp.data[53:28], saved_req.addr[29:0]});
`endif
                        end
                        else begin
                            pt_addr <= {8'b0, mem_resp.data[53:10], 12'b0};
                            cur     <= REQ_1;

`ifdef DEBUG
                            $display("[MMU_L2_DONE] vaddr=%h pte=%h next_pt=%h",
                                     saved_req.addr,
                                     mem_resp.data,
                                     {8'b0, mem_resp.data[53:10], 12'b0});
`endif
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
                            cur        <= IDLE;
                            saved_req  <= '0;
                            saved_resp <= '0;
                            pt_addr    <= 64'b0;
                            paddr      <= 64'b0;

`ifdef DEBUG
                            $display("[MMU_BAD_L1_PTE] vaddr=%h pte_addr=%h pte=%h pt_addr=%h vpn1=%h",
                                     saved_req.addr,
                                     pt_addr + ({55'b0, vpn1} << 3),
                                     mem_resp.data,
                                     pt_addr,
                                     vpn1);
`endif
                        end
                        else if (pte_leaf) begin
                            // Sv39 megapage leaf at level 1.
                            paddr <= {
                                8'b0,
                                mem_resp.data[53:19],
                                saved_req.addr[20:0]
                            };
                            cur <= REQ_P;

`ifdef DEBUG
                            $display("[MMU_L1_LEAF] vaddr=%h pte=%h paddr=%h",
                                     saved_req.addr,
                                     mem_resp.data,
                                     {8'b0, mem_resp.data[53:19], saved_req.addr[20:0]});
`endif
                        end
                        else begin
                            pt_addr <= {8'b0, mem_resp.data[53:10], 12'b0};
                            cur     <= REQ_0;

`ifdef DEBUG
                            $display("[MMU_L1_DONE] vaddr=%h pte=%h next_pt=%h",
                                     saved_req.addr,
                                     mem_resp.data,
                                     {8'b0, mem_resp.data[53:10], 12'b0});
`endif
                        end
                    end
                end

                REQ_0: begin
                    cur <= WAIT_0;
                end

                WAIT_0: begin
                    if (mem_resp.data_ok) begin
                        pte <= mem_resp.data;

                        if (pte_invalid || !pte_leaf) begin
                            cur        <= IDLE;
                            saved_req  <= '0;
                            saved_resp <= '0;
                            paddr      <= 64'b0;

`ifdef DEBUG
                            $display("[MMU_BAD_L0_PTE] vaddr=%h pte_addr=%h pte=%h pt_addr=%h vpn0=%h invalid=%b leaf=%b",
                                     saved_req.addr,
                                     pt_addr + ({55'b0, vpn0} << 3),
                                     mem_resp.data,
                                     pt_addr,
                                     vpn0,
                                     pte_invalid,
                                     pte_leaf);
`endif
                        end
                        else begin
                            paddr <= {8'b0, mem_resp.data[53:10], saved_req.addr[11:0]};
                            cur   <= REQ_P;

`ifdef DEBUG
                            $display("[MMU_L0_DONE] vaddr=%h pte=%h pte_ppn=%h final_paddr=%h pt_addr=%h vpn0=%h req_pte_addr=%h",
                                     saved_req.addr,
                                     mem_resp.data,
                                     mem_resp.data[53:10],
                                     {8'b0, mem_resp.data[53:10], saved_req.addr[11:0]},
                                     pt_addr,
                                     vpn0,
                                     pt_addr + ({55'b0, vpn0} << 3));
`endif
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

`ifdef DEBUG
                        $display("[MMU_MEM_DONE] saved_vaddr=%h paddr=%h resp_data=%h",
                                 saved_req.addr, paddr, mem_resp.data);
`endif
                    end
                end

                RESP: begin
`ifdef DEBUG
                    if (cpu_req.valid) begin
                        $display("[MMU_RESP_BLOCK_NEW_REQ] resp_for=%h resp_data=%h blocked_cpu_addr=%h",
                                 saved_req.addr, saved_resp.data, cpu_req.addr);
                    end

                    $display("[MMU_CPU_RESP] saved_addr=%h data_ok=%b data=%h",
                             saved_req.addr, saved_resp.data_ok, saved_resp.data);
`endif

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

`ifdef DEBUG
    always_ff @(posedge clk) begin
        if (!reset) begin
            if (cpu_req.valid || mem_req.valid || mem_resp.data_ok || cpu_resp.data_ok || flush) begin
                $display("[MMU_STATE] cur=%0d flush=%b cpu_valid=%b cpu_addr=%h saved_valid=%b saved_addr=%h paddr=%h mem_valid=%b mem_addr=%h mem_strobe=%h mem_data=%h mem_data_ok=%b mem_data_resp=%h cpu_data_ok=%b cpu_data=%h priv=%0d satp=%h",
                         cur,
                         flush,
                         cpu_req.valid,
                         cpu_req.addr,
                         saved_req.valid,
                         saved_req.addr,
                         paddr,
                         mem_req.valid,
                         mem_req.addr,
                         mem_req.strobe,
                         mem_req.data,
                         mem_resp.data_ok,
                         mem_resp.data,
                         cpu_resp.data_ok,
                         cpu_resp.data,
                         privil_mode,
                         satp);
            end

            if (flush) begin
                $display("[MMU_FLUSH_CHECK] flush=%b cur=%0d saved_addr=%h cpu_addr=%h priv=%0d satp=%h",
                         flush, cur, saved_req.addr, cpu_req.addr, privil_mode, satp);
            end
        end
    end
`endif

endmodule