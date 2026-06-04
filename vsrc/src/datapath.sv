`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`include "src/alu_adder.sv"
`include "src/alu.sv"
`include "src/alures_mux.sv"
`include "src/load_use_hazard.sv"
`include "src/branch_cmp.sv"
`include "src/control_unit.sv"
`include "src/ex_mem_reg.sv"
`include "src/id_ex_reg.sv"
`include "src/if_id_reg.sv"
`include "src/instr_mem.sv"
`include "src/mem_wb_reg.sv"
`include "src/pc_reg.sv"
`include "src/redirect_pc_unit.sv"
`include "src/redirect_valid_unit.sv"
`include "src/reg_file.sv"
`include "src/saf_unit.sv"
`include "src/sign12to64.sv"
`include "src/sign32to64.sv"
`include "src/srcb_mux.sv"
`include "src/srca_mux.sv"
`include "src/data_mem.sv"
`include "src/imm_gen.sv"
`include "src/wbres_mux.sv"
`include "src/csr_file.sv"
`include "src/final_redirect_pc_unit.sv"
`include "src/privilege_unit.sv"
`include "src/dbus_arbiter.sv"
`include "src/mmu.sv"
`include "src/ibus_to_dbus.sv"
`endif

module datapath import common::*;(
    input  logic        clk,
    input  logic        reset,
    input  logic [63:0] PCINIT,

    input logic         trint,
    input logic         swint,
    input logic         exint,

    input  ibus_resp_t  ibus_resp,
    output ibus_req_t   ibus_req,

    input  dbus_resp_t  dbus_resp,
    output dbus_req_t   dbus_req,

    output logic [31:0] test_instr,
    output logic [63:0] test_pc,
    output logic        test_wen,
    output logic [4:0]  test_wdest,
    output logic [63:0] test_wdata,

    output logic        valid,
    output logic [63:0] test_reg_x0,
    output logic [63:0] test_reg_x1,
    output logic [63:0] test_reg_x2,
    output logic [63:0] test_reg_x3,
    output logic [63:0] test_reg_x4,
    output logic [63:0] test_reg_x5,
    output logic [63:0] test_reg_x6,
    output logic [63:0] test_reg_x7,
    output logic [63:0] test_reg_x8,
    output logic [63:0] test_reg_x9,
    output logic [63:0] test_reg_x10,
    output logic [63:0] test_reg_x11,
    output logic [63:0] test_reg_x12,
    output logic [63:0] test_reg_x13,
    output logic [63:0] test_reg_x14,
    output logic [63:0] test_reg_x15,
    output logic [63:0] test_reg_x16,
    output logic [63:0] test_reg_x17,
    output logic [63:0] test_reg_x18,
    output logic [63:0] test_reg_x19,
    output logic [63:0] test_reg_x20,
    output logic [63:0] test_reg_x21,
    output logic [63:0] test_reg_x22,
    output logic [63:0] test_reg_x23,
    output logic [63:0] test_reg_x24,
    output logic [63:0] test_reg_x25,
    output logic [63:0] test_reg_x26,
    output logic [63:0] test_reg_x27,
    output logic [63:0] test_reg_x28,
    output logic [63:0] test_reg_x29,
    output logic [63:0] test_reg_x30,
    output logic [63:0] test_reg_x31,
    output logic mem,
    output logic [63:0] memaddr,

    output logic [63:0] csr_mstatus,
    output logic [63:0] csr_mtvec,
    output logic [63:0] csr_mip,
    output logic [63:0] csr_mie,
    output logic [63:0] csr_mscratch,
    output logic [63:0] csr_mcause,
    output logic [63:0] csr_mtval,
    output logic [63:0] csr_mepc,
    output logic [63:0] csr_mcycle,
    output logic [63:0] csr_mhartid,
    output logic [63:0] csr_satp,

    output logic [1:0] privil_mode    

);



`ifdef DEBUG
always_ff @(posedge clk) begin
    if ((is_mret_w && valid_w) || (is_ecall_w && valid_w)) begin
        $display("[DP TRAPRET] pc_w=%h instr_w=%h valid_w=%b is_mret_w=%b is_ecall_w=%b csr_mepc=%h csr_mtvec=%h final_redirect_pc=%h privil=%0d satp=%h",
                 pc_w, instr_w, valid_w, is_mret_w, is_ecall_w,
                 csr_mepc, csr_mtvec, final_redirect_pc, privil_mode, csr_satp);
    end
end
`endif




`ifdef DEBUG
always_ff @(posedge clk) begin
    if (is_mret_w || is_ecall_w) begin
        $display("[DP TRAPRET] pc_w=%h instr_w=%h valid_w=%b is_mret_w=%b is_ecall_w=%b csr_mepc=%h csr_mtvec=%h final_redirect_pc=%h",
                 pc_w, instr_w, valid_w, is_mret_w, is_ecall_w,
                 csr_mepc, csr_mtvec, final_redirect_pc);
    end
end
`endif
    // exception & interruption
    logic iaddr_exc_f;
    logic iaddr_exc_d;
    logic iaddr_exc_e;
    logic iaddr_exc_m;
    logic iaddr_exc_w;

    logic daddr_exc_f;
    logic daddr_exc_d;
    logic daddr_exc_e;
    logic daddr_exc_m;
    logic daddr_exc_w;

    logic instr_exc_f;
    logic instr_exc_d;
    logic instr_exc_e;
    logic instr_exc_m;
    logic instr_exc_w;




    // MMU & bus
    logic mmu_flush;

    assign mmu_flush = is_ecall_w | is_mret_w;

    ibus_resp_t  real_ibus_resp;
    ibus_req_t   real_ibus_req;

    dbus_resp_t  real_dbus_resp;
    dbus_req_t   real_dbus_req;

    dbus_resp_t  virtual_dbus_resp;
    dbus_req_t   virtual_dbus_req;

    dbus_resp_t  instr_dbus_resp;
    dbus_req_t   instr_dbus_req;


    ibus_to_dbus itb(
        .clk        (clk),
        .reset      (reset),
        .iresp      (real_ibus_resp), 
        .ireq       (real_ibus_req),
        .dreq       (instr_dbus_req),
        .dresp      (instr_dbus_resp)
    );

    dbus_arbiter ab(
        .clk    (clk),
        .reset  (reset),
        .reqs   ({instr_dbus_req,real_dbus_req}),
        .resps  ({instr_dbus_resp,real_dbus_resp}),
        .final_req  (virtual_dbus_req),
        .final_resp (virtual_dbus_resp)
    );
    mmu mmu(
        .clk    (clk),
        .reset  (reset),
        .flush       (mmu_flush),
        .cpu_req    (virtual_dbus_req),
        .cpu_resp   (virtual_dbus_resp),
        .mem_req    (dbus_req),
        .mem_resp   (dbus_resp),
        .satp       (csr_satp),
        .privil_mode       (privil_mode)
    );


    assign ibus_req='0;



    // =========================================================
    // stall / flush / redirect
    // =========================================================
    logic pc_stall;
    logic if_id_stall;
    logic id_ex_stall;
    logic ex_mem_stall;
    logic mem_wb_stall;
    logic mem_stall;

    logic if_id_flush;
    logic id_ex_flush;
    logic ex_mem_flush;
    logic mem_wb_flush;

    logic        redirect_valid;
    logic [63:0] redirect_pc;

    saf_unit st(
        .is_ecall       (is_ecall_w),
        .is_mret        (is_mret_w),
        .load_use_stall (load_use_stall),
        .mem_stall      (mem_stall),
        .redirect_valid (redirect_valid),
        .pc_stall       (pc_stall),
        .if_id_stall    (if_id_stall),
        .id_ex_stall    (id_ex_stall),
        .ex_mem_stall   (ex_mem_stall),
        .mem_wb_stall   (mem_wb_stall),
        .if_id_flush    (if_id_flush),
        .id_ex_flush    (id_ex_flush),
        .ex_mem_flush   (ex_mem_flush),
        .mem_wb_flush   (mem_wb_flush)  //暂时写成0.避免mret、iecall把自己flush掉。
    );

    // =========================================================
    // csr
    // =========================================================

    
    logic [63:0] csr_value_d;
    logic [63:0] csr_value_e;
    logic [63:0] csr_value_m;
    logic [63:0] csr_value_w;

    logic [11:0] csr_num_d;
    logic [11:0] csr_num_e;
    logic [11:0] csr_num_m;
    logic [11:0] csr_num_w;

    logic [63:0] csr_operand_d;
    logic [63:0] csr_operand_e;
    logic [63:0] csr_operand_m;
    logic [63:0] csr_operand_w;

    logic csrwrite_d;
    logic csrwrite_e;
    logic csrwrite_m;
    logic csrwrite_w;

// CSR 写入 operand
// 注意：这里不是最终写入 CSR 的值。
// CSRRW/CSRRS/CSRRC 传 rs1_val。
// CSRRWI/CSRRSI/CSRRCI 传 zimm。
// 最终 OR / AND / CLEAR 仍然由 csr_file 根据 instr_m[14:12] 完成。
always_comb begin
    unique case (instr_d[14:12])
        3'b001, 3'b010, 3'b011: begin
            csr_operand_d = rs1_val_d;
        end

        3'b101, 3'b110, 3'b111: begin
            csr_operand_d = {59'b0, instr_d[19:15]};
        end

        default: begin
            csr_operand_d = 64'b0;
        end
    endcase
end

csr_file cf(
    .clk    (clk),
    .reset  (reset),

    // D 阶段读 CSR 旧值
    .instr_d(instr_d),

    // M 阶段写 CSR
    // 写在 M 阶段，是为了到 W 阶段 difftest commit 时 CSR 状态已经更新
    .instr_w(instr_w),

    .new_csr_num    (csr_num_w),
    .new_csr_value  (csr_operand_w),
    .csrwrite       (csrwrite_w & valid_w),

    .csr_value      (csr_value_d),
    .csr_num        (csr_num_d),

    .pc_w           (pc_w),
    .is_ecall       (is_ecall_w & valid_w),
    .is_mret        (is_mret_w & valid_w),
    .privil_mode    (privil_mode),

    .csr_mtvec      (csr_mtvec),
    .csr_mip        (csr_mip),
    .csr_mie        (csr_mie),
    .csr_mscratch   (csr_mscratch),
    .csr_mcause     (csr_mcause),
    .csr_mtval      (csr_mtval),
    .csr_mepc       (csr_mepc),
    .csr_mcycle     (csr_mcycle),
    .csr_mhartid    (csr_mhartid),
    .csr_satp       (csr_satp),
    .csr_mstatus    (csr_mstatus)
);

    // =========================================================
    // PRIVILEGE_UNIT
    // =========================================================
    logic is_ecall_f;
    logic is_ecall_d;
    logic is_ecall_e;
    logic is_ecall_m;
    logic is_ecall_w;

    logic is_mret_f;
    logic is_mret_d;
    logic is_mret_e;
    logic is_mret_m;
    logic is_mret_w;



    privilege_unit pu(
        .clk        (clk),
        .rst        (reset),
        .privil_mode    (privil_mode),
        .is_ecall   (is_ecall_w & valid_w),
        .is_mret    (is_mret_w & valid_w),
        .mpp        (csr_mstatus[12:11])

    );


    // =========================================================
    // 1. IF
    // =========================================================
    logic        fetch_ok;
    logic        fetch_consume;

    logic [31:0] instr_f;
    logic [31:0] instr_d;
    logic [31:0] instr_e;
    logic [31:0] instr_m;
    logic [31:0] instr_w;

    logic [63:0] pc_f;
    logic [63:0] pc_d;
    logic [63:0] pc_e;
    logic [63:0] pc_m;
    logic [63:0] pc_w;

    logic valid_d;
    logic valid_e;
    logic valid_m;
    logic valid_w;

    assign fetch_consume = fetch_ok & ~if_id_stall;

    instr_mem if3(
        .clk            (clk),
        .reset          (reset),
        .consume        (fetch_consume),
        .pc_stall       (pc_stall),
        .ibus_resp      (real_ibus_resp),
        .pcinit         (PCINIT),
        .redirect_pc    (final_redirect_pc),
        .branch_redirect_valid (redirect_valid),
        .is_ecall       (is_ecall_w & valid_w),
        .is_mret        (is_mret_w & valid_w),

        .iaddr_exc      (iaddr_exc_f),
        .fetch_ok       (fetch_ok),
        .instr          (instr_f),
        .ibus_req       (real_ibus_req),
        .instr_pc       (pc_f)
    );

    // =========================================================
    // IF/ID
    // =========================================================
    if_id_reg if_id(
        .instr_f     (instr_f),
        .clk         (clk),
        .fetch_ok    (fetch_ok),
        .pc_f        (pc_f),
        .reset       (reset),
        .if_id_stall (if_id_stall),
        .flush       (if_id_flush),
        .instr_d     (instr_d),
        .valid_d     (valid_d),
        .pc_d        (pc_d),
        .iaddr_exc_f (iaddr_exc_f),
        .iaddr_exc_d (iaddr_exc_d)
    );

    // =========================================================
    // 2. ID
    // =========================================================
    logic [2:0]  funct3;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [6:0]  opcode;
    logic [11:0] immediate;

    logic [63:0] imm_d;
    logic [63:0] rs1_val_d;
    logic [63:0] rs2_val_d;

    logic        alusign_d;
    logic [3:0]  aluctrl_d;
    logic [1:0]  alusrca_d;
    logic [1:0]  alusrcb_d;
    logic        regwrite_d;
    logic        mem_write_d;
    logic        mem_read_d;
    logic        mem_sign_d;
    logic [1:0]  wb_result_d;
    logic [1:0]  mem_digit_d;

    logic        cmpsrc_d;
    logic [1:0]  is_baj_d;
    logic [2:0]  branch_type_d;


    assign opcode = instr_d[6:0];
    assign rd     = instr_d[11:7];
    assign funct3 = instr_d[14:12];
    assign rs1    = instr_d[19:15];
    assign rs2    = instr_d[24:20];
    assign immediate = instr_d[31:20];

    logic [4:0] rs1_d, rs2_d;//就是rs1和rs2，接给load use hazard
    logic load_use_stall;

    assign rs1_d = instr_d[19:15];
    assign rs2_d = instr_d[24:20];

    load_use_hazard HZD1(
        .mem_read_e      (mem_read_e),
        .rd_e            (rd_e),
        .rs1_d           (rs1_d),
        .rs2_d           (rs2_d),
        .load_use_stall  (load_use_stall)
    );

    control_unit ID1(
        .funct3        (funct3),
        .opcode        (opcode),
        .bit30         (instr_d[30]),
        .immediate      (immediate),

        .alusign_d     (alusign_d),
        .aluctrl_d     (aluctrl_d),
        .alusrcb_d     (alusrcb_d),
        .regwrite_d    (regwrite_d),
        .mem_write_d   (mem_write_d),
        .mem_read_d    (mem_read_d),
        .mem_sign_d    (mem_sign_d),
        .wb_result_d   (wb_result_d),
        .mem_digit_d   (mem_digit_d),
        .alusrca_d     (alusrca_d),
        .csrwrite_d    (csrwrite_d),
        .is_ecall_d     (is_ecall_d),
        .is_mret_d      (is_mret_d),

        .cmpsrc_d      (cmpsrc_d),
        .is_baj_d      (is_baj_d),
        .branch_type_d (branch_type_d)

    );

    logic [63:0] wb_write_data;
    logic [4:0]  rd_w;
    logic        regwrite_w;

    reg_file ID2(
        .rs1          (rs1),
        .rs2          (rs2),
        .writedata    (wb_write_data),
        .rd           (rd_w),
        .regwrite     (regwrite_w & valid_w),
        .clk          (clk),
        .reset        (reset),

        .rs1_val_d    (rs1_val_d),
        .rs2_val_d    (rs2_val_d),

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

    imm_gen ID3(
        .instr_d (instr_d),
        .imm_d   (imm_d)
    );

    // =========================================================
    // ID/EX
    // =========================================================
    logic [63:0] rs1_val_e;
    logic [63:0] rs2_val_e;
    logic [63:0] imm_e;
    logic [4:0]  rd_e;

    logic        alusign_e;
    logic [3:0]  aluctrl_e;
    logic [1:0]  alusrca_e;
    logic [1:0]   alusrcb_e;
    logic        mem_write_e;
    logic        mem_read_e;
    logic [1:0]   wbresult_e;
    logic [1:0]  mem_digit_e;
    logic        mem_sign_e;
    logic        regwrite_e;

    logic [2:0]  branch_type_e;
    logic        cmpsrc_e;
    logic [1:0]  is_baj_e;

    id_ex_reg id_ex(
        .csr_operand_d(csr_operand_d),
        .csr_operand_e(csr_operand_e),
        .clk           (clk),
        .rs1_val_d     (rs1_val_d),
        .rs2_val_d     (rs2_val_d),
        .imm_d         (imm_d),
        .rd_d          (rd),
        .alusign_d     (alusign_d),
        .aluctrl_d     (aluctrl_d),
        .alusrcb_d     (alusrcb_d),
        .alusrca_d     (alusrca_d),
        .mem_write_d   (mem_write_d),
        .mem_read_d    (mem_read_d),
        .wbresult_d    (wb_result_d),
        .mem_digit_d   (mem_digit_d),
        .mem_sign_d    (mem_sign_d),
        .regwrite_d    (regwrite_d),
        .pc_d          (pc_d),
        .instr_d       (instr_d),
        .valid_d       (valid_d),
        .reset         (reset),
        .flush         (id_ex_flush),
        .id_ex_stall   (id_ex_stall),
        .branch_type_d (branch_type_d),
        .cmpsrc_d      (cmpsrc_d),
        .is_baj_d      (is_baj_d),
        .csrwrite_d  (csrwrite_d),
        .csr_num_d  (csr_num_d),
        .csr_value_d(csr_value_d),

        .is_ecall_d (is_ecall_d),
        .is_mret_d  (is_mret_d),
        .is_ecall_e (is_ecall_e),
        .is_mret_e  (is_mret_e),

        .csr_num_e  (csr_num_e),
        .csr_value_e(csr_value_e),

        .csrwrite_e  (csrwrite_e),
        .wbresult_e    (wbresult_e),
        .valid_e       (valid_e),
        .instr_e       (instr_e),
        .pc_e          (pc_e),
        .rs1_val_e     (rs1_val_e),
        .rs2_val_e     (rs2_val_e),
        .imm_e         (imm_e),
        .rd_e          (rd_e),
        .alusign_e     (alusign_e),
        .aluctrl_e     (aluctrl_e),
        .branch_type_e (branch_type_e),
        .cmpsrc_e      (cmpsrc_e),
        .is_baj_e      (is_baj_e),
        .alusrca_e     (alusrca_e),
        .alusrcb_e     (alusrcb_e),
        .mem_write_e   (mem_write_e),
        .mem_read_e    (mem_read_e),
        .mem_sign_e    (mem_sign_e),
        .mem_digit_e   (mem_digit_e),
        .regwrite_e    (regwrite_e)
    );

    // =========================================================
    // 3. EX
    // =========================================================
    logic [63:0] srca_e;
    logic [63:0] srcb_e;
    logic [63:0] alu_result_e;
    logic [63:0] long_alu_result_e;
    logic [63:0] aluout_e;

    logic [63:0] rs1_eff_e;
    logic [63:0] rs2_eff_e;

    logic [63:0] cmp_b_e;
    logic        cmp_res;

always_comb begin
    rs1_eff_e = rs1_val_e;
    rs2_eff_e = rs2_val_e;

    // rs1
    if (valid_m && regwrite_m && (rd_m != 5'd0) && (rd_m == instr_e[19:15])) begin
        if (!mem_read_m) begin
            rs1_eff_e = aluout_m;
        end
        else if (dbus_resp.data_ok) begin
            rs1_eff_e = mem_read_data_m;
        end
    end
    else if (valid_w && regwrite_w && (rd_w != 5'd0) &&
             (rd_w == instr_e[19:15])) begin
        rs1_eff_e = wb_write_data;
    end

    // rs2
    if (valid_m && regwrite_m && (rd_m != 5'd0) && (rd_m == instr_e[24:20])) begin
        if (!mem_read_m) begin
            rs2_eff_e = aluout_m;
        end
        else if (dbus_resp.data_ok) begin
            rs2_eff_e = mem_read_data_m;
        end
    end
    else if (valid_w && regwrite_w && (rd_w != 5'd0) &&
             (rd_w == instr_e[24:20])) begin
        rs2_eff_e = wb_write_data;
    end
end

    srca_mux EX5(
        .rs1_val_e (rs1_eff_e),
        .alusrca_e (alusrca_e),
        .pc_e      (pc_e),
        .srca_e    (srca_e)
    );

    srcb_mux EX1(
        .imm_e      (imm_e),
        .rs2_val_e  (rs2_eff_e),
        .alusrcb_e  (alusrcb_e),
        .srcb_e     (srcb_e)
    );

    alu EX2(
        .srca_e       (srca_e),
        .srcb_e       (srcb_e),
        .aluctrl_e    (aluctrl_e),
        .alusign_e    (alusign_e),
        .alu_result_e (alu_result_e)
    );

    sign32to64 EX3(
        .short_imm (alu_result_e),
        .long_imm  (long_alu_result_e)
    );

    alures_mux EX4(
        .alusign_e          (alusign_e),
        .alu_result_e       (alu_result_e),
        .long_alu_result_e  (long_alu_result_e),
        .final_alu_result_e (aluout_e)
    );

    assign cmp_b_e = cmpsrc_e ? imm_e : rs2_eff_e;

    branch_cmp EXCMP(
        .a             (rs1_eff_e),
        .b             (cmp_b_e),
        .branch_type_e (branch_type_e),
        .cmp_res       (cmp_res)
    );

    redirect_valid_unit EXRV(
        .cmp_res        (cmp_res),
        .is_baj_e       (is_baj_e),
        .redirect_valid (redirect_valid)
    );

    redirect_pc_unit EXRP(
        .alu_res     (aluout_e),
        .is_baj_e    (is_baj_e),
        .redirect_pc (redirect_pc)
    );

    logic [63:0] final_redirect_pc;

    final_redirect_pc_unit frp(
        .branch_redirect_pc  (redirect_pc),
        .final_redirect_pc   (final_redirect_pc),
        .csr_mepc            (csr_mepc),
        .csr_mtvec           (csr_mtvec),
        .is_ecall            (is_ecall_w & valid_w),
        .is_mret             (is_mret_w & valid_w)
    );

    // =========================================================
    // EX/MEM
    // =========================================================
    logic [1:0]  wb_result_m;
    logic        mem_write_m;
    logic        mem_read_m;
    logic        mem_sign_m;
    logic [1:0]  mem_digit_m;
    logic [63:0] aluout_m;
    logic [4:0]  rd_m;
    logic        regwrite_m;
    logic [63:0] rs2_val_m;
    logic [1:0]  is_baj_m;

    ex_mem_reg ex_mem(
        .flush          (ex_mem_flush),
        .csr_operand_e(csr_operand_e),
        .csr_operand_m(csr_operand_m),
        .mem_write_e        (mem_write_e),
        .mem_read_e         (mem_read_e),
        .mem_sign_e         (mem_sign_e),
        .wb_result_e        (wbresult_e),
        .mem_digit_e        (mem_digit_e),
        .final_alu_result_e (aluout_e),
        .rd_e               (rd_e),
        .regwrite_e         (regwrite_e),
        .clk                (clk),
        .reset              (reset),
        .pc_e               (pc_e),
        .instr_e            (instr_e),
        .valid_e            (valid_e),
        .rs2_val_e          (rs2_eff_e),
        .ex_mem_stall       (ex_mem_stall),
        .is_baj_e           (is_baj_e),
        .csrwrite_e  (csrwrite_e),
        .csr_num_e  (csr_num_e),
        .csr_value_e(csr_value_e),
        .csr_num_m  (csr_num_m),
        .csr_value_m(csr_value_m),

        .is_ecall_m (is_ecall_m),
        .is_mret_m  (is_mret_m),
        .is_ecall_e (is_ecall_e),
        .is_mret_e  (is_mret_e),

        .csrwrite_m  (csrwrite_m),
        .wb_result_m        (wb_result_m),
        .valid_m            (valid_m),
        .pc_m               (pc_m),
        .instr_m            (instr_m),
        .mem_write_m        (mem_write_m),
        .mem_read_m         (mem_read_m),
        .mem_sign_m         (mem_sign_m),
        .mem_digit_m        (mem_digit_m),
        .final_alu_result_m (aluout_m),
        .rd_m               (rd_m),
        .regwrite_m         (regwrite_m),
        .rs2_val_m          (rs2_val_m),
        .is_baj_m           (is_baj_m)
    );

    // =========================================================
    // 4. MEM
    // =========================================================
    logic [63:0] mem_read_data_m;
    logic [63:0] mem_write_data_w;

    data_mem MEM1(
        .clk            (clk),
        .rst            (reset),
        .valid_m        (valid_m),
        .address        (aluout_m),
        .mem_write_data (rs2_val_m),
        .mem_write_m    (mem_write_m),
        .mem_read_m     (mem_read_m),
        .mem_digit_m    (mem_digit_m),
        .mem_sign_m     (mem_sign_m),

        .dresp          (real_dbus_resp),
        .dreq           (real_dbus_req),

        .mem_read_data  (mem_read_data_m),
        .mem_stall      (mem_stall)
    );
    // =========================================================
    // MEM/WB
    // =========================================================
    logic [1:0]  wb_result_w;
    logic [63:0] aluout_w;
    logic [1:0]  is_baj_w;

    mem_wb_reg mem_wb(
        .flush            (1'b0),//暂时写成0，防止把自己刷掉。
        .aluout_m         (aluout_m),
        .mem_write_data_m (mem_read_data_m),
        .rd_m             (rd_m),
        .wb_result_m      (wb_result_m),
        .regwrite_m       (regwrite_m),
        .clk              (clk),
        .reset            (reset),
        .pc_m             (pc_m),
        .instr_m          (instr_m),
        .valid_m          (valid_m),
        .mem_wb_stall     (mem_wb_stall),
        .is_baj_m         (is_baj_m),
        .csrwrite_m  (csrwrite_m),
        .csrwrite_w  (csrwrite_w),

        .is_ecall_m (is_ecall_m),
        .is_mret_m  (is_mret_m),
        .is_ecall_w (is_ecall_w),
        .is_mret_w (is_mret_w),

        .csr_num_m  (csr_num_m),
        .csr_value_m (csr_value_m),
        .csr_num_w  (csr_num_w),
        .csr_value_w(csr_value_w),
        .is_baj_w         (is_baj_w),
        .mem_write_data_w (mem_write_data_w),
        .wb_result_w      (wb_result_w),
        .pc_w             (pc_w),
        .instr_w          (instr_w),
        .aluout_w         (aluout_w),
        .rd_w             (rd_w),
        .regwrite_w       (regwrite_w),
        .valid_w          (valid_w)
    );

    // =========================================================
    // 5. WB
    // =========================================================
    wbres_mux WB1(
        .wb_result_w      (wb_result_w),
        .is_baj_w         (is_baj_w),
        .aluout_w         (aluout_w),
        .mem_write_data_w (mem_write_data_w),
        .pc_w             (pc_w),
        .wb_write_data    (wb_write_data),
        .csr_value_w      (csr_value_w)
    );

    // =========================================================
    // commit for test
    // =========================================================
    
    logic        mem_inst_w;
    logic        commit_mem_valid;
    logic [63:0] commit_mem_addr;

    assign mem_inst_w =
    (instr_w[6:0] == 7'b0000011) ||   // LOAD
    (instr_w[6:0] == 7'b0100011);     // STORE
    
    logic        commit_valid;
    logic [63:0] commit_pc;
    logic [31:0] commit_instr;
    logic        commit_wen;
    logic [4:0]  commit_wdest;
    logic [63:0] commit_wdata;

        assign valid = commit_valid;

    always_ff @(posedge clk) begin
        if (reset) begin
            commit_valid <= 1'b0;
            commit_pc    <= 64'b0;
            commit_instr <= 32'b0;
            commit_wen   <= 1'b0;
            commit_wdest <= 5'b0;
            commit_wdata <= 64'b0;
            commit_mem_valid <= 1'b0;
            commit_mem_addr  <= 64'b0;
        end
        else begin
            commit_valid <= valid_w;

            if (valid_w) begin
                commit_pc    <= pc_w;
                commit_instr <= instr_w;
                commit_wen   <= regwrite_w;
                commit_wdest <= rd_w;
                commit_wdata <= wb_write_data;
                commit_mem_valid <= mem_inst_w;
                commit_mem_addr  <= aluout_w;
            end
            else begin
                commit_pc    <= 64'b0;
                commit_instr <= 32'b0;
                commit_wen   <= 1'b0;
                commit_wdest <= 5'b0;
                commit_wdata <= 64'b0;
                commit_mem_valid <= 1'b0;
                commit_mem_addr  <= 64'b0;
            end
        end
    end

    assign mem = commit_mem_valid & commit_valid;
    assign memaddr  = commit_mem_addr;

    assign test_pc    = commit_pc;
    assign test_instr = commit_instr;
    assign test_wen   = commit_wen & commit_valid;
    assign test_wdest = commit_wdest;
    assign test_wdata = commit_wdata;

endmodule
