`ifdef VERILATOR
`include "include/common.sv"
`endif

module dbus_arbiter import common::*; #(
    parameter int NUM_INPUTS = 2,
    localparam int MAX_INDEX = NUM_INPUTS - 1
) (
    input  logic clk,
    input  logic reset,

    input  dbus_req_t  [MAX_INDEX:0] reqs,
    output dbus_resp_t [MAX_INDEX:0] resps,

    output dbus_req_t  final_req,
    input  dbus_resp_t final_resp
);

    logic busy;
    int   index;

    dbus_req_t saved_req;

    logic has_req;
    int   selected;

    logic done_now;

    assign done_now = busy && final_resp.data_ok;

    always_comb begin
        has_req  = 1'b0;
        selected = 0;

        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (!has_req && reqs[i].valid) begin
                has_req  = 1'b1;
                selected = i;
            end
        end
    end

    always_comb begin
        final_req = '0;

        if (busy) begin
            final_req = saved_req;
        end
    end

    always_comb begin
        resps = '0;

        if (done_now) begin
            resps[index] = final_resp;
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            busy      <= 1'b0;
            index     <= 0;
            saved_req <= '0;
        end
        else begin
            if (busy) begin
                if (final_resp.data_ok) begin
                    busy      <= 1'b0;
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
            $display("[DBUS_STATE] busy=%b index=%0d final_valid=%b final_addr=%h data_ok=%b done_now=%b resp_data=%h saved_req=%h req0_valid=%b req0_addr=%h req1_valid=%b req1_addr=%h",
                     busy, index,
                     final_req.valid, final_req.addr,
                     final_resp.data_ok, done_now,
                     final_resp.data, saved_req,
                     reqs[0].valid, reqs[0].addr,
                     reqs[1].valid, reqs[1].addr);
        end
    end
`endif

endmodule