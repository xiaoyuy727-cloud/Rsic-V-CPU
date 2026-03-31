//模块名称：alures_mux
//接口：input logic alusign_e
//     input logic [63:0] alu_result_e
//     input logic [63:0] long_alu_result_e
//     output logic [63:0] final_alu_result_e
//功能：复用器。
//     当alusign_e=0时，将alu_result_e写入final_alu_result_e
//     当alusign_e=1时，将long_alu_result_e写入final_alu_result_e(针对rv64i这种特殊指令)

module alures_mux(
    input  logic        alusign_e,
    input  logic [63:0] alu_result_e,
    input  logic [63:0] long_alu_result_e,
    output logic [63:0] final_alu_result_e
);

    always_comb begin
        if (alusign_e == 1'b0)
            final_alu_result_e = alu_result_e;
        else
            final_alu_result_e = long_alu_result_e;
    end

endmodule
