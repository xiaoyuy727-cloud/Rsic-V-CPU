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
    output logic [63:0] instr_pc
);

    logic redirect_valid;
    assign redirect_valid = branch_redirect_valid | is_ecall | is_mret;

    logic [63:0] pc_r;

    logic        req_inflight;
    logic [63:0] req_pc;

    logic        drop_resp;

    assign ibus_req.valid = req_inflight;
    assign ibus_req.addr  = req_pc;

    always_ff @(posedge clk) begin
        if (reset) begin
            pc_r         <= pcinit;
            req_inflight <= 1'b0;
            req_pc       <= 64'b0;
            drop_resp    <= 1'b0;
            fetch_ok     <= 1'b0;
            instr        <= 32'b0;
            instr_pc     <= 64'b0;
        end
        else begin

`ifdef DEBUG
            if (redirect_valid &&
                (is_mret || is_ecall ||
                 req_pc == 64'h0000000080001e00 ||
                 redirect_pc == 64'h00000007ffff0000)) begin
                $display("[IF REDIRECT FOCUS] req_inflight=%b req_pc=%h pc_r=%h redirect_pc=%h pc_stall=%b ecall=%b mret=%b branch=%b data_ok=%b data=%h",
                         req_inflight, req_pc, pc_r, redirect_pc,
                         pc_stall, is_ecall, is_mret, branch_redirect_valid,
                         ibus_resp.data_ok, ibus_resp.data);
            end

            if (ibus_resp.data_ok &&
                (req_pc == 64'h0000000080001e00 ||
                 req_pc == 64'h00000007ffff0000 )) begin
                $display("[IF RESP FOCUS] req_pc=%h drop=%b data=%h",
                         req_pc, drop_resp, ibus_resp.data);
            end
`endif

            if (consume) begin
                fetch_ok <= 1'b0;
            end

            if (redirect_valid) begin
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