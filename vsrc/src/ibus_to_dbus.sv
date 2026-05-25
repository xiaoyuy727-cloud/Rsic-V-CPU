`ifdef VERILATOR
`include "include/common.sv"
`endif
//功能：把ibus转成dbus形式，然后进入arbiter仲裁
module ibus_to_dbus import common::*;(
    input  logic       clk,
    input  logic       reset,

    output ibus_resp_t iresp,
    input  ibus_req_t  ireq,

    input  dbus_resp_t dresp,
    output dbus_req_t  dreq
);

    // 正在等待返回的请求
    logic [63:0] req_addr;
    logic        req_hi;
    logic        miss_pending;

    // cache 一整条 64-bit instruction line
    logic [63:0] cache_addr;
    logic [63:0] cache_data;
    logic        cache_valid;

    logic hit;
    logic miss_fire;

    assign hit =
        cache_valid &&
        ireq.valid &&
        (cache_addr[63:3] == ireq.addr[63:3]);

    // 只允许同一时间一个 IBus miss 在路上
    assign miss_fire = ireq.valid && !hit && !miss_pending;

    //========================================================
    // 保存 miss 请求和 memory 返回的一整行
    //========================================================
    always_ff @(posedge clk) begin
        if (reset) begin
            req_addr     <= 64'b0;
            req_hi       <= 1'b0;
            miss_pending <= 1'b0;

            cache_addr   <= 64'b0;
            cache_data   <= 64'b0;
            cache_valid  <= 1'b0;
        end
        else begin
            // 只在真正发出一个新的 miss 时锁存地址
            if (miss_fire) begin
                req_addr     <= {ireq.addr[63:3], 3'b000};
                req_hi       <= ireq.addr[2];
                miss_pending <= 1'b1;
            end

            // 只有确实有未完成 miss 时，才接收 data_ok
            if (dresp.data_ok && miss_pending) begin
                cache_addr   <= req_addr;
                cache_data   <= dresp.data;
                cache_valid  <= 1'b1;
                miss_pending <= 1'b0;
            end
        end
    end

    //========================================================
    // 发 memory 请求
    //========================================================
    assign dreq.valid  = miss_fire;
    assign dreq.addr   = {ireq.addr[63:3], 3'b000};
    assign dreq.size   = MSIZE8;
    assign dreq.strobe = 8'b0;
    assign dreq.data   = 64'b0;

    //========================================================
    // IF response
    //========================================================
    assign iresp.addr_ok = hit ? 1'b1 : dresp.addr_ok;

    assign iresp.data_ok =
        hit ? 1'b1 :
        (dresp.data_ok && miss_pending);

    assign iresp.data =
        hit
            ? (ireq.addr[2] ? cache_data[63:32] : cache_data[31:0])
            : (req_hi      ? dresp.data[63:32]  : dresp.data[31:0]);

`ifdef DEBUG
    always_ff @(posedge clk) begin
        if (!reset) begin
            if (miss_fire) begin
                $display("[IBUS] miss_fire iaddr=%h line=%h hi=%b",
                         ireq.addr, {ireq.addr[63:3], 3'b000}, ireq.addr[2]);
            end

            if (dresp.data_ok && miss_pending) begin
                $display("[IBUS] data_ok req_addr=%h req_hi=%b ddata=%h inst=%h",
                         req_addr,
                         req_hi,
                         dresp.data,
                         req_hi ? dresp.data[63:32] : dresp.data[31:0]);
            end

            if (hit) begin
                $display("[IBUS] hit iaddr=%h cache_addr=%h inst=%h",
                         ireq.addr,
                         cache_addr,
                         ireq.addr[2] ? cache_data[63:32] : cache_data[31:0]);
            end
        end
    end
`endif


endmodule