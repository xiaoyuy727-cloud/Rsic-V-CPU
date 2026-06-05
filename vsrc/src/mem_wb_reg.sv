//模块名称：mem_wb_reg
//接口：input logic [63:0] aluout_m
//     input logic [63:0] mem_write_data_m
//     input logic [4:0] rd_m
//     input logic [1:0]wb_result_m
//     input logic regwrite_m
//     input logic clk
//     input logic reset
//     input logic flush
//     input logic is_ecall_d
//     input logic is_mret_d
//     output logic is_mret_e
//     output logic is_ecall_e
//     input logic [63:0] pc_m
//     input logic [31:0] instr_m
//     input logic valid_m
//     input logic mem_wb_stall
//     input logic is_baj_m
//     input logic csrwrite_m

//     output logic csrwrite_w
//     output logic is_baj_w
//     output logic [63:0] mem_write_data_w
//     output logic [1:0]wb_result_w
//     output logic [63:0] pc_w
//     output logic [31:0] instr_w
//     output logic [63:0] aluout_w
//     output logic [4:0] rd_w
//     output logic regwrite_w
//     output logic valid_w

//      input logic iaddr_exc_m
//      output logic iaddr_exc_w
//      input logic redirect_valid_m
//      output logic redirect_valid_w
//      input logic [63:0]redirect_pc_m
//      output logic [63:0]redirect_pc_w
//    input logic     daddr_exc_m
//    output logic    daddr_exc_w
//功能：流水寄存器，reset清零。每一拍，当stall为0，将输入的“m”类量写入对应的“w”类量.

module mem_wb_reg (
    input  logic        flush,
    input  logic [63:0] aluout_m,
    input  logic [63:0] mem_write_data_m,
    input  logic [4:0]  rd_m,
    input  logic  [1:0]  wb_result_m,
    input  logic        regwrite_m,
    input  logic        clk,
    input  logic        reset,
    input  logic [63:0] pc_m,
    input  logic [31:0] instr_m,
    input  logic        valid_m,
    input  logic        mem_wb_stall,
    input  logic [1:0]  is_baj_m,
    input  logic        csrwrite_m,
    input logic [11:0]      csr_num_m,
    input logic [63:0]      csr_value_m,

    input logic is_ecall_m,
    input logic is_mret_m,
    output logic is_mret_w,
    output logic is_ecall_w,

    output logic [11:0]      csr_num_w,
    output logic [63:0]      csr_value_w,

    output logic        csrwrite_w,
    output logic [1:0]  is_baj_w,
    output logic [63:0] mem_write_data_w,
    output logic  [1:0] wb_result_w,
    output logic [63:0] pc_w,
    output logic [31:0] instr_w,
    output logic [63:0] aluout_w,
    output logic [4:0]  rd_w,
    output logic        regwrite_w,
    output logic        valid_w,
    input logic iaddr_exc_m,
    output logic iaddr_exc_w,
    input logic redirect_valid_m,
    output logic redirect_valid_w,
    input logic [63:0]redirect_pc_m,
    output logic [63:0]redirect_pc_w,

    input logic     daddr_exc_m,
    output logic    daddr_exc_w
);

    always_ff @(posedge clk) begin
        if (reset | flush) begin
            csr_num_w     <= 12'b0;
            csr_value_w   <= 64'b0;
            mem_write_data_w <= 64'b0;
            wb_result_w      <= 2'b0;
            pc_w             <= 64'b0;
            instr_w          <= 32'b0;
            aluout_w         <= 64'b0;
            rd_w             <= 5'b0;
            regwrite_w       <= 1'b0;
            valid_w          <= 1'b0;
            is_baj_w         <=2'b0;
            csrwrite_w       <=1'b0;
            is_ecall_w       <= 1'b0;
            is_mret_w        <= 1'b0;
            iaddr_exc_w      <= 1'b0;
            redirect_pc_w    <= 64'd0;
            redirect_valid_w <= 1'b0;
            daddr_exc_w      <= 1'b0;
        end
        else if (!mem_wb_stall) begin
            csr_num_w     <= csr_num_m;
            csr_value_w   <= csr_value_m;
            mem_write_data_w <= mem_write_data_m;
            wb_result_w      <= wb_result_m;
            pc_w             <= pc_m;
            instr_w          <= instr_m;
            aluout_w         <= aluout_m;
            rd_w             <= rd_m;
            regwrite_w       <= regwrite_m;
            valid_w          <= valid_m;
            is_baj_w         <= is_baj_m;
            csrwrite_w       <= csrwrite_m;
            is_ecall_w       <= is_ecall_m;
            is_mret_w        <= is_mret_m;
            iaddr_exc_w      <= iaddr_exc_m;
            redirect_pc_w    <= redirect_pc_m;
            redirect_valid_w <= redirect_valid_m;
            daddr_exc_w      <= daddr_exc_m;
        end
    end

endmodule
