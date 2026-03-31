//模块名称：mem_wb_reg
//接口：input logic [63:0] aluout_m
//     input logic [63:0] mem_write_data_m
//     input logic [4:0] rd_m
//     input logic wb_result_m
//     input logic regwrite_m
//     input logic clk
//     input logic reset
//     input logic [63:0] pc_m
//     input logic [31:0] instr_m
//     input logic valid_m
//     input logic mem_wb_stall

//     output logic [63:0] mem_write_data_w
//     output logic wb_result_w
//     output logic [63:0] pc_w
//     output logic [31:0] instr_w
//     output logic [63:0] aluout_w
//     output logic [4:0] rd_w
//     output logic regwrite_w
//     output logic valid_w
//功能：流水寄存器，reset清零。每一拍，当stall为0，将输入的“m”类量写入对应的“w”类量.

module mem_wb_reg (
    input  logic [63:0] aluout_m,
    input  logic [63:0] mem_write_data_m,
    input  logic [4:0]  rd_m,
    input  logic        wb_result_m,
    input  logic        regwrite_m,
    input  logic        clk,
    input  logic        reset,
    input  logic [63:0] pc_m,
    input  logic [31:0] instr_m,
    input  logic        valid_m,
    input  logic        mem_wb_stall,

    output logic [63:0] mem_write_data_w,
    output logic        wb_result_w,
    output logic [63:0] pc_w,
    output logic [31:0] instr_w,
    output logic [63:0] aluout_w,
    output logic [4:0]  rd_w,
    output logic        regwrite_w,
    output logic        valid_w
);

    always_ff @(posedge clk) begin
        if (reset) begin
            mem_write_data_w <= 64'b0;
            wb_result_w      <= 1'b0;
            pc_w             <= 64'b0;
            instr_w          <= 32'b0;
            aluout_w         <= 64'b0;
            rd_w             <= 5'b0;
            regwrite_w       <= 1'b0;
            valid_w          <= 1'b0;
        end
        else if (!mem_wb_stall) begin
            mem_write_data_w <= mem_write_data_m;
            wb_result_w      <= wb_result_m;
            pc_w             <= pc_m;
            instr_w          <= instr_m;
            aluout_w         <= aluout_m;
            rd_w             <= rd_m;
            regwrite_w       <= regwrite_m;
            valid_w          <= valid_m;
        end
    end

endmodule
