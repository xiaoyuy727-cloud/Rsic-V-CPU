`ifdef VERILATOR
`include "include/common.sv"
`endif

module instr_mem import common::*;(
    input  logic         clk,
    input  logic         reset,

    // From datapath
    input  logic         consume,
    input  logic [63:0]  pcinit,
    input  logic [63:0]  redirect_pc,
    input  logic         branch_redirect_valid,
    input  logic         is_ecall,
    input  logic         is_mret,
    input  logic         pc_stall,

    // I-bus
    input  ibus_resp_t   ibus_resp,
    output ibus_req_t    ibus_req,

    // To datapath
    output logic         instr_valid,
    output logic [31:0]  instr,
    output logic [63:0]  pc,
    output logic         iaddr_exc
);

    typedef enum logic [1:0] {
        NEW_INSTR,
        CHECKING,
        EXEC,
        COMMIT
    } fetch_state_t;

    fetch_state_t cur, next;

    logic [63:0] pc_prepared;
    logic [31:0] instr_prepared;

    logic        fetch_ok;
    logic        redirect_valid;
    logic        pc_misaligned;

    assign redirect_valid = branch_redirect_valid | is_ecall | is_mret;
    assign pc_misaligned  = (pc_prepared[1:0] != 2'b00);

    // 对外语义：
    // instr_valid=1 表示 pc/instr/iaddr_exc 当前是稳定有效的输出
    assign instr_valid = (cur == COMMIT);

    // 内部语义：
    // fetch_ok=1 表示本次取指流程已经完成，可以进入 COMMIT
    assign fetch_ok = pc_misaligned | ibus_resp.data_ok;

    // =========================================================
    // FSM next-state logic
    // =========================================================
    always_comb begin
        next = cur;

        unique case (cur)
            NEW_INSTR: begin
                if (!pc_stall)
                    next = CHECKING;
            end

            CHECKING: begin
                if (pc_stall)
                    next = CHECKING;
                else if (redirect_valid)
                    next = NEW_INSTR;
                else if (pc_misaligned)
                    next = COMMIT;
                else
                    next = EXEC;
            end

            EXEC: begin
                if (pc_stall)
                    next = EXEC;
                else if (redirect_valid)
                    next = NEW_INSTR;
                else if (fetch_ok)
                    next = COMMIT;
            end

            COMMIT: begin
                if (pc_stall)
                    next = COMMIT;
                else if (redirect_valid)
                    next = NEW_INSTR;
                else if (consume)
                    next = NEW_INSTR;
            end

            default: begin
                next = NEW_INSTR;
            end
        endcase
    end

    // =========================================================
    // Sequential logic
    // =========================================================
    always_ff @(posedge clk) begin
        if (reset) begin
            cur <= NEW_INSTR;

            pc_prepared    <= pcinit;
            instr_prepared <= 32'b0;

            pc             <= 64'b0;
            instr          <= 32'b0;
            iaddr_exc      <= 1'b0;

            ibus_req.valid <= 1'b0;
            ibus_req.addr  <= 64'b0;
        end else begin
            cur <= next;

            unique case (cur)
                NEW_INSTR: begin
                    ibus_req.valid <= 1'b0;
                    ibus_req.addr  <= 64'b0;

                    iaddr_exc      <= 1'b0;
                    instr_prepared <= 32'b0;

                    if (!pc_stall) begin
                        if (redirect_valid)
                            pc_prepared <= redirect_pc;
                        else if (pc == 64'b0)
                            pc_prepared <= pcinit;
                        else
                            pc_prepared <= pc + 64'd4;
                    end
                end

                CHECKING: begin
                    ibus_req.valid <= 1'b0;
                    ibus_req.addr  <= 64'b0;

                    if (!pc_stall) begin
                        if (pc_misaligned) begin
                            iaddr_exc      <= 1'b1;
                            instr_prepared <= 32'b0;
                            pc             <= pc_prepared;
                        end
                    end
                end

                EXEC: begin
                    if (!pc_stall) begin
                        ibus_req.valid <= 1'b1;
                        ibus_req.addr  <= pc_prepared;

                        if (ibus_resp.data_ok) begin
                            instr_prepared <= ibus_resp.data;
                            iaddr_exc      <= 1'b0;
                            pc             <= pc_prepared;
                        end
                    end
                end

                COMMIT: begin
                    ibus_req.valid <= 1'b0;
                    ibus_req.addr  <= 64'b0;
                end

                default: begin
                    ibus_req.valid <= 1'b0;
                    ibus_req.addr  <= 64'b0;
                end
            endcase
        end
    end

endmodule