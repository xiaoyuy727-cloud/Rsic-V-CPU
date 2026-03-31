//现在的实现没有使用它了，不过先保留一下吧。

//模块名称：alu_adder
//接口:input logic [63:0] pc
//    output logic [63:0] next_pc
//功能:输入pc,输出pc+4

module alu_adder(
    input  logic [63:0] pc,
    output logic [63:0] next_pc
);

    assign next_pc = pc + 64'd4;

endmodule
