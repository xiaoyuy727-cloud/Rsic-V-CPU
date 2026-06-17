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

    // ======================================================
    // ✨ NEW: page fault interface（给CSR/trap用）
    // ======================================================
    output logic        page_fault,
    output logic [63:0] fault_addr,
    output logic [3:0]  fault_cause
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

    logic [8:0] vpn2, vpn1, vpn0;
    logic [63:0] root_addr;
    logic [63:0] pt_addr;
    logic [63:0] pte;
    logic [63:0] paddr;

    logic translate;

    logic pte_v, pte_r, pte_w, pte_x;
    logic pte_invalid;
    logic pte_leaf;

    // ======================================================
    // address translation enable
    // ======================================================
    assign translate =
        cpu_req.valid &&
        (privil_mode != 2'b11) &&
        (satp[63:60] == 4'd8);

    assign pte_v = mem_resp.data[0];
    assign pte_r = mem_resp.data[1];
    assign pte_w = mem_resp.data[2];
    assign pte_x = mem_resp.data[3];

    // ======================================================
    // ✨ FIXED: Sv39 page fault rule (更严格)
    // ======================================================
    assign pte_invalid = (!pte_v) ||
                         (pte_w && !pte_r) ||
                         (pte_v && !pte_r && pte_w); // illegal W=1 R=0

    assign pte_leaf = pte_r || pte_x;

    // ======================================================
    // CPU response
    // ======================================================
    always_comb begin
        cpu_resp = '0;

        if (!flush && cur == RESP) begin
            cpu_resp = saved_resp;
        end
    end

    // ======================================================
    // memory request
    // ======================================================
    always_comb begin
        mem_req = '0;

        if (!flush) begin
            case (cur)

                REQ_2, WAIT_2: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = root_addr + ({55'b0, vpn2} << 3);
                    mem_req.size   = MSIZE8;
                end

                REQ_1, WAIT_1: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = pt_addr + ({55'b0, vpn1} << 3);
                    mem_req.size   = MSIZE8;
                end

                REQ_0, WAIT_0: begin
                    mem_req.valid  = 1'b1;
                    mem_req.addr   = pt_addr + ({55'b0, vpn0} << 3);
                    mem_req.size   = MSIZE8;
                end

                REQ_P, WAIT_P: begin
                    mem_req      = saved_req;
                    mem_req.addr = paddr;
                end

            endcase
        end
    end

    // ======================================================
    // ✨ page fault helper
    // ======================================================
    task automatic raise_page_fault(input logic [3:0] cause);
    begin
        page_fault  <= 1'b1;
        fault_addr  <= saved_req.addr;
        fault_cause <= cause;
    end
    endtask

    // ======================================================
    // FSM
    // ======================================================
    always_ff @(posedge clk) begin
        if (reset) begin
            cur <= IDLE;

            saved_req  <= '0;
            saved_resp <= '0;

            page_fault  <= 0;
            fault_addr  <= 0;
            fault_cause <= 0;
        end

        else if (flush) begin
            // ==================================================
            // ✨ flush = kill MMU + cancel pagewalk + cancel fault
            // ==================================================
            cur <= IDLE;

            saved_req  <= '0;
            saved_resp <= '0;

            page_fault  <= 0;
            fault_addr  <= 0;
            fault_cause <= 0;
        end

        else begin

            // default: no fault
            page_fault <= 0;

            case (cur)

                IDLE: begin
                    if (cpu_req.valid) begin
                        saved_req <= cpu_req;

                        vpn2 <= cpu_req.addr[38:30];
                        vpn1 <= cpu_req.addr[29:21];
                        vpn0 <= cpu_req.addr[20:12];

                        root_addr <= {8'b0, satp[43:0], 12'b0};

                        if (translate)
                            cur <= REQ_2;
                        else begin
                            paddr <= cpu_req.addr;
                            cur   <= REQ_P;
                        end
                    end
                end

                // ============================
                // L2
                // ============================
                WAIT_2: begin
                    if (mem_resp.data_ok) begin
                        pte <= mem_resp.data;

                        // ❗ PAGE FAULT: invalid PTE
                        if (pte_invalid) begin
                            raise_page_fault(4'd12); // instr/load fault (example)
                            cur <= IDLE;
                        end

                        // ============================
                        // ✨ L2 HUGE PAGE (1GB)
                        // ============================
                        else if (pte_leaf) begin
                            paddr <= {
                                8'b0,
                                mem_resp.data[53:28],   // PPN high
                                saved_req.addr[29:0]    // offset
                            };
                            cur <= REQ_P;
                        end

                        else begin
                            pt_addr <= {8'b0, mem_resp.data[53:10], 12'b0};
                            cur <= REQ_1;
                        end
                    end
                end

                // ============================
                // L1
                // ============================
                WAIT_1: begin
                    if (mem_resp.data_ok) begin
                        pte <= mem_resp.data;

                        if (pte_invalid) begin
                            raise_page_fault(4'd13);
                            cur <= IDLE;
                        end

                        // ============================
                        // ✨ L1 HUGE PAGE (2MB)
                        // ============================
                        else if (pte_leaf) begin
                            paddr <= {
                                8'b0,
                                mem_resp.data[53:19],   // PPN aligned
                                saved_req.addr[20:0]
                            };
                            cur <= REQ_P;
                        end

                        else begin
                            pt_addr <= {8'b0, mem_resp.data[53:10], 12'b0};
                            cur <= REQ_0;
                        end
                    end
                end

                // ============================
                // L0
                // ============================
                WAIT_0: begin
                    if (mem_resp.data_ok) begin
                        pte <= mem_resp.data;

                        if (pte_invalid || !pte_leaf) begin
                            raise_page_fault(4'd15); // store/load fault
                            cur <= IDLE;
                        end

                        else begin
                            paddr <= {8'b0, mem_resp.data[53:10], saved_req.addr[11:0]};
                            cur <= REQ_P;
                        end
                    end
                end

                WAIT_P: begin
                    if (mem_resp.data_ok) begin
                        saved_resp <= mem_resp;
                        cur <= RESP;
                    end
                end

                RESP: begin
                    cur <= IDLE;
                    saved_req <= '0;
                    saved_resp <= '0;
                end

            endcase
        end
    end

endmodule