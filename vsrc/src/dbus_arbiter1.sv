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

    output dbus_req_t  final_req,
    input  dbus_resp_t final_resp
);

    // ======================================================
    // 基础仲裁状态
    // ======================================================
    logic busy;
    int   index;

    dbus_req_t saved_req;

    logic has_req;
    int   selected;

    logic done_now;

    assign done_now = !cancel && busy && final_resp.data_ok;

    // ======================================================
    // ✨ NEW: request type tagging（IMEM / DMEM归属）
    // ======================================================
    typedef enum logic {
        REQ_IFETCH = 1'b0,
        REQ_LOAD   = 1'b1
    } req_type_t;

    req_type_t saved_req_type;

    // ======================================================
    // ✨ NEW: exception shadow metadata（不进bus！）
    // ======================================================
    logic        saved_ex_valid;
    logic [3:0]  saved_ex_cause;
    logic [63:0] saved_ex_addr;

    // ======================================================
    // 选择请求
    // ======================================================
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

    // ======================================================
    // final request output
    // ======================================================
    always_comb begin
        final_req = '0;

        if (!cancel && busy) begin
            final_req = saved_req;
        end
    end

    // ======================================================
    // response routing
    // ======================================================
    always_comb begin
        resps = '0;

        if (done_now) begin
            resps[index] = final_resp;
        end
    end

    // ======================================================
    // FSM
    // ======================================================
    always_ff @(posedge clk) begin
        if (reset) begin
            busy <= 1'b0;
            index <= 0;
            saved_req <= '0;

            saved_req_type <= REQ_LOAD;

            saved_ex_valid <= 0;
            saved_ex_cause <= 0;
            saved_ex_addr  <= 0;
        end

        else if (cancel) begin
            busy <= 1'b0;
            index <= 0;
            saved_req <= '0;

            saved_ex_valid <= 0;
            saved_ex_cause <= 0;
            saved_ex_addr  <= 0;
        end

        else begin

            // ==================================================
            // busy state
            // ==================================================
            if (busy) begin
                if (final_resp.data_ok) begin
                    busy <= 1'b0;
                    index <= 0;
                    saved_req <= '0;

                    saved_ex_valid <= 0;
                end
            end

            // ==================================================
            // accept new request
            // ==================================================
            else begin
                if (has_req) begin
                    busy <= 1'b1;
                    index <= selected;
                    saved_req <= reqs[selected];

                    // ==================================================
                    // ✨ NEW: tag request source (IMEM / DMEM)
                    // ==================================================
                    if (selected == 0)
                        saved_req_type <= REQ_IFETCH;  // IMEM
                    else
                        saved_req_type <= REQ_LOAD;    // DMEM

                    // ==================================================
                    // ✨ NEW: bind exception shadow (from MMU later)
                    // ==================================================
                    saved_ex_valid <= 1'b0;
                    saved_ex_cause <= 4'b0;
                    saved_ex_addr  <= reqs[selected].addr;
                end
            end

        end
    end

endmodule