//模块名称：ex_mem_reg
//接口：input logic mem_write_e
//     input logic mem_read_e
//     input logic mem_sign_e
//     input logic wb_result_e
//     input logic [1:0]mem_digit_e
//     input logic [63:0] final_alu_result_e
//     input logic [4:0] rd_e
//     input logic regwrite_e
//     input logic clk
//     input logic reset
//     input logic [63:0] pc_e 
//     input logic [31:0] instr_e 
//     input logic valid_e
//     input logic [63:0] rs2_val_e
//     input logic ex_mem_stall
//     output logic wb_result_m
//     output logic valid_m
//     output logic [63:0] pc_m
//     output logic [31:0] instr_m
//     output logic mem_write_m
//     output logic mem_read_m
//     output logic mem_sign_m
//     output logic [1:0] mem_digit_m
//     output logic [63:0] final_alu_result_m
//     output logic [4:0] rd_m
//     output logic regwrite_m
//     output logic [63:0] rs2_val_m
//功能：流水寄存器，reset清零。每一拍,当stall为0时，将输入的“e”类量写入对应的“m”类量

module ex_mem_reg (
    input  logic        mem_write_e,
    input  logic        mem_read_e,
    input  logic        mem_sign_e,
    input  logic        wb_result_e,
    input  logic [1:0]  mem_digit_e,
    input  logic [63:0] final_alu_result_e,
    input  logic [4:0]  rd_e,
    input  logic        regwrite_e,
    input  logic        clk,
    input  logic        reset,
    input  logic [63:0] pc_e,
    input  logic [31:0] instr_e,
    input  logic        valid_e,
    input  logic [63:0] rs2_val_e,
    input  logic        ex_mem_stall,

    output logic        wb_result_m,
    output logic        valid_m,
    output logic [63:0] pc_m,
    output logic [31:0] instr_m,
    output logic        mem_write_m,
    output logic        mem_read_m,
    output logic        mem_sign_m,
    output logic [1:0]  mem_digit_m,
    output logic [63:0] final_alu_result_m,
    output logic [4:0]  rd_m,
    output logic        regwrite_m,
    output logic [63:0] rs2_val_m
);

    always_ff @(posedge clk) begin
        if (reset) begin
            wb_result_m        <= 1'b0;
            valid_m            <= 1'b0;
            pc_m               <= 64'b0;
            instr_m            <= 32'b0;
            mem_write_m        <= 1'b0;
            mem_read_m         <= 1'b0;
            mem_sign_m         <= 1'b0;
            mem_digit_m        <= 2'b0;
            final_alu_result_m <= 64'b0;
            rd_m               <= 5'b0;
            regwrite_m         <= 1'b0;
            rs2_val_m          <= 64'b0;
        end
        else if (!ex_mem_stall) begin
            wb_result_m        <= wb_result_e;
            valid_m            <= valid_e;
            pc_m               <= pc_e;
            instr_m            <= instr_e;
            mem_write_m        <= mem_write_e;
            mem_read_m         <= mem_read_e;
            mem_sign_m         <= mem_sign_e;
            mem_digit_m        <= mem_digit_e;
            final_alu_result_m <= final_alu_result_e;
            rd_m               <= rd_e;
            regwrite_m         <= regwrite_e;
            rs2_val_m          <= rs2_val_e;
        end
    end

endmodule
