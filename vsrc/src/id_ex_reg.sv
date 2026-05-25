//模块名称：id_ex_reg
//接口：
//     input logic [63:0] rs1_val_d
//     input logic [63:0] rs2_val_d
//     input logic [63:0] imm_d
//     input logic [4:0] rd_d
//     input logic alusign_d
//     input logic [3:0] aluctrl_d
//     input logic [1:0]alusrcb_d
//     input logic [1:0]alusrca_d
//     input logic mem_write_d
//     input logic mem_read_d
//     input logic [1:0]wbresult_d
//     input logic [1:0]mem_digit_d
//     input logic mem_sign_d
//     input logic regwrite_d
//     input logic [63:0] pc_d
//     input logic [31:0] instr_d
//     input logic valid_d
//     input logic reset
//     input logic clk
//     input logic flush
//     input logic id_ex_stall
//     input logic [2:0]branch_type_d
//     input logic cmpsrc_d
//     input logic is_baj_d
//     input logic is_ecall_d
//     input logic is_mret_d
//     output logic is_mret_e
//     output logic is_ecall_e
//     output logic [1:0]wbresult_e
//     output logic valid_e
//     output logic [31:0] instr_e
//     output logic [63:0] pc_e
//     output logic [63:0] rs1_val_e
//     output logic [63:0] rs2_val_e
//     output logic [63:0] imm_e
//     output logic [4:0] rd_e
//     output logic alusign_e
//     output logic [3:0] aluctrl_e
//     output logic [2:0]branch_type_e
//     output logic cmpsrc_e
//     output logic is_baj_e
//     output logic [1:0]alusrca_e
//     output logic [1:0]alusrcb_e
//     output logic mem_write_e
//     output logic mem_read_e
//     output logic mem_sign_e
//     output logic [1:0] mem_digit_e
//     output logic regwrite_e
//     input logic csrwrite_d
//     output logic csrwrite_e
//功能：流水寄存器，
//     reset时全部归零。
//     flush时全部归零。
//     每一拍,如果stall为0，将输入的“d”类量写入对应的“e”类量

module id_ex_reg (
    input  logic [63:0] rs1_val_d,
    input  logic [63:0] rs2_val_d,
    input  logic [63:0] imm_d,
    input  logic [4:0]  rd_d,
    input  logic        alusign_d,
    input  logic [3:0]  aluctrl_d,
    input  logic [1:0]  alusrcb_d,
    input  logic [1:0]  alusrca_d,
    input  logic        mem_write_d,
    input  logic        mem_read_d,
    input  logic [1:0]  wbresult_d,
    input  logic [1:0]  mem_digit_d,
    input  logic        mem_sign_d,
    input  logic        regwrite_d,
    input  logic [63:0] pc_d,
    input  logic [31:0] instr_d,
    input  logic        valid_d,
    input  logic        reset,
    input  logic        clk,
    input  logic        flush,
    input  logic        id_ex_stall,
    input  logic [2:0]  branch_type_d,
    input  logic        cmpsrc_d,
    input  logic [1:0]  is_baj_d,
    input  logic        csrwrite_d,
    input logic [11:0]      csr_num_d,
    input logic [63:0]      csr_value_d,
    input  logic [63:0] csr_operand_d,
    output logic [63:0] csr_operand_e,

    input logic is_ecall_d,
    input logic is_mret_d,
    output logic is_mret_e,
    output logic is_ecall_e,

    output logic [11:0]      csr_num_e,
    output logic [63:0]      csr_value_e,
    output  logic        csrwrite_e,
    output logic  [1:0] wbresult_e,
    output logic        valid_e,
    output logic [31:0] instr_e,
    output logic [63:0] pc_e,
    output logic [63:0] rs1_val_e,
    output logic [63:0] rs2_val_e,
    output logic [63:0] imm_e,
    output logic [4:0]  rd_e,
    output logic        alusign_e,
    output logic [3:0]  aluctrl_e,
    output logic [2:0]  branch_type_e,
    output logic        cmpsrc_e,
    output logic [1:0]  is_baj_e,
    output logic [1:0]  alusrca_e,
    output logic [1:0]  alusrcb_e,
    output logic        mem_write_e,
    output logic        mem_read_e,
    output logic        mem_sign_e,
    output logic [1:0]  mem_digit_e,
    output logic        regwrite_e
);

always_ff @(posedge clk) begin
    if (reset) begin
        csr_operand_e <= 64'b0;
        csr_num_e     <= 12'b0;
        csr_value_e   <= 64'b0;
        wbresult_e    <= 2'b0;
        valid_e       <= 1'b0;
        instr_e       <= 32'b0;
        pc_e          <= 64'b0;
        rs1_val_e     <= 64'b0;
        rs2_val_e     <= 64'b0;
        imm_e         <= 64'b0;
        rd_e          <= 5'b0;
        alusign_e     <= 1'b0;
        aluctrl_e     <= 4'b0;
        branch_type_e <= 3'b0;
        cmpsrc_e      <= 1'b0;
        is_baj_e      <= 2'b0;
        alusrca_e     <= 2'b0;
        alusrcb_e     <= 2'b0;
        mem_write_e   <= 1'b0;
        mem_read_e    <= 1'b0;
        mem_sign_e    <= 1'b0;
        mem_digit_e   <= 2'b0;
        regwrite_e    <= 1'b0;
        csrwrite_e    <= 1'b0;
        is_ecall_e    <= 1'b0;
        is_mret_e    <= 1'b0;
    end
    else if (flush) begin
        csr_operand_e <= 64'b0;
        csr_num_e     <= 12'b0;
        csr_value_e   <= 64'b0;
        wbresult_e    <= 2'b0;
        valid_e       <= 1'b0;
        instr_e       <= 32'b0;
        pc_e          <= 64'b0;
        rs1_val_e     <= 64'b0;
        rs2_val_e     <= 64'b0;
        imm_e         <= 64'b0;
        rd_e          <= 5'b0;
        alusign_e     <= 1'b0;
        aluctrl_e     <= 4'b0;
        branch_type_e <= 3'b0;
        cmpsrc_e      <= 1'b0;
        is_baj_e      <= 2'b0;
        alusrca_e     <= 2'b0;
        alusrcb_e     <= 2'b0;
        mem_write_e   <= 1'b0;
        mem_read_e    <= 1'b0;
        mem_sign_e    <= 1'b0;
        mem_digit_e   <= 2'b0;
        regwrite_e    <= 1'b0;
        csrwrite_e    <= 1'b0;
        is_ecall_e    <= 1'b0;
        is_mret_e    <= 1'b0;
    end
    else if (!id_ex_stall) begin
        csr_operand_e <= csr_operand_d;
        csr_num_e     <= csr_num_d ;
        csr_value_e   <= csr_value_d;
        wbresult_e    <= wbresult_d;
        valid_e       <= valid_d;
        instr_e       <= instr_d;
        pc_e          <= pc_d;
        rs1_val_e     <= rs1_val_d;
        rs2_val_e     <= rs2_val_d;
        imm_e         <= imm_d;
        rd_e          <= rd_d;
        alusign_e     <= alusign_d;
        aluctrl_e     <= aluctrl_d;
        branch_type_e <= branch_type_d;
        cmpsrc_e      <= cmpsrc_d;
        is_baj_e      <= is_baj_d;
        alusrca_e     <= alusrca_d;
        alusrcb_e     <= alusrcb_d;
        mem_write_e   <= mem_write_d;
        mem_read_e    <= mem_read_d;
        mem_sign_e    <= mem_sign_d;
        mem_digit_e   <= mem_digit_d;
        regwrite_e    <= regwrite_d;
        csrwrite_e    <=csrwrite_d;
        is_mret_e     <= is_mret_d;
        is_ecall_e    <= is_ecall_d;
    end
end

endmodule