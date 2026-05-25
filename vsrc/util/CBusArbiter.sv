`ifndef __CBUSARBITER_SV
`define __CBUSARBITER_SV

`ifdef VERILATOR
`include "include/common.sv"
`else

`endif
/**
 * this implementation is not efficient, since
 * it adds one cycle lantency to all requests.
 */

module CBusArbiter
	import common::*;#(
    parameter int NUM_INPUTS = 2,  // NOTE: NUM_INPUTS >= 1

    localparam int MAX_INDEX = NUM_INPUTS - 1
) (
    input logic clk, reset,

    input  cbus_req_t  [MAX_INDEX:0] ireqs,
    output cbus_resp_t [MAX_INDEX:0] iresps,
    output cbus_req_t  oreq,
    input  cbus_resp_t oresp
);


`ifdef DEBUG
always_ff @(posedge clk) begin
    if (!reset) begin
        if (busy) begin
            $display("[CBUS_ARB_BUSY] busy=%b index=%0d o_valid=%b o_addr=%h o_strobe=%h o_data=%h | saved_valid=%b saved_addr=%h saved_strobe=%h saved_data=%h | live_valid=%b live_addr=%h live_strobe=%h live_data=%h | ready=%b last=%b",
                     busy, index,
                     oreq.valid, oreq.addr, oreq.strobe, oreq.data,
                     saved_req.valid, saved_req.addr, saved_req.strobe, saved_req.data,
                     ireqs[index].valid, ireqs[index].addr, ireqs[index].strobe, ireqs[index].data,
                     oresp.ready, oresp.last);
        end
    end
end
`endif

// CBusArbiter.sv
`ifdef DEBUG
always_ff @(posedge clk) begin
    if (!reset) begin
        $display("[CBUS_ARB] busy=%b index=%0d ovalid=%b oaddr=%h ostrobe=%h ready=%b last=%b",
                 busy, index, oreq.valid, oreq.addr, oreq.strobe,
                 oresp.ready, oresp.last);
    end
end
`endif



    logic busy;
    int index, select;
    cbus_req_t saved_req, selected_req;

    // assign oreq = ireqs[index];
    assign oreq = busy ? saved_req : '0;  // prevent early issue
    assign selected_req = ireqs[select];

    // select a preferred request
    always_comb begin
        select = 0;

        for (int i = 0; i < NUM_INPUTS; i++) begin
            if (ireqs[i].valid) begin
                select = i;
                break;
            end
        end
    end

    // feedback to selected request
    always_comb begin
        iresps = '0;

        if (busy) begin
            for (int i = 0; i < NUM_INPUTS; i++) begin
                if (index == i)
                    iresps[i] = oresp;
            end
        end
    end

    always_ff @(posedge clk)
    if (~reset) begin
        if (busy) begin
            if (oresp.last)
                {busy, saved_req} <= '0;
        end else begin

`ifdef DEBUG
        if (busy) begin
            $display("[CBUS_ARB_BUSY] index=%0d o_valid=%b o_addr=%h o_strobe=%h o_data=%h | saved_valid=%b saved_addr=%h saved_strobe=%h saved_data=%h | live_valid=%b live_addr=%h live_strobe=%h live_data=%h | ready=%b last=%b",
                     index,
                     oreq.valid, oreq.addr, oreq.strobe, oreq.data,
                     saved_req.valid, saved_req.addr, saved_req.strobe, saved_req.data,
                     ireqs[index].valid, ireqs[index].addr, ireqs[index].strobe, ireqs[index].data,
                     oresp.ready, oresp.last);
        end

        if (!busy && selected_req.valid) begin
            $display("[CBUS_ARB_ACCEPT] select=%0d addr=%h strobe=%h data=%h valid=%b",
                     select, selected_req.addr, selected_req.strobe, selected_req.data, selected_req.valid);
        end

        if (busy && oresp.last) begin
            $display("[CBUS_ARB_DONE] index=%0d oaddr=%h ostrobe=%h odata=%h saved_addr=%h saved_strobe=%h saved_data=%h",
                     index, oreq.addr, oreq.strobe, oreq.data,
                     saved_req.addr, saved_req.strobe, saved_req.data);
        end
        
`endif


            // if not valid, busy <= 0
            busy <= selected_req.valid;
            index <= select;
            saved_req <= selected_req;
        end
    end else begin
        {busy, index, saved_req} <= '0;
    end

    `UNUSED_OK({saved_req});
endmodule



`endif