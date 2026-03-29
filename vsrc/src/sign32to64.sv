//模块名称：sign32to64
//接口：input logic [63:0] short_imm
//     output logic [63:0] long_imm
//功能：截取64位short_imm的低32位，符号扩展到64位long_imm

module sign32to64(
    input  logic [63:0] short_imm,
    output logic [63:0] long_imm
);

    assign long_imm = {{32{short_imm[31]}}, short_imm[31:0]};

endmodule