`ifndef __CORE_SV
`define __CORE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`include "src/datapath.sv"
`endif


module core import common::*;(
	input  logic       clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
	input  logic       trint, swint, exint
);
	/* TODO: Add your CPU-Core here. */

	logic [1:0] privil_mode;
	
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

	logic mem;
	logic [63:0] memaddr;

	logic [63:0] csr_mstatus;
    logic [63:0] csr_mtvec;
    logic [63:0] csr_mip;
    logic [63:0] csr_mie;
    logic [63:0] csr_mscratch;
    logic [63:0] csr_mcause;
    logic [63:0] csr_mtval;
    logic [63:0] csr_mepc;
    logic [63:0] csr_mcycle;
    logic [63:0] csr_mhartid;
    logic [63:0] csr_satp; 

	datapath u_datapath (
		.clk         (clk),
		.reset       (reset),

		.mem		 (mem),
		.memaddr	 (memaddr),

		.ibus_resp   (iresp),
		.ibus_req    (ireq),
		.dbus_resp   (dresp),
		.dbus_req    (dreq),
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
		.test_reg_x31 (test_reg_x31),

		.csr_mstatus (csr_mstatus),
		.csr_mtvec	 (csr_mtvec),
		.csr_mip	 (csr_mip),
		.csr_mie	 (csr_mie),
		.csr_mscratch(csr_mscratch),
		.csr_mcause	 (csr_mcause),
		.csr_mtval	 (csr_mtval),
		.csr_mepc	 (csr_mepc),
		.csr_mcycle	 (csr_mcycle),
		.csr_mhartid (csr_mhartid),
		.csr_satp	 (csr_satp),

		.privil_mode   (privil_mode)
	);

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (valid),//当前指令是否有效
		.pc                 (test_pc),//
		.instr              (test_instr),//
		.skip    			(mem & memaddr[31] == 0),//(mem & memaddr[31] == 0)或者0
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
		.priviledgeMode     (privil_mode),
		.mstatus            (csr_mstatus),
		.sstatus		    (csr_mstatus & 64'h8000_0003_000D_E122),
		.mepc               (csr_mepc),
		.sepc               (0),
		.mtval              (csr_mtval),
		.stval              (0),
		.mtvec              (csr_mtvec),
		.stvec              (0),
		.mcause             (csr_mcause),
		.scause             (0),
		.satp               (csr_satp ),
		.mip                (csr_mip),
		.mie                (csr_mie),
		.mscratch           (csr_mscratch),
		.sscratch           (0),
		.mideleg            (0),
		.medeleg            (0)
	);
`endif
endmodule
`endif
