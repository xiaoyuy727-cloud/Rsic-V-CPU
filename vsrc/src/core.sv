`ifndef __CORE_SV
`define __CORE_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif
`include "src/datapath.sv"


module core import common::*;(
	input  logic       clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
	input  logic       trint, swint, exint
);
	/* TODO: Add your CPU-Core here. */
		logic [63:0] test_reg_x0;
	logic [63:0] test_reg_x1;
	logic [63:0] test_reg_x2;
	logic [63:0] test_reg_x3;
	logic [63:0] test_reg_x4;
	logic [63:0] test_reg_x5;
	logic [63:0] test_reg_x6;
	logic [63:0] test_reg_x7;
	logic [63:0] test_reg_x8;
	logic [63:0] test_reg_x9;
	logic [63:0] test_reg_x10;
	logic [63:0] test_reg_x11;
	logic [63:0] test_reg_x12;
	logic [63:0] test_reg_x13;
	logic [63:0] test_reg_x14;
	logic [63:0] test_reg_x15;
	logic [63:0] test_reg_x16;
	logic [63:0] test_reg_x17;
	logic [63:0] test_reg_x18;
	logic [63:0] test_reg_x19;
	logic [63:0] test_reg_x20;
	logic [63:0] test_reg_x21;
	logic [63:0] test_reg_x22;
	logic [63:0] test_reg_x23;
	logic [63:0] test_reg_x24;
	logic [63:0] test_reg_x25;
	logic [63:0] test_reg_x26;
	logic [63:0] test_reg_x27;
	logic [63:0] test_reg_x28;
	logic [63:0] test_reg_x29;
	logic [63:0] test_reg_x30;
	logic [63:0] test_reg_x31;

	logic [31:0] test_instr;
	logic [63:0] test_pc;
	logic test_wen;
	logic [4:0] test_wdest;
	logic [63:0] test_wdata;

	logic valid;

	assign dreq = '0;//

	datapath u_datapath (
		.clk         (clk),
		.reset       (reset),

		.ibus_resp   (iresp),
		.ibus_req    (ireq),
		.PCINIT		 (PCINIT),

		.valid		 (valid),
		.test_pc	 (test_pc),
		.test_instr	 (test_instr),
		.test_wen	 (test_wen),
		.test_wdata  (test_wdata),
		.test_wdest	 (test_wdest),

		.test_reg_x0  (test_reg_x0),
		.test_reg_x1  (test_reg_x1),
		.test_reg_x2  (test_reg_x2),
		.test_reg_x3  (test_reg_x3),
		.test_reg_x4  (test_reg_x4),
		.test_reg_x5  (test_reg_x5),
		.test_reg_x6  (test_reg_x6),
		.test_reg_x7  (test_reg_x7),
		.test_reg_x8  (test_reg_x8),
		.test_reg_x9  (test_reg_x9),
		.test_reg_x10 (test_reg_x10),
		.test_reg_x11 (test_reg_x11),
		.test_reg_x12 (test_reg_x12),
		.test_reg_x13 (test_reg_x13),
		.test_reg_x14 (test_reg_x14),
		.test_reg_x15 (test_reg_x15),
		.test_reg_x16 (test_reg_x16),
		.test_reg_x17 (test_reg_x17),
		.test_reg_x18 (test_reg_x18),
		.test_reg_x19 (test_reg_x19),
		.test_reg_x20 (test_reg_x20),
		.test_reg_x21 (test_reg_x21),
		.test_reg_x22 (test_reg_x22),
		.test_reg_x23 (test_reg_x23),
		.test_reg_x24 (test_reg_x24),
		.test_reg_x25 (test_reg_x25),
		.test_reg_x26 (test_reg_x26),
		.test_reg_x27 (test_reg_x27),
		.test_reg_x28 (test_reg_x28),
		.test_reg_x29 (test_reg_x29),
		.test_reg_x30 (test_reg_x30),
		.test_reg_x31 (test_reg_x31)
	);

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (valid),//当前指令是否有效
		.pc                 (test_pc),//
		.instr              (test_instr),//
		.skip               (0),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (test_wen),//
		.wdest              ({3'b000, test_wdest}),//
		.wdata              (test_wdata)//
	);

	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (0),
		.gpr_0              (test_reg_x0),
		.gpr_1              (test_reg_x1),
		.gpr_2              (test_reg_x2),
		.gpr_3              (test_reg_x3),
		.gpr_4              (test_reg_x4),
		.gpr_5              (test_reg_x5),
		.gpr_6              (test_reg_x6),
		.gpr_7              (test_reg_x7),
		.gpr_8              (test_reg_x8),
		.gpr_9              (test_reg_x9),
		.gpr_10             (test_reg_x10),
		.gpr_11             (test_reg_x11),
		.gpr_12             (test_reg_x12),
		.gpr_13             (test_reg_x13),
		.gpr_14             (test_reg_x14),
		.gpr_15             (test_reg_x15),
		.gpr_16             (test_reg_x16),
		.gpr_17             (test_reg_x17),
		.gpr_18             (test_reg_x18),
		.gpr_19             (test_reg_x19),
		.gpr_20             (test_reg_x20),
		.gpr_21             (test_reg_x21),
		.gpr_22             (test_reg_x22),
		.gpr_23             (test_reg_x23),
		.gpr_24             (test_reg_x24),
		.gpr_25             (test_reg_x25),
		.gpr_26             (test_reg_x26),
		.gpr_27             (test_reg_x27),
		.gpr_28             (test_reg_x28),
		.gpr_29             (test_reg_x29),
		.gpr_30             (test_reg_x30),
		.gpr_31             (test_reg_x31)
	);

    DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (0),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);

	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (0),
		.priviledgeMode     (3),
		.mstatus            (0),
		.sstatus            (0 /* mstatus & 64'h800000030001e000 */),
		.mepc               (0),
		.sepc               (0),
		.mtval              (0),
		.stval              (0),
		.mtvec              (0),
		.stvec              (0),
		.mcause             (0),
		.scause             (0),
		.satp               (0),
		.mip                (0),
		.mie                (0),
		.mscratch           (0),
		.sscratch           (0),
		.mideleg            (0),
		.medeleg            (0)
	);
`endif
endmodule
`endif