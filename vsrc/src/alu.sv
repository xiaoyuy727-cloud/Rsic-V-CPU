//模块名称：alu
//接口：input logic [63:0] srca_e
//     input logic [63:0] srcb_e
//     input logic [2:0] aluctrl_e
//     output logic [63:0] alu_result_e
//功能：对srca_e，srcb_e根据aluctrl_e进行4种不同运算。
//     当aluctrl_e=0，输出srca_e+srcb_e
//     当aluctrl_e=1，输出srca_e按位异或srcb_e
//     当aluctrl_e=2，输出srca_e按位或srcb_e
//     当aluctrl_e=3，输出srca_e按位与srcb_e
//     当aluctrl_e=4，输出srca_e-srcb_e
//     忽略溢出，输出给alu_result_e

module alu(
    input  logic [63:0] srca_e,
    input  logic [63:0] srcb_e,
    input  logic [2:0]  aluctrl_e,
    output logic [63:0] alu_result_e
);

    always_comb begin
        case (aluctrl_e)
            3'd0: alu_result_e = srca_e + srcb_e;   // 加法
            3'd1: alu_result_e = srca_e ^ srcb_e;   // 按位异或
            3'd2: alu_result_e = srca_e | srcb_e;   // 按位或
            3'd3: alu_result_e = srca_e & srcb_e;   // 按位与
            3'd4: alu_result_e = srca_e - srcb_e;   // 减法
            default: alu_result_e = 64'd0;          // 默认输出 0
        endcase
    end

endmodule