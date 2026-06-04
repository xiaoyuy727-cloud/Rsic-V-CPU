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

    output logic        fetch_ok,
    output logic [31:0]       instr,
    output logic [63:0]       pc,

    input logic [63:0]  redirect_pc,
    input logic         branch_redirect_valid,
    input logic         is_ecall,
    input logic         is_mret,

    input logic         pc_stall, 

    output logic        iaddr_exc

);

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
    assign redirect_valid   = branch_redirect_valid | is_ecall | is_mret;

    always_comb begin
        next = cur;

        case (cur)
            NEW_INSTR: next = CHECKING;
            CHECKING:begin
                if(pc_stall) next = CHECKING;
                else if (redirect_valid) next = NEW_INSTR;
                else if (pc_prepared[1:0] != 2'b0) begin
                    next = COMMIT;
                end
                else next = EXEC;
            end
            EXEC:begin
                if(redirect_valid) next = NEW_INSTR;
                else if(fetch_ok) next = COMMIT;
            end
            COMMIT:begin
                if(redirect_valid) next = NEW_INSTR;
                else if(consume) next = NEW_INSTR;
            end
            default: ;
        endcase

    end

    always_ff @(posedge clk) begin
        if (reset) begin
            cur <= NEW_INSTR;
            ibus_req.addr <= 64'b0;
            ibus_req.valid <= 1'b0;
            iaddr_exc     <= 1'b0;
            pc_prepared   <= pcinit;
            instr         <= 32'b0;
            fetch_ok      <= 1'b0; 
            pc <= pcinit - 64'd4;
            instr_prepared <= 32'b0;
        end else begin
            cur  <= next;

            case (cur)
                NEW_INSTR:begin
                    if (redirect_valid) begin
                        ibus_req.addr <= 64'b0;
                        ibus_req.valid <= 1'b0;
                        iaddr_exc     <= 1'b0;
                        pc_prepared   <= redirect_pc;
                        instr         <= 32'b0;
                        fetch_ok      <= 1'b0;  
                    end 
                    else begin
                        ibus_req.addr <= 64'b0;
                        ibus_req.valid <= 1'b0;
                        iaddr_exc     <= 1'b0;
                        pc_prepared   <= pc + 64'd4;
                        instr         <= 32'b0;
                        fetch_ok      <= 1'b0;  
                    end                  
                end
                CHECKING:begin
                    if (pc_stall) ;
                    else if (pc_prepared[1:0] != 2'b0) begin
                        fetch_ok <= 1'b1;
                        iaddr_exc   <= 1'b1;
                        instr_prepared      <= 32'b0;
                    end
                end
                EXEC:begin
                    ibus_req.valid  <= 1'b1;
                    ibus_req.addr   <= pc_prepared;
                    fetch_ok        <= ibus_resp.data_ok & ibus_resp.addr_ok;
                    if(ibus_resp.data_ok)   instr_prepared  <= ibus_resp.data;
                end
                COMMIT:begin
                    pc      <= pc_prepared;
                    instr   <= instr_prepared;
                end
                default: ;
            endcase
        end
    end


endmodule

