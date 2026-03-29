//模块名称：control_unit
//接口：input logic [2:0] funct3
//     input logic [6:0] funct7
//     input logic [6:0] opcode
//     output logic alusign_d
//     output logic [2:0] aluctrl_d
//     output logic alusrcb_d
//     output logic regwrite_d
//     output logic mem_write_d
//     output logic mem_read_d
//     output logic mem_sign_d
//     output logic wb_result_d
//     output logic[1:0] mem_digit_d
//     output logic alusrca_d
//功能：将指令编码翻译成控制信号。控制信号默认为0。（具体的控制信号翻译表见excel）
//当opcode为0010011时，将alusrca_d写为1，mem_write_d写为0，mem_read_d写为0，mem_sign_d写为0，wb_result_d写为0，mem_digit_d写为0,alusrcb_d写为1，memwrite_d写为0，alusign_d写为0，regwrite_d写为1
//在此基础上，当funct3为000时，将aluctrl_d写为0。
//           当funct3为100时，将aluctrl_d写为1。
//           当funct3为110时，将aluctrl_d写为2。
//           当funct3为111时，将aluctrl_d写为3。

//当opcode为0110011时，将alusrc_d写为0，memwrite_d写为0，alusign_d写为0，regwrite_d写为1
//在此基础上，当funct3为000，且funct7为0000000时，将aluctrl_d写为0。
//           当funct3为000，且funct7为0100000时，将aluctrl_d写为4。
//           当funct3为100时，将aluctrl_d写为1。
//           当funct3为110时，将aluctrl_d写为2。
//           当funct3为111时，将aluctrl_d写为3。

//当opcode为0011011时，将alusrc_d写为1，memwrite_d写为0，alusign_d写为1，regwrite_d写为1
//在此基础上，当funct3为000时，将aluctrl_d写为0。

//当opcode为0111011时，将alusrc_d写为0，memwrite_d写为0，alusign_d写为1，regwrite_d写为1
//在此基础上，当funct3为000，且funct7为0000000时，将aluctrl_d写为0。
//           当funct3为000，且funct7为0100000时，将aluctrl_d写为4。
module control_unit (
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    input  logic [6:0] opcode,

    output logic       alusign_d,
    output logic [2:0] aluctrl_d,
    output logic       alusrcb_d,
    output logic       regwrite_d,
    output logic       mem_write_d,
    output logic       mem_read_d,
    output logic       mem_sign_d,
    output logic       wb_result_d,
    output logic [1:0] mem_digit_d,
    output logic       alusrca_d
);

    always_comb begin
        // 默认全为 0
        alusign_d   = 1'b0;
        aluctrl_d   = 3'b000;
        alusrcb_d   = 1'b0;
        regwrite_d  = 1'b0;
        mem_write_d = 1'b0;
        mem_read_d  = 1'b0;
        mem_sign_d  = 1'b0;
        wb_result_d = 1'b0;
        mem_digit_d = 2'b00;
        alusrca_d   = 1'b0;

        case (opcode)

            // =========================
            // I-type arithmetic
            // addi xori ori andi
            // opcode = 0010011
            // =========================
            7'b0010011: begin
                alusrca_d  = 1'b1;
                alusrcb_d  = 1'b1;
                regwrite_d = 1'b1;

                case (funct3)
                    3'b000: aluctrl_d = 3'd0; // addi
                    3'b100: aluctrl_d = 3'd1; // xori
                    3'b110: aluctrl_d = 3'd2; // ori
                    3'b111: aluctrl_d = 3'd3; // andi
                    default: begin
                    end
                endcase
            end

            // =========================
            // addiw
            // opcode = 0011011
            // =========================
            7'b0011011: begin
                alusign_d  = 1'b1;
                aluctrl_d  = 3'd0;
                alusrca_d  = 1'b1;
                alusrcb_d  = 1'b1;
                regwrite_d = 1'b1;
            end

            // =========================
            // R-type arithmetic
            // add sub and or xor addw subw
            // opcode = 0110011 / 0111011
            // =========================
            7'b0110011: begin
                alusrca_d  = 1'b1;
                alusrcb_d  = 1'b0;
                regwrite_d = 1'b1;

                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            aluctrl_d = 3'd4;   // sub
                        else
                            aluctrl_d = 3'd0;   // add
                    end
                    3'b111: aluctrl_d = 3'd3;   // and
                    3'b110: aluctrl_d = 3'd2;   // or
                    3'b100: aluctrl_d = 3'd1;   // xor
                    default: begin
                    end
                endcase
            end

            7'b0111011: begin
                alusign_d  = 1'b1;
                alusrca_d  = 1'b1;
                alusrcb_d  = 1'b0;
                regwrite_d = 1'b1;

                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            aluctrl_d = 3'd4;   // subw
                        else
                            aluctrl_d = 3'd0;   // addw
                    end
                    default: begin
                    end
                endcase
            end

            // =========================
            // Load
            // lb lh lw ld lbu lhu lwu
            // opcode = 0000011
            // =========================
            7'b0000011: begin
                aluctrl_d   = 3'd0;   // address = rs1 + imm
                alusrca_d   = 1'b1;
                alusrcb_d   = 1'b1;
                regwrite_d  = 1'b1;
                mem_read_d  = 1'b1;
                wb_result_d = 1'b1;

                case (funct3)
                    3'b000: begin // lb
                        mem_sign_d  = 1'b0;
                        mem_digit_d = 2'd0;
                    end
                    3'b001: begin // lh
                        mem_sign_d  = 1'b0;
                        mem_digit_d = 2'd1;
                    end
                    3'b010: begin // lw
                        mem_sign_d  = 1'b0;
                        mem_digit_d = 2'd2;
                    end
                    3'b011: begin // ld
                        mem_sign_d  = 1'b0;
                        mem_digit_d = 2'd3;
                    end
                    3'b100: begin // lbu
                        mem_sign_d  = 1'b1;
                        mem_digit_d = 2'd0;
                    end
                    3'b101: begin // lhu
                        mem_sign_d  = 1'b1;
                        mem_digit_d = 2'd1;
                    end
                    3'b110: begin // lwu
                        mem_sign_d  = 1'b1;
                        mem_digit_d = 2'd2;
                    end
                    default: begin
                    end
                endcase
            end

            // =========================
            // Store
            // sb sh sw sd
            // opcode = 0100011
            // =========================
            7'b0100011: begin
                aluctrl_d   = 3'd0;   // address = rs1 + imm
                alusrca_d   = 1'b1;
                alusrcb_d   = 1'b1;
                mem_write_d = 1'b1;

                case (funct3)
                    3'b000: mem_digit_d = 2'd0; // sb
                    3'b001: mem_digit_d = 2'd1; // sh
                    3'b010: mem_digit_d = 2'd2; // sw
                    3'b011: mem_digit_d = 2'd3; // sd
                    default: begin
                    end
                endcase
            end

            // =========================
            // lui
            // opcode = 0110111
            // =========================
            7'b0110111: begin
                regwrite_d = 1'b1;
                // 其余保持默认 0
                // 按你的表：alusrca_d = 0, alusrcb_d = 0, wb_result_d = 0
            end

            default: begin
            end
        endcase
    end

endmodule