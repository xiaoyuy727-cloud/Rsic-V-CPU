`ifdef VERILATOR
`include "include/common.sv"
`endif

module instr_mem import common::*;(
    input logic         clk,
    input logic         reset,

    input logic         consume,
    input  logic [63:0] pcinit,

    input  ibus_resp_t  ibus_resp,
    output ibus_req_t   ibus_req,

    output logic        instr_valid,
    output logic [31:0]       instr,
    output logic [63:0]       pc,

    input logic [63:0]  redirect_pc,
    input logic         branch_redirect_valid, 
    input logic         is_ecall,
    input logic         is_mret,

    input logic         pc_stall, 

    output logic        iaddr_exc

);


`ifdef DEBUG
longint dbg_cycle;
always_ff @(posedge clk) begin
    if (reset) begin
        dbg_cycle <= 0;
    end else begin
        dbg_cycle <= dbg_cycle + 1;

if ((dbg_cycle >= 1288) && (dbg_cycle <= 1320)) begin
    $display(
        "[IF_FSM_DBG] cycle=%0d cur=%0d next=%0d pc=%h pc_prepared=%h instr=%h instr_prepared=%h instr_valid=%b consume=%b pc_stall=%b ibus_valid=%b ibus_addr=%h addr_ok=%b data_ok=%b rdata=%h",
        dbg_cycle,
        cur,
        next,
        pc,
        pc_prepared,
        instr,
        instr_prepared,
        instr_valid,
        consume,
        pc_stall,
        ibus_req.valid,
        ibus_req.addr,
        ibus_resp.addr_ok,
        ibus_resp.data_ok,
        ibus_resp.data
    );

    if (pc_stall && (next != cur)) begin
        $display(
            "[BUG_IF_STATE_MOVE_WHEN_PC_STALL] cycle=%0d cur=%0d next=%0d pc=%h pc_prepared=%h",
            dbg_cycle,
            cur,
            next,
            pc,
            pc_prepared
        );
    end

    if (pc_stall && ibus_req.valid) begin
        $display(
            "[BUG_IF_REQ_WHEN_PC_STALL] cycle=%0d cur=%0d pc=%h pc_prepared=%h ibus_addr=%h",
            dbg_cycle,
            cur,
            pc,
            pc_prepared,
            ibus_req.addr
        );
    end
end


        
    end
end
`endif


//按照状态机写。
    typedef enum logic [1:0] {
        NEW_INSTR,
        CHECKING,
        EXEC,
        COMMIT
    } fetch_state_t;

    fetch_state_t cur,next;

    logic [63:0] pc_prepared;
    logic [31:0] instr_prepared;

    logic redirect_valid;
    logic fetch_ok;
    logic pc_misaligned;
    assign redirect_valid   = branch_redirect_valid | is_ecall | is_mret;
    assign pc_misaligned = (pc_prepared[1:0] != 2'b00);

    // 对外语义：
    // instr_valid=1 表示 pc/instr/iaddr_exc 当前是稳定有效的输出
    assign instr_valid = (cur == COMMIT);

    // 内部语义：
    // fetch_ok=1 表示本次取指流程已经完成，可以进入 COMMIT
    assign fetch_ok = pc_misaligned | ibus_resp.data_ok;

    //有限状态机 状态转移
    always_comb begin
        next = cur;

        unique case (cur)
            NEW_INSTR: begin
                if (!pc_stall)
                    next = CHECKING;
            end
            CHECKING:begin
                if(pc_stall) next = CHECKING;
                else if (redirect_valid) next = NEW_INSTR;
                else if (pc_misaligned)  next = COMMIT;
                else next = EXEC;
            end
            EXEC:begin
                if(pc_stall) next = EXEC;
                else if(redirect_valid) next = NEW_INSTR;
                else if(fetch_ok) next = COMMIT;
            end
            COMMIT:begin
                if(pc_stall) next=COMMIT;
                else if(redirect_valid) next = NEW_INSTR;
                else if(consume) next = NEW_INSTR;
            end
            default: begin
                next = NEW_INSTR;
            end
        endcase

    end

    //有限状态机时序逻辑
    always_ff @(posedge clk) begin
        if (reset) begin
            cur <= NEW_INSTR;
            ibus_req.addr <= 64'b0;
            ibus_req.valid <= 1'b0;
            iaddr_exc     <= 1'b0;
            pc_prepared   <= pcinit;
            instr         <= 32'b0;
            pc            <= 64'b0;
            instr_prepared <= 32'b0;
        end else if (redirect_valid && !pc_stall) begin
            cur            <= NEW_INSTR;

            pc_prepared    <= redirect_pc;
            instr_prepared <= 32'b0;

            pc             <= 64'b0;
            instr          <= 32'b0;

            ibus_req.valid <= 1'b0;
            ibus_req.addr  <= 64'b0;
            iaddr_exc      <= 1'b0;
        end else begin
            cur  <= next;

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
                CHECKING:begin
                    ibus_req.valid <= 1'b0;
                    ibus_req.addr  <= 64'b0;                
                    if (!pc_stall) begin
                        if (pc_misaligned) begin
                            iaddr_exc   <= 1'b1;
                            instr       <= 32'b0;
                            pc          <= pc_prepared;
                        end
                    end
                end
                EXEC:begin
                    if (!pc_stall) begin
                        ibus_req.valid <= 1'b1;
                        ibus_req.addr  <= pc_prepared;

                        if (ibus_resp.data_ok) begin
                            instr       <= ibus_resp.data;
                            iaddr_exc      <= 1'b0;
                            pc          <= pc_prepared;
                        end
                    end
                end

                COMMIT:begin
                    ibus_req.valid <= 1'b0;
                    ibus_req.addr  <= 64'b0;

                    //if (!pc_stall) begin
                    //    pc    <= pc_prepared;
                    //    instr <= instr_prepared;
                    //end
                end

                default: begin
                    ibus_req.valid <= 1'b0;
                    ibus_req.addr  <= 64'b0;
                end
            endcase
        end
    end

endmodule