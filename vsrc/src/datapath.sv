`include "include/common.sv"
`include "src/alu_adder.sv"
`include "src/alu.sv"
`include "src/alures_mux.sv"
`include "src/control_unit.sv"
`include "src/ex_mem_reg.sv"
`include "src/id_ex_reg.sv"
`include "src/if_id_reg.sv"
`include "src/instr_mem.sv"
`include "src/mem_wb_reg.sv"
`include "src/pc_reg.sv"
`include "src/reg_file.sv"
`include "src/sign12to64.sv"
`include "src/sign32to64.sv"
`include "src/srcb_mux.sv"
`include "src/srca_mux.sv"
`include "src/stall_unit.sv"
`include "src/data_mem.sv"
`include "src/imm_gen.sv"
`include "src/wbres_mux.sv"

module datapath import common::*;(
    input  logic       clk,
    input  logic       reset,
    input  logic [63:0] PCINIT,

    input  ibus_resp_t ibus_resp,
    output ibus_req_t  ibus_req,

    input  dbus_resp_t dbus_resp,
    output dbus_req_t  dbus_req,

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
    output logic [63:0] test_reg_x31
);

    // =========================
    // stall
    // =========================
    logic pc_stall;
    logic if_id_stall;
    logic id_ex_stall;
    logic ex_mem_stall;
    logic mem_wb_stall;
    logic mem_stall;

    stall_unit st(
        .mem_stall    (mem_stall),
        .pc_stall     (pc_stall),
        .if_id_stall  (if_id_stall),
        .id_ex_stall  (id_ex_stall),
        .ex_mem_stall (ex_mem_stall),
        .mem_wb_stall (mem_wb_stall)
    );

    // =========================
    // 1. IF
    // =========================
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

    // 只有 IF/ID 能接收时，已经取回的指令才算被消费
    assign fetch_consume = fetch_ok & ~if_id_stall;

    instr_mem if3(
        .clk      (clk),
        .reset    (reset),
        .consume  (fetch_consume),
        .pc_stall (pc_stall),
        .ibus_resp(ibus_resp),
        .pcinit   (PCINIT),

        .fetch_ok (fetch_ok),
        .instr    (instr_f),
        .ibus_req (ibus_req),
        .instr_pc (pc_f)
    );

    // =========================
    // IF/ID
    // =========================
    if_id_reg if_id(
        .instr_f     (instr_f),
        .clk         (clk),
        .fetch_ok    (fetch_ok),
        .pc_f        (pc_f),
        .reset       (reset),
        .if_id_stall (if_id_stall),
        .instr_d     (instr_d),
        .valid_d     (valid_d),
        .pc_d        (pc_d)
    );

    // =========================
    // 2. ID
    // =========================
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [6:0]  opcode;

    logic [63:0] imm_d;
    logic [63:0] rs1_val_d;
    logic [63:0] rs2_val_d;

    logic        alusign_d;
    logic [2:0]  aluctrl_d;
    logic        alusrca_d;
    logic        alusrcb_d;
    logic        regwrite_d;
    logic        mem_write_d;
    logic        mem_read_d;
    logic        mem_sign_d;
    logic        wb_result_d;
    logic [1:0]  mem_digit_d;

    assign opcode = instr_d[6:0];
    assign rd     = instr_d[11:7];
    assign funct3 = instr_d[14:12];
    assign rs1    = instr_d[19:15];
    assign rs2    = instr_d[24:20];
    assign funct7 = instr_d[31:25];

    control_unit ID1(
        .funct3      (funct3),
        .funct7      (funct7),
        .opcode      (opcode),
        .alusign_d   (alusign_d),
        .aluctrl_d   (aluctrl_d),
        .alusrcb_d   (alusrcb_d),
        .regwrite_d  (regwrite_d),
        .mem_write_d (mem_write_d),
        .mem_read_d  (mem_read_d),
        .mem_sign_d  (mem_sign_d),
        .wb_result_d (wb_result_d),
        .mem_digit_d (mem_digit_d),
        .alusrca_d   (alusrca_d)
    );

    logic [63:0] wb_write_data;
    logic [4:0]  rd_w;
    logic        regwrite_w;

    reg_file ID2(
        .rs1         (rs1),
        .rs2         (rs2),
        .writedata   (wb_write_data),
        .rd          (rd_w),
        .regwrite    (regwrite_w & valid_w),
        .clk         (clk),
        .reset       (reset),

        .rs1_val_d   (rs1_val_d),
        .rs2_val_d   (rs2_val_d),

        .test_reg_x0 (test_reg_x0),
        .test_reg_x1 (test_reg_x1),
        .test_reg_x2 (test_reg_x2),
        .test_reg_x3 (test_reg_x3),
        .test_reg_x4 (test_reg_x4),
        .test_reg_x5 (test_reg_x5),
        .test_reg_x6 (test_reg_x6),
        .test_reg_x7 (test_reg_x7),
        .test_reg_x8 (test_reg_x8),
        .test_reg_x9 (test_reg_x9),
        .test_reg_x10(test_reg_x10),
        .test_reg_x11(test_reg_x11),
        .test_reg_x12(test_reg_x12),
        .test_reg_x13(test_reg_x13),
        .test_reg_x14(test_reg_x14),
        .test_reg_x15(test_reg_x15),
        .test_reg_x16(test_reg_x16),
        .test_reg_x17(test_reg_x17),
        .test_reg_x18(test_reg_x18),
        .test_reg_x19(test_reg_x19),
        .test_reg_x20(test_reg_x20),
        .test_reg_x21(test_reg_x21),
        .test_reg_x22(test_reg_x22),
        .test_reg_x23(test_reg_x23),
        .test_reg_x24(test_reg_x24),
        .test_reg_x25(test_reg_x25),
        .test_reg_x26(test_reg_x26),
        .test_reg_x27(test_reg_x27),
        .test_reg_x28(test_reg_x28),
        .test_reg_x29(test_reg_x29),
        .test_reg_x30(test_reg_x30),
        .test_reg_x31(test_reg_x31)
    );

    imm_gen ID3(
        .instr_d (instr_d),
        .imm_d   (imm_d)
    );

    // =========================
    // ID/EX
    // =========================
    logic [63:0] rs1_val_e;
    logic [63:0] rs2_val_e;
    logic [63:0] imm_e;
    logic [4:0]  rd_e;

    logic        alusign_e;
    logic [2:0]  aluctrl_e;
    logic        alusrca_e;
    logic        alusrcb_e;
    logic        mem_write_e;
    logic        mem_read_e;
    logic        wbresult_e;
    logic [1:0]  mem_digit_e;
    logic        mem_sign_e;
    logic        regwrite_e;

    id_ex_reg id_ex(
        .clk         (clk),
        .rs1_val_d   (rs1_val_d),
        .rs2_val_d   (rs2_val_d),
        .imm_d       (imm_d),
        .rd_d        (rd),
        .alusign_d   (alusign_d),
        .aluctrl_d   (aluctrl_d),
        .alusrcb_d   (alusrcb_d),
        .alusrca_d   (alusrca_d),
        .mem_write_d (mem_write_d),
        .mem_read_d  (mem_read_d),
        .wbresult_d  (wb_result_d),
        .mem_digit_d (mem_digit_d),
        .mem_sign_d  (mem_sign_d),
        .regwrite_d  (regwrite_d),
        .pc_d        (pc_d),
        .instr_d     (instr_d),
        .valid_d     (valid_d),
        .reset       (reset),
        .id_ex_stall (id_ex_stall),

        .wbresult_e  (wbresult_e),
        .valid_e     (valid_e),
        .instr_e     (instr_e),
        .pc_e        (pc_e),
        .rs1_val_e   (rs1_val_e),
        .rs2_val_e   (rs2_val_e),
        .imm_e       (imm_e),
        .rd_e        (rd_e),
        .alusign_e   (alusign_e),
        .aluctrl_e   (aluctrl_e),
        .alusrca_e   (alusrca_e),
        .alusrcb_e   (alusrcb_e),
        .mem_write_e (mem_write_e),
        .mem_read_e  (mem_read_e),
        .mem_sign_e  (mem_sign_e),
        .mem_digit_e (mem_digit_e),
        .regwrite_e  (regwrite_e)
    );

    // =========================
    // 3. EX
    // =========================
    logic [63:0] srca_e;
    logic [63:0] srcb_e;
    logic [63:0] alu_result_e;
    logic [63:0] long_alu_result_e;
    logic [63:0] aluout_e;

    srca_mux EX5(
        .rs1_val_e (rs1_val_e),
        .alusrca_e (alusrca_e),
        .srca_e    (srca_e)
    );

    srcb_mux EX1(
        .imm_e     (imm_e),
        .rs2_val_e (rs2_val_e),
        .alusrcb_e  (alusrcb_e),
        .srcb_e    (srcb_e)
    );

    alu EX2(
        .srca_e       (srca_e),
        .srcb_e       (srcb_e),
        .aluctrl_e    (aluctrl_e),
        .alu_result_e (alu_result_e)
    );

    sign32to64 EX3(
        .short_imm (alu_result_e),
        .long_imm  (long_alu_result_e)
    );

    alures_mux EX4(
        .alusign_e         (alusign_e),
        .alu_result_e      (alu_result_e),
        .long_alu_result_e (long_alu_result_e),
        .final_alu_result_e(aluout_e)
    );

    // =========================
    // EX/MEM
    // =========================
    logic        wb_result_m;
    logic        mem_write_m;
    logic        mem_read_m;
    logic        mem_sign_m;
    logic [1:0]  mem_digit_m;
    logic [63:0] aluout_m;
    logic [4:0]  rd_m;
    logic        regwrite_m;
    logic [63:0] rs2_val_m;

    ex_mem_reg ex_mem(
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
        .rs2_val_e          (rs2_val_e),
        .ex_mem_stall       (ex_mem_stall),

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
        .rs2_val_m          (rs2_val_m)
    );

    // =========================
    // 4. MEM
    // =========================
    logic [63:0] mem_read_data_m;
    logic [63:0] mem_write_data_w;

    data_mem MEM1(
        .address       (aluout_m),
        .mem_write_data(rs2_val_m),
        .mem_write_m   (mem_write_m),
        .mem_read_m    (mem_read_m),
        .mem_digit_m   (mem_digit_m),
        .mem_sign_m    (mem_sign_m),

        .dresp         (dbus_resp),
        .dreq          (dbus_req),

        .mem_read_data (mem_read_data_m),
        .mem_stall     (mem_stall)
    );

    // =========================
    // MEM/WB
    // =========================
    logic        wb_result_w;
    logic [63:0] aluout_w;
    mem_wb_reg mem_wb(
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

        .mem_write_data_w (mem_write_data_w),
        .wb_result_w      (wb_result_w),
        .pc_w             (pc_w),
        .instr_w          (instr_w),
        .aluout_w         (aluout_w),
        .rd_w             (rd_w),
        .regwrite_w       (regwrite_w),
        .valid_w          (valid_w)
    );

    // =========================
    // 5. WB
    // =========================
    wbres_mux WB1(
        .wb_result_w      (wb_result_w),
        .aluout_w        (aluout_w),
        .mem_write_data_w(mem_write_data_w),
        .wb_write_data   (wb_write_data)
    );

    assign valid = commit_valid;
    logic valid_w_prev;
    // =========================
    // commit for test
    // =========================
    logic        commit_valid;
    logic [63:0] commit_pc;
    logic [31:0] commit_instr;
    logic        commit_wen;
    logic [4:0]  commit_wdest;
    logic [63:0] commit_wdata;

    always_ff @(posedge clk) begin
        if (reset) begin
            valid_w_prev <= 1'b0;
            commit_valid <= 1'b0;
            commit_pc    <= 64'b0;
            commit_instr <= 32'b0;
            commit_wen   <= 1'b0;
            commit_wdest <= 5'b0;
            commit_wdata <= 64'b0;
        end else begin
            valid_w_prev <= valid_w;

            // 只在 valid_w 从 0 变成 1 时提交一次
            commit_valid <= valid_w & ~valid_w_prev;

            if (valid_w & ~valid_w_prev) begin
                commit_pc    <= pc_w;
                commit_instr <= instr_w;
                commit_wen   <= regwrite_w;
                commit_wdest <= rd_w;
                commit_wdata <= wb_write_data;
            end
        end
    end

    assign test_pc    = commit_pc;
    assign test_instr = commit_instr;
    assign test_wen   = commit_wen & commit_valid;
    assign test_wdest = commit_wdest;
    assign test_wdata = commit_wdata;

endmodule
