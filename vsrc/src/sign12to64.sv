//模块名称：sign12to64
//接口：input logic [11:0] short_imm
//     output logic [63:0] long_imm
//功能：将12位short_imm符号扩展到64位long_imm

module sign12to64(
    input  logic [11:0] short_imm,
    output logic [63:0] long_imm
);

    assign long_imm = {{52{short_imm[11]}}, short_imm};

endmodule