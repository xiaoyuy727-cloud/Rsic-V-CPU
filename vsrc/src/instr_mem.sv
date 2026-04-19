//模块名称：instr_mem
//接口：input  logic [63:0] pc
//     input  logic clk
//     input  logic reset
//     input ibus_resp_t ibus_resp
//     input logic comsume
//     input logic pc_stall
//     input logic [63:0] redirect_pc
//     input logic redirect_valid
//     output logic fetch_ok
//     output logic [31:0] instr
//     output ibus_req_t ibus_req
//     output logic [63:0] instr_pc
//功能：reset时全部清零。
//每一拍，当consume=1，表示目前的指令被下游消费，fetch_ok归零。
//     当目前没有挂起请求且没有已取回但是没有消费的指令时，pending=1，发起新的请求，把发起请求的pc锁存起来。收到返回前每一拍保持。
//     当ibus_resp.addr_ok和data_ok都是1，instr和pc传给后面，fetch_ok写入1，pc更新+4，pending归0.

`include "include/common.sv"

module instr_mem import common::*;(
    input  logic        clk,
    input  logic        reset,

    input  logic        consume,
    input  logic        pc_stall,

    input  ibus_resp_t  ibus_resp,

    input  logic [63:0] pcinit,
    input  logic [63:0] redirect_pc,
    input  logic        redirect_valid,

    output logic        fetch_ok,
    output logic [31:0] instr,
    output ibus_req_t   ibus_req,
    output logic [63:0] instr_pc
);

    // 当前“下一次要请求”的 PC
    logic [63:0] pc_r;

    // 正在总线上等待返回的请求
    logic        req_inflight;
    logic [63:0] req_pc;

    // 是否需要丢弃下一次返回（因为 redirect 把旧路径冲掉了）
    logic        drop_resp;

    // 组合输出：一旦有在飞请求，就持续保持 valid/addr 不变
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
            // -----------------------------------------
            // A. 下游消费掉当前缓存指令
            // -----------------------------------------
            if (consume) begin
                fetch_ok <= 1'b0;
            end

            // -----------------------------------------
            // B. redirect 优先级最高：切 PC，并清掉当前取指结果
            // -----------------------------------------
            if (redirect_valid) begin
                pc_r     <= redirect_pc;
                fetch_ok <= 1'b0;

                // 如果当前已经有旧路径请求在飞，则把它的返回丢掉
                if (req_inflight) begin
                    drop_resp <= 1'b1;
                end
                else begin
                    drop_resp <= 1'b0;
                end

                // 若当前没有请求在飞，且不 stall，则立刻对新 PC 发请求
                if (!req_inflight && !pc_stall) begin
                    req_inflight <= 1'b1;
                    req_pc       <= redirect_pc;
                end
            end

            // -----------------------------------------
            // C. 正常处理返回：只看 data_ok
            // -----------------------------------------
            if (ibus_resp.data_ok) begin
                if (drop_resp) begin
                    // 这是旧路径返回，丢掉
                    drop_resp    <= 1'b0;
                    req_inflight <= 1'b0;
                end
                else if (req_inflight) begin
                    // 这是当前有效返回
                    instr        <= ibus_resp.data;
                    instr_pc     <= req_pc;
                    fetch_ok     <= 1'b1;
                    pc_r         <= req_pc + 64'd4;
                    req_inflight <= 1'b0;
                end
            end

            // -----------------------------------------
            // D. 空闲时自动对 pc_r 发起新请求
            // 条件：
            //   1. 没有缓存好的指令
            //   2. 没有请求在飞
            //   3. 没有 stall
            //   4. 本拍没有 redirect
            // -----------------------------------------
            if (!redirect_valid && !pc_stall && !fetch_ok && !req_inflight) begin
                req_inflight <= 1'b1;
                req_pc       <= pc_r;
            end
        end
    end

endmodule