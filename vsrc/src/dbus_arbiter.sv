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
`ifdef DEBUG
 always_ff @(posedge clk) begin
    if (!reset) begin
        if (busy && final_resp.addr_ok && final_resp.data_ok) begin
            $display("[DBUS_DONE] index=%0d accepted=%b final_addr=%h strobe=%h data=%h",
                     index, req_accepted, final_req.addr, final_req.strobe, final_req.data);
        end

        if (!busy && selected_req.valid) begin
            $display("[DBUS_ACCEPT] select=%0d addr=%h strobe=%h data=%h req0_valid=%b req1_valid=%b",
                     select, selected_req.addr, selected_req.strobe, selected_req.data,
                     reqs[0].valid, reqs[1].valid);
        end

 if (busy && final_resp.addr_ok && final_resp.data_ok) begin
    $display("[DBUS_SAME_CYCLE_DONE] index=%0d accepted=%b will_clear=%b addr=%h strobe=%h data=%h",
             index, req_accepted,
             req_accepted && final_resp.data_ok,
             final_req.addr, final_req.strobe, final_req.data);
 end

    end
 end

 always_ff @(posedge clk) begin
    if (!reset) begin
        if (busy && final_resp.addr_ok && final_resp.data_ok && !req_accepted) begin
            $display("[BUG_CONFIRM] addr_ok and data_ok same cycle while req_accepted=0, addr=%h strobe=%h data=%h",
                     final_req.addr, final_req.strobe, final_req.data);
        end

        if (busy && req_accepted && !final_resp.data_ok) begin
            $display("[STALE_BUSY] accepted=1 but data_ok already missed, addr=%h strobe=%h data=%h",
                     final_req.addr, final_req.strobe, final_req.data);
        end
    end
 end
`endif



    logic busy;
    logic req_accepted;

    int index;
    int select;

    dbus_req_t saved_req;
    dbus_req_t selected_req;

    assign final_req = busy ? saved_req : '0;
    assign selected_req = reqs[select];

    always_comb begin
        select = 0;
        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (reqs[i].valid) begin
                select = i;
                break;
            end
        end
    end

    always_comb begin
        resps = '0;

        if (busy && req_accepted) begin
        //if (busy && (req_accepted || final_resp.addr_ok)) begin

            for (int i = 0; i < NUM_INPUTS; i++) begin
                if (index == i) begin
                    resps[i] = final_resp;
                end
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            busy         <= 1'b0;
            req_accepted <= 1'b0;
            index        <= 0;
            saved_req    <= '0;
        end
        else begin
            if (busy) begin
                if (final_resp.addr_ok) begin
                    req_accepted <= 1'b1;
                end

                if (req_accepted && final_resp.data_ok) begin
                //if (final_resp.data_ok && (req_accepted || final_resp.addr_ok)) begin
                //if ((req_accepted || final_resp.addr_ok) && final_resp.data_ok) begin
                    busy         <= 1'b0;
                    req_accepted <= 1'b0;
                    saved_req    <= '0;
                end
            end
            else begin
                if (selected_req.valid) begin
                    busy         <= 1'b1;
                    req_accepted <= 1'b0;
                    index        <= select;
                    saved_req    <= selected_req;
                end
            end
        end
    end


`ifdef DEBUG
 always_ff @(posedge clk) begin
    if (!reset) begin
        if (busy || final_resp.addr_ok || final_resp.data_ok) begin
            $display("[DBUS_STATE] busy=%b index=%0d accepted=%b final_valid=%b final_addr=%h addr_ok=%b data_ok=%b resp_data=%h",
                     busy, index, req_accepted,
                     final_req.valid, final_req.addr,
                     final_resp.addr_ok, final_resp.data_ok, final_resp.data);
        end
    end
 end


    always_ff @(posedge clk) begin
        if (!reset) begin
            if (busy) begin
                $display("[DBUS_ARB] busy=%b accepted=%b index=%0d final_addr=%h size=%0d strobe=%h final_data_ok=%b final_data=%h",
                         busy, req_accepted, index,
                         final_req.addr, final_req.size, final_req.strobe,
                         final_resp.data_ok, final_resp.data);
            end
        end
    end
`endif


endmodule