module control_unit (
    input  logic [2:0] funct3,
    input  logic [6:0] opcode,
    input  logic       bit30,
    input  logic [11:0] immediate,

    output logic       alusign_d,
    output logic [3:0] aluctrl_d,
    output logic [1:0]  alusrcb_d,
    output logic       regwrite_d,
    output logic       mem_write_d,
    output logic       mem_read_d,
    output logic       mem_sign_d,
    output logic [1:0] wb_result_d,
    output logic [1:0] mem_digit_d,
    output logic [1:0] alusrca_d,
    output logic       csrwrite_d,
    output logic       is_ecall_d,
    output logic       is_mret_d,

    output logic       cmpsrc_d,
    output logic [1:0] is_baj_d,
    output logic [2:0] branch_type_d
);

always_comb begin
    // default values
    is_ecall_d = 1'b0;
    is_mret_d  = 1'b0;
    alusign_d    = 1'b0;
    aluctrl_d    = 4'd0;
    alusrca_d    = 2'd0;
    alusrcb_d    = 2'b0;
    regwrite_d   = 1'b0;
    mem_write_d  = 1'b0;
    mem_read_d   = 1'b0;
    mem_sign_d   = 1'b0;
    wb_result_d  = 2'b0;
    mem_digit_d  = 2'd0;

    cmpsrc_d     = 1'b0;
    is_baj_d     = 2'd0;
    branch_type_d = 3'd0;
    csrwrite_d=  1'd0;

    case (opcode)

        // ================= I-type =================
        7'b1110011: begin

            

            case(funct3)
                3'b000:begin

                    case(immediate)
                        12'h000:is_ecall_d=1'b1;
                        12'h302:is_mret_d=1'b1;
                        default:;
                    endcase

                end
                3'b001,3'b010,3'b011:begin

                    alusrca_d=2'b01;
                    regwrite_d=1'b1;
                    wb_result_d=2'b11;
                    csrwrite_d=1'b1;

                end
                3'b101,3'b110,3'b111:begin

                    regwrite_d=1'b1;
                    wb_result_d=2'b11;
                    csrwrite_d=1'b1;
                    alusrcb_d=2'b01;

                end
                default:;
            endcase
        end

        7'b0010011: begin
            alusrca_d  = 2'd1;   // rs1
            alusrcb_d  = 2'b01;   // imm
            regwrite_d = 1'b1;

            case (funct3)
                3'b000: aluctrl_d = 4'd0; // addi
                3'b100: aluctrl_d = 4'd1; // xori
                3'b110: aluctrl_d = 4'd2; // ori
                3'b111: aluctrl_d = 4'd3; // andi
                3'b010: aluctrl_d = 4'd5; // slti
                3'b011: aluctrl_d = 4'd6; // sltiu
                3'b001: aluctrl_d = 4'd7; // slli
                3'b101: aluctrl_d = bit30 ? 4'd9 : 4'd8; // srai/srli
                default: ;
            endcase
        end

        // ================= R-type =================
        7'b0110011: begin
            alusrca_d  = 2'd1;   // rs1
            alusrcb_d  = 2'b0;   // rs2
            regwrite_d = 1'b1;

            case (funct3)
                3'b000: aluctrl_d = bit30 ? 4'd4 : 4'd0; // sub/add
                3'b100: aluctrl_d = 4'd1; // xor
                3'b110: aluctrl_d = 4'd2; // or
                3'b111: aluctrl_d = 4'd3; // and
                3'b001: aluctrl_d = 4'd7; // sll
                3'b010: aluctrl_d = 4'd5; // slt
                3'b011: aluctrl_d = 4'd6; // sltu
                3'b101: aluctrl_d = bit30 ? 4'd9 : 4'd8; // sra/srl
                default: ;
            endcase
        end

        // ================= I-type W =================
        7'b0011011: begin
            alusign_d  = 1'b1;
            alusrca_d  = 2'd1;   // rs1
            alusrcb_d  = 2'b01;   // imm
            regwrite_d = 1'b1;

            case (funct3)
                3'b000: aluctrl_d = 4'd0; // addiw
                3'b001: aluctrl_d = 4'd7; // slliw
                3'b101: aluctrl_d = bit30 ? 4'd9 : 4'd8; // sraiw/srliw
                default: ;
            endcase
        end

        // ================= R-type W =================
        7'b0111011: begin
            alusign_d  = 1'b1;
            alusrca_d  = 2'd1;   // rs1
            alusrcb_d  = 2'b00;   // rs2
            regwrite_d = 1'b1;

            case (funct3)
                3'b000: aluctrl_d = bit30 ? 4'd4 : 4'd0; // subw/addw
                3'b001: aluctrl_d = 4'd7; // sllw
                3'b101: aluctrl_d = bit30 ? 4'd9 : 4'd8; // sraw/srlw
                default: ;
            endcase
        end

        // ================= LOAD =================
        7'b0000011: begin
            alusrca_d   = 2'd1;  // rs1
            alusrcb_d   = 2'b01;  // imm
            regwrite_d  = 1'b1;
            mem_read_d  = 1'b1;
            wb_result_d = 2'b01;  // write back from memory
            aluctrl_d   = 4'd0;  // address = rs1 + imm

            case (funct3)
                3'b000: begin mem_sign_d = 1'b0; mem_digit_d = 2'd0; end // lb
                3'b001: begin mem_sign_d = 1'b0; mem_digit_d = 2'd1; end // lh
                3'b010: begin mem_sign_d = 1'b0; mem_digit_d = 2'd2; end // lw
                3'b011: begin mem_sign_d = 1'b0; mem_digit_d = 2'd3; end // ld
                3'b100: begin mem_sign_d = 1'b1; mem_digit_d = 2'd0; end // lbu
                3'b101: begin mem_sign_d = 1'b1; mem_digit_d = 2'd1; end // lhu
                3'b110: begin mem_sign_d = 1'b1; mem_digit_d = 2'd2; end // lwu
                default: ;
            endcase
        end

        // ================= STORE =================
        7'b0100011: begin
            alusrca_d   = 2'd1;  // rs1
            alusrcb_d   = 2'b01;  // imm
            mem_write_d = 1'b1;
            aluctrl_d   = 4'd0;  // address = rs1 + imm

            case (funct3)
                3'b000: mem_digit_d = 2'd0; // sb
                3'b001: mem_digit_d = 2'd1; // sh
                3'b010: mem_digit_d = 2'd2; // sw
                3'b011: mem_digit_d = 2'd3; // sd
                default: ;
            endcase
        end

        // ================= LUI =================
        7'b0110111: begin
            regwrite_d = 1'b1;
            alusrca_d  = 2'd0;   // zero
            alusrcb_d  = 2'b01;   // imm
            aluctrl_d  = 4'd0;   // 0 + imm
        end

        // ================= AUIPC =================
        7'b0010111: begin
            regwrite_d = 1'b1;
            alusrca_d  = 2'd2;   // pc
            alusrcb_d  = 2'b01;   // imm
            aluctrl_d  = 4'd0;   // pc + imm
        end

        // ================= BRANCH =================
        7'b1100011: begin
            alusrca_d = 2'd2;    // pc
            alusrcb_d = 2'b01;    // imm
            aluctrl_d = 4'd0;    // target = pc + imm
            is_baj_d  = 2'd1;    // branch

            case (funct3)
                3'b000: branch_type_d = 3'd0; // beq
                3'b001: branch_type_d = 3'd1; // bne
                3'b100: branch_type_d = 3'd2; // blt
                3'b101: branch_type_d = 3'd3; // bge
                3'b110: branch_type_d = 3'd4; // bltu
                3'b111: branch_type_d = 3'd5; // bgeu
                default: ;
            endcase
        end

        // ================= JAL =================
        7'b1101111: begin
            regwrite_d = 1'b1;
            alusrca_d  = 2'd2;   // pc
            alusrcb_d  = 2'b01;   // imm
            aluctrl_d  = 4'd0;   // target = pc + imm
            is_baj_d   = 2'd2;   // jal
        end

        // ================= JALR =================
        7'b1100111: begin
            regwrite_d = 1'b1;
            alusrca_d  = 2'd1;   // rs1
            alusrcb_d  = 2'b01;   // imm
            aluctrl_d  = 4'd0;   // target = rs1 + imm
            is_baj_d   = 2'd3;   // jalr
        end

        default: begin
        end

    endcase
end

endmodule