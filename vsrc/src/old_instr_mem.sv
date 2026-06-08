`ifdef VERILATOR
`include "include/common.sv"
`endif

module instr_mem import common::*;(
    input  logic        clk,
    input  logic        reset,

    input  logic        is_ecall,
    input  logic        is_mret,

    input  logic        consume,
    input  logic        pc_stall,

    input  ibus_resp_t  ibus_resp,

    input  logic [63:0] pcinit,
    
    input  logic [63:0] redirect_pc,
    input  logic        branch_redirect_valid,

    output logic        fetch_ok,
    output logic [31:0] instr,
    output ibus_req_t   ibus_req,
    output logic [63:0] instr_pc,

    output logic        iaddr_exc
);

    logic redirect_valid;
    assign redirect_valid = branch_redirect_valid | is_ecall | is_mret; //需要redirect的时候

    logic [63:0] pc_r;

    logic        req_inflight;
    logic [63:0] req_pc;

    logic        drop_resp;

    assign ibus_req.valid = req_inflight; //准备好了发出请求
    assign ibus_req.addr  = req_pc; //发出请求的地址

    always_ff @(posedge clk) begin
        if (reset) begin
            pc_r         <= pcinit;
            req_inflight <= 1'b0;
            req_pc       <= 64'b0;
            drop_resp    <= 1'b0;
            fetch_ok     <= 1'b0;
            instr        <= 32'b0;
            instr_pc     <= 64'b0;

            iaddr_exc    <= 1'b0;
        end
        else begin


            if (consume) begin //ibus送回的指令已经传入流水寄存器。
                fetch_ok <= 1'b0;
            end

            if (redirect_valid) begin //
                pc_r     <= redirect_pc;
                fetch_ok <= 1'b0;
                instr    <= 32'b0;
                instr_pc <= 64'b0;

                if (req_inflight) begin 
                    drop_resp <= 1'b1;
                end
                else begin
                    drop_resp <= 1'b0;

                    if (!pc_stall) begin
                        req_inflight <= 1'b1;
                        req_pc       <= redirect_pc;
                    end
                end
            end
            else begin
                if (ibus_resp.data_ok && req_inflight) begin
                    if (drop_resp) begin
                        drop_resp    <= 1'b0;
                        req_inflight <= 1'b0;
                    end
                    else begin
                        instr        <= ibus_resp.data;
                        instr_pc     <= req_pc;
                        fetch_ok     <= 1'b1;
                        pc_r         <= req_pc + 64'd4;
                        req_inflight <= 1'b0;
                    end
                end

                if (!pc_stall && !fetch_ok && !req_inflight) begin
                    req_inflight <= 1'b1;
                    req_pc       <= pc_r;
                end
            end
        end
    end

endmodule