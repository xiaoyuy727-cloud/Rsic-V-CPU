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

    input logic         mem_stall 

);

    assign fetch_ok         = ibus_resp.addr_ok & ibus_resp.data_ok;
    logic redirect_valid;
    assign redirect_valid   = branch_redirect_valid | is_ecall | is_mret; 
    logic[63:0] pre_pc;
    

    always_ff @(posedge clk) begin

        if (reset) begin 
            fetch_ok    <= 0;
            instr       <= 32'b0;
            pc          <= 64'b0;
            ibus.valid  <= 0;
            ibus.addr   <= pcinit;
        end 
        else if (consume) begin
            if (redirect_valid) begin
                fetch_ok    <= 0;
                instr       <= 32'b0;
                pc          <= 64'b0;
                ibus.valid  <= 0;
                ibus.addr   <= redirect_pc;
            end else begin
                fetch_ok    <= 0;
                instr       <= 32'b0;
                pc          <= 64'b0;
                ibus.valid  <= 0;
                ibus.addr   <= pc + 64'd4;
            end

            if()
        end 
        else begin

            if (fetch_ok) begin
                instr   <= data;
            end
        end
        
    end



endmodule

