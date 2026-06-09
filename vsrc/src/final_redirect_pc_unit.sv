// 模块名称：final_redirect_pc_unit
// 功能：统一仲裁最终 redirect PC
//
// 优先级：
//   1. trap_valid            -> csr_mtvec
//   2. mret_valid            -> csr_mepc
//   3. branch_redirect_valid -> branch_redirect_pc
//   4. default               -> 0
//
// 注意：
//   本模块只选择 PC，不判断异常/中断原因，不修改 CSR。
module final_redirect_pc_unit(
    input  logic [63:0] branch_redirect_pc,
    input  logic        branch_redirect_valid,

    input  logic [63:0] csr_mepc,
    input  logic [63:0] csr_mtvec,

    input  logic        trap_valid,
    input  logic        mret_valid,

    output logic [63:0] final_redirect_pc
);

    always_comb begin
        if (trap_valid) begin
            final_redirect_pc = csr_mtvec;
        end
        else if (mret_valid) begin
            final_redirect_pc = csr_mepc;
        end
        else if (branch_redirect_valid) begin
            final_redirect_pc = branch_redirect_pc;
        end
        else begin
            final_redirect_pc = 64'b0;
        end
    end

endmodule