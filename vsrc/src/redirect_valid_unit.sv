//模块名称：redirect_valid_unit
//接口：input  logic cmp_res
// input logic [1:0] is_baj_e
// output logic redirect_valid
//功能：当is_baj_e是0，输出0。当is_baj_e是1，输出cmp_res。当is_baj_e是2或者3，输出1.

module redirect_valid_unit (
    input  logic       cmp_res,
    input  logic [1:0] is_baj_e,
    output logic       redirect_valid
);

    always_comb begin
        redirect_valid = 1'b0;

        case (is_baj_e)
            2'd0: redirect_valid = 1'b0;        // 非跳转
            2'd1: redirect_valid = cmp_res;     // branch
            2'd2: redirect_valid = 1'b1;        // jal
            2'd3: redirect_valid = 1'b1;        // jalr
            default: redirect_valid = 1'b0;
        endcase
    end

endmodule