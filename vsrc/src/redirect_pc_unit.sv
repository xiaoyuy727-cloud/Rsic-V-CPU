//模块名称：redirect_pc_unit
//接口：
//input logic [63:0] alu_res
//input [1:0] is_baj_e //0代表都不是，1代表b类，2代表jal,3代表jalr。
//output logic [63:0] redirect_pc
//功能：当is_baj_e是0、1、2的时候正常输出input。3的时候输出alu_res & ~1

module redirect_pc_unit (
    input  logic [63:0] alu_res,
    input  logic [1:0]  is_baj_e,   // 0:none, 1:branch, 2:jal, 3:jalr
    output logic [63:0] redirect_pc
);

    always_comb begin
        // 默认：直接输出 ALU 结果
        redirect_pc = alu_res;

        // 只有 jalr 需要特殊处理
        if (is_baj_e == 2'd3) begin
            redirect_pc[0] = 1'b0;
        end
    end

endmodule