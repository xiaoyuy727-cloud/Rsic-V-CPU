//模块名称：imm_gen
//接口：
//      input logic [31:0] instr_d
//      output logic [63:0] imm_d

//功能：根据opcode和instr的其他信息决定该指令后续使用的imm具体是什么。
//    首先取instr_d的0-6位opcode
//    当opcode为0000011或0010011或0011011，Itype指令。对第20-31位的立即数进行符号扩展到64位之后写给imm_d
//    当opcode为0100011，Stype指令。对第7-11位、第25-31位的立即数拼接成12位立即数，进行符号扩展到64位之后写给imm_d
//    当opcode为0110111，Utype指令。对于第12-31位的立即数，首先左移12位变成一个32位立即数，然后符号扩展到64位之后写给imm_d


module imm_gen (
    input  logic [31:0] instr_d,
    output logic [63:0] imm_d
);

    logic [6:0] opcode;

    always_comb begin
        opcode = instr_d[6:0];
        imm_d  = 64'd0;

        unique case (opcode)
            // I-type: 0000011, 0010011, 0011011
            7'b0000011,
            7'b0010011,
            7'b0011011: begin
                imm_d = {{52{instr_d[31]}}, instr_d[31:20]};
            end

            // S-type: 0100011
            7'b0100011: begin
                imm_d = {{52{instr_d[31]}}, instr_d[31:25], instr_d[11:7]};
            end

            // U-type: 0110111 (lui)
            7'b0110111: begin
                imm_d = {{32{instr_d[31]}}, instr_d[31:12], 12'b0};
            end

            default: begin
                imm_d = 64'd0;
            end
        endcase
    end

endmodule
