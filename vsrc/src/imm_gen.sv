//模块名称：imm_gen
//接口：
//      input logic [31:0] instr_d
//      output logic [63:0] imm_d

//功能：根据opcode和instr的其他信息决定该指令后续使用的imm具体是什么。
//    首先取instr_d的0-6位opcode
//    当opcode为0000011或0010011或0011011或1100111，Itype指令。对第20-31位的立即数进行符号扩展到64位之后写给imm_d
//    当opcode为0100011，Stype指令。对第7-11位、第25-31位的立即数拼接成12位立即数，进行符号扩展到64位之后写给imm_d
//    当opcode为0110111或0010111，Utype指令。对于第12-31位的立即数，首先左移12位变成一个32位立即数，然后符号扩展到64位之后写给imm_d
//    当opcode为1100011，Btype指令，对于第25-31位的立即数，对应的分别是立即数的5-10和12位；对于7-11位的立即数，对应的分别是立即数的1-4和11位。拼凑之后写给imm_d
//    当opcode为1101111，Jtype指令，imm = {{43{instr[31]}},instr[31], instr[19:12],instr[20],instr[30:21],1'b0};
//    当opcode为1110011，Itype指令，对于第15-19位的立即数，0扩展到64位。
module imm_gen (
    input  logic [31:0] instr_d,
    output logic [63:0] imm_d
);

    always_comb begin
        imm_d = 64'b0;

        case (instr_d[6:0])

            // I-type
            // load / OP-IMM / OP-IMM-32 / jalr
            7'b0000011,
            7'b0010011,
            7'b0011011,
            7'b1100111: begin
                imm_d = {{52{instr_d[31]}}, instr_d[31:20]};
            end

            // S-type
            7'b0100011: begin
                imm_d = {{52{instr_d[31]}}, instr_d[31:25], instr_d[11:7]};
            end

            // U-type
            // lui / auipc
            7'b0110111,
            7'b0010111: begin
                imm_d = {{32{instr_d[31]}}, instr_d[31:12], 12'b0};
            end

            // B-type
            7'b1100011: begin
                imm_d = {{51{instr_d[31]}},
                         instr_d[31],
                         instr_d[7],
                         instr_d[30:25],
                         instr_d[11:8],
                         1'b0};
            end

            // J-type
            // jal
            7'b1101111: begin
                imm_d = {{43{instr_d[31]}},
                         instr_d[31],
                         instr_d[19:12],
                         instr_d[20],
                         instr_d[30:21],
                         1'b0};
            end

            7'b1110011: begin
                imm_d={59'd0,instr_d[19:15]};
            end

            default: begin
                imm_d = 64'b0;
            end
        endcase
    end

endmodule