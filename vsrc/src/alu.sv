//模块名称：alu
//接口：input logic [63:0] srca_e
//     input logic [63:0] srcb_e
//     input logic [3:0] aluctrl_e
//     input logic alusign_e
//     output logic [63:0] alu_result_e
//功能：对srca_e，srcb_e根据aluctrl_e进行4种不同运算。
//     当aluctrl_e=0，输出srca_e+srcb_e
//     当aluctrl_e=1，输出srca_e按位异或srcb_e
//     当aluctrl_e=2，输出srca_e按位或srcb_e
//     当aluctrl_e=3，输出srca_e按位与srcb_e
//     当aluctrl_e=4，输出srca_e-srcb_e
//     当aluctrl_e=5，输出srca_e有符号小于srcb_e（是则输出1，否则0）
//     当aluctrl_e=6，输出srca_e无符号小于srcb_e（是则输出1，否则0）
//     当aluctrl_e=7，当alusign_e=0，输出srca_e逻辑左移srcb_e[5:0]；否则输出srca_e[31:0]逻辑左移srcb_e[4:0]
//     当aluctrl_e=8，当alusign_e=0，输出srca_e逻辑右移srcb_e[5:0]；否则输出srca_e[31:0]逻辑右移srcb_e[4:0]
//     当aluctrl_e=9，当alusign_e=0，输出srca_e算术右移srcb_e[5:0]；否则输出srca_e[31:0]算术右移srcb_e[4:0]
//     忽略溢出，输出给alu_result_e
module alu ( 
    input  logic [63:0] srca_e, 
    input  logic [63:0] srcb_e, 
    input  logic [3:0]  aluctrl_e, 
    input  logic        alusign_e, 
    output logic [63:0] alu_result_e 
); 
 
    logic signed [31:0] sra32_res;

    always_comb begin 
        alu_result_e = 64'd0; 
        sra32_res    = 32'sd0;
 
        unique case (aluctrl_e) 
            4'd0: alu_result_e = srca_e + srcb_e; 
            4'd1: alu_result_e = srca_e ^ srcb_e; 
            4'd2: alu_result_e = srca_e | srcb_e; 
            4'd3: alu_result_e = srca_e & srcb_e; 
            4'd4: alu_result_e = srca_e - srcb_e; 
            4'd5: alu_result_e = ($signed(srca_e) < $signed(srcb_e)) ? 64'd1 : 64'd0; 
            4'd6: alu_result_e = (srca_e < srcb_e) ? 64'd1 : 64'd0; 
 
            4'd7: begin 
                if (alusign_e == 1'b0) 
                    alu_result_e = srca_e << srcb_e[5:0]; 
                else 
                    alu_result_e = {32'd0, (srca_e[31:0] << srcb_e[4:0])}; 
            end 
 
            4'd8: begin 
                if (alusign_e == 1'b0) 
                    alu_result_e = srca_e >> srcb_e[5:0]; 
                else 
                    alu_result_e = {32'd0, (srca_e[31:0] >> srcb_e[4:0])}; 
            end 
 
            4'd9: begin 
                if (alusign_e == 1'b0) 
                    alu_result_e = $signed(srca_e) >>> srcb_e[5:0]; 
                else begin
                    sra32_res   = $signed(srca_e[31:0]) >>> srcb_e[4:0];
                    alu_result_e = {{32{sra32_res[31]}}, sra32_res};
                end
            end 
 
            default: alu_result_e = 64'd0; 
        endcase 
    end 
 
endmodule