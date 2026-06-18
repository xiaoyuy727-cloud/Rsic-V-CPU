`ifdef VERILATOR
`include "include/common.sv"
`endif

module dbus_arbiter import common::*; #(
    parameter int NUM_INPUTS = 2,
    localparam int MAX_INDEX = NUM_INPUTS - 1
) (
    input  logic clk,
    input  logic reset,
    input  logic cancel,

    input  dbus_req_t  [MAX_INDEX:0] reqs,
    output dbus_resp_t [MAX_INDEX:0] resps,
    output access_type_t access_type,

    output dbus_req_t  final_req,
    input  dbus_resp_t final_resp
);

    logic busy;
    int   index;

    dbus_req_t saved_req;

    logic has_req;
    int   selected;

    logic done_now;

    // cancel 当拍，旧事务无效，不能完成、不能回 resp
    assign done_now = !cancel && busy && final_resp.data_ok;

    // ---- 当前活跃请求的访问类型 ----
    // reqs[1] = instr fetch, reqs[0] = data access
    assign access_type =
        (!busy)         ? FETCH :
        (index == 1)    ? FETCH :
        (|saved_req.strobe) ? STORE : LOAD;

    //========================================================
    // 从输入请求中选择一个
    // reqs[0] 优先级最高，reqs[NUM_INPUTS-1] 最低
    //
    // 注意：
    //   cancel 当拍不接受新请求。
    //   因为 cancel 代表控制流切换，旧请求源可能还没来得及撤销。
    //========================================================
    always_comb begin
        has_req  = 1'b0;
        selected = 0;

        if (!cancel) begin
            for (int i = 0; i < NUM_INPUTS; i++) begin
                if (!has_req && reqs[i].valid) begin
                    has_req  = 1'b1;
                    selected = i;
                end
            end
        end
    end

    //========================================================
    // 输出给下游 MMU / memory 的请求
    //
    // 这个 arbiter 是“锁存后发送”语义：
    //   只有 busy 的 saved_req 会送到 final_req。
    //   新选择的 reqs[selected] 会在下一拍进入 saved_req。
    //
    // cancel 当拍不允许旧 saved_req 继续出现。
    //========================================================
    always_comb begin
        final_req = '0;

        if (!cancel && busy) begin
            final_req = saved_req;
        end
    end

    //========================================================
    // 返回给被仲裁输入端的响应
    //
    // 只有当前 saved_req 对应的 index 可以收到 final_resp。
    // cancel 当拍丢弃 final_resp，避免旧事务污染上游。
    //========================================================
    always_comb begin
        resps = '0;

        if (done_now) begin
            resps[index] = final_resp;
        end
    end

    //========================================================
    // 仲裁状态
    //========================================================
    always_ff @(posedge clk) begin
        if (reset) begin
            busy      <= 1'b0;
            index     <= 0;
            saved_req <= '0;
        end
        else if (cancel) begin
            // 事务级取消：
            // 当前 saved_req 不再有效，不能继续送进 MMU。
            busy      <= 1'b0;
            index     <= 0;
            saved_req <= '0;
        end
        else begin
            if (busy) begin
                if (final_resp.data_ok) begin
                    busy      <= 1'b0;
                    index     <= 0;
                    saved_req <= '0;
                end
            end
            else begin
                if (has_req) begin
                    busy      <= 1'b1;
                    index     <= selected;
                    saved_req <= reqs[selected];
                end
            end
        end
    end

`ifdef DEBUG
    always_ff @(posedge clk) begin
        if (!reset) begin
            if (cancel) begin
                $display("[DBUS_CANCEL] busy=%b index=%0d saved_valid=%b saved_addr=%h final_valid=%b final_addr=%h final_data_ok=%b final_data=%h req0_valid=%b req0_addr=%h req1_valid=%b req1_addr=%h",
                         busy, index,
                         saved_req.valid, saved_req.addr,
                         final_req.valid, final_req.addr,
                         final_resp.data_ok, final_resp.data,
                         reqs[0].valid, reqs[0].addr,
                         reqs[1].valid, reqs[1].addr);
            end

            $display("[DBUS_STATE] busy=%b index=%0d final_valid=%b final_addr=%h data_ok=%b done_now=%b resp_data=%h saved_valid=%b saved_addr=%h req0_valid=%b req0_addr=%h req1_valid=%b req1_addr=%h",
                     busy, index,
                     final_req.valid, final_req.addr,
                     final_resp.data_ok, done_now,
                     final_resp.data,
                     saved_req.valid, saved_req.addr,
                     reqs[0].valid, reqs[0].addr,
                     reqs[1].valid, reqs[1].addr);
        end
    end
`endif

endmodule