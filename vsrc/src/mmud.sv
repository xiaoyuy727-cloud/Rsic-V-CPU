`ifndef __MMU_SV
`define __MMU_SV

`ifdef VERILATOR
    `include "include/common.sv"
`else
    `include "../include/common.sv"
`endif

module mmu (
    input logic clk,
    input logic reset,

    input dbus_req_t dbus_req_in,
    output dbus_resp_t dbus_resp_out,

    output cbus_req_t cbus_req_out,
    input cbus_resp_t cbus_resp_in,

    input logic[1:0] priv_mode,
    input u64 satp
);

localparam SV39_MODE=4'd8;
localparam PTE_V=0;


typedef enum logic[3:0] {
    IDLE,WAIT_L2,WAIT_L1,WAIT_L0,ACCESS,FAULT
} state_t;

state_t state,next_state;

logic mmu_enable;
logic [8:0] vpn2, vpn1, vpn0;
logic [11:0] offset;
u64 pte;
addr_t paddr;
dbus_req_t req_latch;
logic mmu_enable_latched;
logic busy;

assign busy=(state!=IDLE);
assign mmu_enable=(priv_mode!=2'b11)&&(satp[63:60]==SV39_MODE);
assign vpn2=req_latch.addr[38:30];
assign vpn1=req_latch.addr[29:21];
assign vpn0=req_latch.addr[20:12];
assign offset=req_latch.addr[11:0];

always_ff @(posedge clk) begin
    if (reset) begin
        req_latch<='0;
        mmu_enable_latched<='0;
    end else if (dbus_req_in.valid&&!busy) begin
        req_latch<=dbus_req_in;
        mmu_enable_latched<=mmu_enable;
    end
end

always_ff @(posedge clk) begin
    if (reset)
        state<=IDLE;
    else
        state<=next_state;
end

always_ff @(posedge clk) begin
    if (reset)
        pte<='0;
    else if ((state==WAIT_L2||state==WAIT_L1||state==WAIT_L0)&&cbus_resp_in.ready&&cbus_resp_in.last)
        pte<=cbus_resp_in.data;
end

always_comb begin
    next_state=state;
    unique case (state)
        IDLE: begin
            if (dbus_req_in.valid)
                next_state=mmu_enable?WAIT_L2:ACCESS;
        end
        WAIT_L2: begin
            if (!(cbus_resp_in.ready&&cbus_resp_in.last)) next_state=WAIT_L2;
            else if (!cbus_resp_in.data[PTE_V]) next_state=FAULT;
            else next_state=WAIT_L1;
        end
        WAIT_L1: begin
            if (!(cbus_resp_in.ready&&cbus_resp_in.last)) next_state=WAIT_L1;
            else if (!cbus_resp_in.data[PTE_V]) next_state=FAULT;
            else next_state=WAIT_L0;
        end
        WAIT_L0: begin
            if (!(cbus_resp_in.ready&&cbus_resp_in.last)) next_state=WAIT_L0;
            else if (!cbus_resp_in.data[PTE_V]) next_state=FAULT;
            else next_state=ACCESS;
        end
        ACCESS: begin
            if (cbus_resp_in.ready&&cbus_resp_in.last) next_state=IDLE;
        end
        FAULT: next_state=IDLE;
        default: next_state=IDLE;
    endcase
end

always_comb begin
    if (!mmu_enable_latched) begin
        paddr=req_latch.addr;
    end else begin
        paddr=64'({pte[53:10],offset});
    end
end

always_comb begin
    cbus_req_out='0;
    unique case (state)
        WAIT_L2: begin
            cbus_req_out.valid=1'b1;
            cbus_req_out.is_write=1'b0;
            cbus_req_out.addr=64'({satp[43:0],12'b0})+64'(vpn2<<3);
            cbus_req_out.size=MSIZE8;
            cbus_req_out.strobe='0;
            cbus_req_out.data='0;
            cbus_req_out.len=MLEN1;
            cbus_req_out.burst=AXI_BURST_FIXED;
        end
        WAIT_L1: begin
            cbus_req_out.valid=1'b1;
            cbus_req_out.is_write=1'b0;
            cbus_req_out.addr=64'({pte[53:10],12'b0})+64'(vpn1<<3);
            cbus_req_out.size=MSIZE8;
            cbus_req_out.strobe='0;
            cbus_req_out.data='0;
            cbus_req_out.len=MLEN1;
            cbus_req_out.burst=AXI_BURST_FIXED;
        end
        WAIT_L0: begin
            cbus_req_out.valid=1'b1;
            cbus_req_out.is_write=1'b0;
            cbus_req_out.addr=64'({pte[53:10],12'b0})+64'(vpn0<<3);
            cbus_req_out.size=MSIZE8;
            cbus_req_out.strobe='0;
            cbus_req_out.data='0;
            cbus_req_out.len=MLEN1;
            cbus_req_out.burst=AXI_BURST_FIXED;
        end
        ACCESS: begin
            cbus_req_out.valid=req_latch.valid;
            cbus_req_out.is_write=(req_latch.strobe!='0);
            cbus_req_out.addr=paddr;
            cbus_req_out.size=req_latch.size;
            cbus_req_out.strobe=req_latch.strobe;
            cbus_req_out.data=req_latch.data;
            cbus_req_out.len=MLEN1;
            cbus_req_out.burst=AXI_BURST_FIXED;
        end
        default:;
    endcase
end

always_comb begin
    dbus_resp_out='0;
    unique case (state)
        IDLE: dbus_resp_out.addr_ok=dbus_req_in.valid;
        FAULT: begin
            dbus_resp_out.addr_ok=1'b1;
            dbus_resp_out.data_ok=1'b1;
            dbus_resp_out.data='0;
        end
        ACCESS: begin
            dbus_resp_out.addr_ok=1'b1;
            dbus_resp_out.data_ok=cbus_resp_in.ready&&cbus_resp_in.last;
            dbus_resp_out.data=cbus_resp_in.data;
        end
        default: begin
            dbus_resp_out.addr_ok=1'b1;
            dbus_resp_out.data_ok=1'b0;
        end
    endcase
end

endmodule

`endif