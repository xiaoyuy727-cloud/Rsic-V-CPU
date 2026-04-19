//模块名称：branch_cmp
//接口：
//input logic [63:0] a
//input logic [63:0] b
//input logic [2:0] branch_type_e
//output logic cmp_res
//功能：branch_type_e是0-5分别代表=，！=，有符号<,有符号>=,无符号<，无符号>=。
//     对a和b根据type信号进行这6种比较，如果成立，那么cmp_res写成1，否则写0
  

module branch_cmp (
    input  logic [63:0] a,
    input  logic [63:0] b,
    input  logic [2:0]  branch_type_e,
    output logic        cmp_res
);

    always_comb begin
        cmp_res = 1'b0;

        case (branch_type_e)
            3'd0: cmp_res = (a == b);                       // BEQ
            3'd1: cmp_res = (a != b);                       // BNE
            3'd2: cmp_res = ($signed(a) <  $signed(b));     // BLT
            3'd3: cmp_res = ($signed(a) >= $signed(b));     // BGE
            3'd4: cmp_res = (a < b);                        // BLTU
            3'd5: cmp_res = (a >= b);                       // BGEU
            default: cmp_res = 1'b0;
        endcase
    end

endmodule