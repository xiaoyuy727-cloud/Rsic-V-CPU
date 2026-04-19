//现在不用了


//模块名称：alures_updater
//接口：
//input logic [1:0]is_baj_e
//input logic [63:0] alu_res
//input logic  cmp_res 
//input logic [63:0] pc_e
//input logic is_slti
//output logic [63:0] alu_new_res
//功能：当is_slti是0的时候，如果is_baj是2或3，那么将pc+4写给alunewres,否则将alures写给alunewres。
//     当is_slti是1的时候，如果cmp_res是1，将1写给alunewres，否则写0.

module alures_updater (
    input  logic [1:0]  is_baj_e,
    input  logic [63:0] alu_res,
    input  logic        cmp_res,
    input  logic [63:0] pc_e,
    input  logic        is_slti,
    output logic [63:0] alu_new_res
);

    always_comb begin
        // 默认直接透传 ALU 结果
        alu_new_res = alu_res;

        // slti/sltiu: 写回 0/1
        if (is_slti) begin
            if (cmp_res) begin
                alu_new_res = 64'd1;
            end else begin
                alu_new_res = 64'd0;
            end
        end
        // jal/jalr: 写回 pc+4
        else if ((is_baj_e == 2'd2) || (is_baj_e == 2'd3)) begin
            alu_new_res = pc_e + 64'd4;
        end
    end

endmodule