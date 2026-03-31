//模块名称：id_ex_reg
//接口：input logic clk
//     input logic [63:0] rs1_val_d
//     input logic [63:0] rs2_val_d
//     input logic [63:0] imm_d
//     input logic [4:0] rd_d
//     input logic alusign_d
//     input logic [2:0] aluctrl_d
//     input logic alusrcb_d
//     input logic alusrca_d
//     input logic mem_write_d
//     input logic mem_read_d
//     input logic wbresult_d
//     input logic [1:0]mem_digit_d
//     input logic mem_sign_d
//     input logic regwrite_d
//     input logic [63:0] pc_d
//     input logic [31:0] instr_d
//     input logic valid_d
//     input logic reset
//     input logic clk
//     input logic id_ex_stall
//     output logic wbresult_e
//     output logic valid_e
//     output logic [31:0] instr_e
//     output logic [63:0] pc_e
//     output logic [63:0] rs1_val_e
//     output logic [63:0] rs2_val_e
//     output logic [63:0] imm_e
//     output logic [4:0] rd_e
//     output logic alusign_e
//     output logic [2:0] aluctrl_e
//     output logic alusrca_e
//     output logic alusrcb_e
//     output logic mem_write_e
//     output logic mem_read_e
//     output logic mem_sign_e
//     output logic [1:0] mem_digit_e
//     output logic regwrite_e
//功能：流水寄存器，
//     reset时全部归零。
//     每一拍,如果stall为0，将输入的“d”类量写入对应的“e”类量

module id_ex_reg (
    input  logic        clk,
    input  logic [63:0] rs1_val_d,
    input  logic [63:0] rs2_val_d,
    input  logic [63:0] imm_d,
    input  logic [4:0]  rd_d,
    input  logic        alusign_d,
    input  logic [2:0]  aluctrl_d,
    input  logic        alusrcb_d,
    input  logic        alusrca_d,
    input  logic        mem_write_d,
    input  logic        mem_read_d,
    input  logic        wbresult_d,
    input  logic [1:0]  mem_digit_d,
    input  logic        mem_sign_d,
    input  logic        regwrite_d,
    input  logic [63:0] pc_d,
    input  logic [31:0] instr_d,
    input  logic        valid_d,
    input  logic        reset,
    input  logic        id_ex_stall,

    output logic        wbresult_e,
    output logic        valid_e,
    output logic [31:0] instr_e,
    output logic [63:0] pc_e,
    output logic [63:0] rs1_val_e,
    output logic [63:0] rs2_val_e,
    output logic [63:0] imm_e,
    output logic [4:0]  rd_e,
    output logic        alusign_e,
    output logic [2:0]  aluctrl_e,
    output logic        alusrca_e,
    output logic        alusrcb_e,
    output logic        mem_write_e,
    output logic        mem_read_e,
    output logic        mem_sign_e,
    output logic [1:0]  mem_digit_e,
    output logic        regwrite_e
);

    always_ff @(posedge clk) begin
        if (reset) begin
            wbresult_e  <= 1'b0;
            valid_e     <= 1'b0;
            instr_e     <= 32'b0;
            pc_e        <= 64'b0;
            rs1_val_e   <= 64'b0;
            rs2_val_e   <= 64'b0;
            imm_e       <= 64'b0;
            rd_e        <= 5'b0;
            alusign_e   <= 1'b0;
            aluctrl_e   <= 3'b0;
            alusrca_e   <= 1'b0;
            alusrcb_e   <= 1'b0;
            mem_write_e <= 1'b0;
            mem_read_e  <= 1'b0;
            mem_sign_e  <= 1'b0;
            mem_digit_e <= 2'b0;
            regwrite_e  <= 1'b0;
        end
        else if (!id_ex_stall) begin
            wbresult_e  <= wbresult_d;
            valid_e     <= valid_d;
            instr_e     <= instr_d;
            pc_e        <= pc_d;
            rs1_val_e   <= rs1_val_d;
            rs2_val_e   <= rs2_val_d;
            imm_e       <= imm_d;
            rd_e        <= rd_d;
            alusign_e   <= alusign_d;
            aluctrl_e   <= aluctrl_d;
            alusrca_e   <= alusrca_d;
            alusrcb_e   <= alusrcb_d;
            mem_write_e <= mem_write_d;
            mem_read_e  <= mem_read_d;
            mem_sign_e  <= mem_sign_d;
            mem_digit_e <= mem_digit_d;
            regwrite_e  <= regwrite_d;
        end
    end

endmodule
