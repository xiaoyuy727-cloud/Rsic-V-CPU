//模块名称：instr_mem
//接口：input  logic [63:0] pc
//     input  logic clk
//     input  logic reset
//     input ibus_resp_t ibus_resp
//     input logic comsume
//     input logic pc_stall
//     output logic fetch_ok
//     output logic [31:0] instr
//     output ibus_req_t ibus_req
//     output logic [63:0] instr_pc
//功能：reset时全部清零。
//每一拍，当consume=1，表示目前的指令被下游消费，fetch_ok归零。
//     当目前没有挂起请求且没有已取回但是没有消费的指令时，pending=1，发起新的请求，把发起请求的pc锁存起来。收到返回前每一拍保持。
//     当ibus_resp.addr_ok和data_ok都是1，instr和pc传给后面，fetch_ok写入1，pc更新+4，pending归0.

module instr_mem import common::*;(
    input  logic        clk,
    input  logic        reset,
    input  logic        consume,
    input  logic        pc_stall,
    input  ibus_resp_t  ibus_resp,
    input  logic [63:0] pcinit,

    output logic        fetch_ok,
    output logic [31:0] instr,
    output ibus_req_t   ibus_req,
    output logic [63:0] instr_pc
);

    logic        pending;
    logic [63:0] pc_r;
    logic [63:0] req_pc;

    assign ibus_req.valid = pending;
    assign ibus_req.addr  = req_pc;

    always_ff @(posedge clk) begin
        if (reset) begin
            pending  <= 1'b0;
            fetch_ok <= 1'b0;
            pc_r     <= pcinit;
            req_pc   <= 64'b0;
            instr    <= 32'b0;
            instr_pc <= 64'b0;
        end
        else begin
            // 下游消费当前指令。stall时不允许消费
            if (consume && !pc_stall) begin
                fetch_ok <= 1'b0;
            end

            // 当前没有挂起请求，也没有已取回但未消费的指令时，
            // 才允许发起新的取指请求。stall时不发新请求
            if (!pc_stall && !pending && !fetch_ok) begin
                pending <= 1'b1;
                req_pc  <= pc_r;
            end

            // 已经发出的请求，返回时正常接收
            if (pending && ibus_resp.addr_ok && ibus_resp.data_ok) begin
                pending  <= 1'b0;
                instr    <= ibus_resp.data;
                instr_pc <= req_pc;
                fetch_ok <= 1'b1;
                pc_r     <= pc_r + 64'd4;
            end
        end
    end

endmodule
