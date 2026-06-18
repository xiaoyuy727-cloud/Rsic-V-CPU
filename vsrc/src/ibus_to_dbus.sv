`ifdef VERILATOR
`include "include/common.sv"
`endif

// 功能：把 ibus 转成 dbus 形式，然后进入 arbiter 仲裁
// 语义：
//   cancel/flush 表示当前取指事务被流水线重定向取消。
//   被取消后：
//     1. 不再发出新的 dreq
//     2. 已经 pending 的 miss 不再接收 dresp
//     3. 不向 IF 返回 addr_ok/data_ok
//     4. 清空本地 instruction line cache，避免 satp/priv 切换后复用旧行
module ibus_to_dbus import common::*;(
    input  logic       clk,
    input  logic       reset,
    input  logic       cancel,

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
    logic accept_resp;

    //========================================================
    // 命中判断
    // cancel 当拍，当前 I-side 事务无效，不能 hit
    //========================================================
    assign hit =
        !cancel &&
        cache_valid &&
        ireq.valid &&
        (cache_addr[63:3] == ireq.addr[63:3]);

    // 只允许同一时间一个 IBus miss 在路上
    // cancel 当拍禁止发新请求
    assign miss_fire =
        !cancel &&
        ireq.valid &&
        !hit &&
        !miss_pending;

    // 只有当前确实有未取消的 pending miss，才能接收返回
    assign accept_resp =
        !cancel &&
        miss_pending &&
        dresp.data_ok;

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
        else if (cancel) begin
            // 事务级取消：
            // 当前 pending miss 不再属于新的控制流，必须丢弃。
            req_addr     <= 64'b0;
            req_hi       <= 1'b0;
            miss_pending <= 1'b0;

            // mret/ecall/satp 相关重定向后，不复用旧取指行。
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
            if (accept_resp) begin
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
    // cancel 当拍不向 IF 返回任何旧事务响应
    //========================================================
    assign iresp.addr_ok =
        !cancel &&
        (hit ? 1'b1 : dresp.addr_ok);

    // cancel 时强制 data_ok=1，让 IF 从等待中退出（遇到 page fault 等场景）
    assign iresp.data_ok =
        cancel ? 1'b1 :
        (hit ? 1'b1 : (dresp.data_ok && miss_pending));

    assign iresp.data =
        hit
            ? (ireq.addr[2] ? cache_data[63:32] : cache_data[31:0])
            : (req_hi      ? dresp.data[63:32]  : dresp.data[31:0]);

`ifdef DEBUG
    always_ff @(posedge clk) begin
        if (!reset) begin
            if (cancel) begin
                $display("[IBUS_CANCEL] pending=%b req_addr=%h req_hi=%b cache_valid=%b cache_addr=%h",
                         miss_pending, req_addr, req_hi, cache_valid, cache_addr);
            end

            if (miss_fire) begin
                $display("[IBUS] miss_fire iaddr=%h line=%h hi=%b",
                         ireq.addr, {ireq.addr[63:3], 3'b000}, ireq.addr[2]);
            end

            if (accept_resp) begin
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