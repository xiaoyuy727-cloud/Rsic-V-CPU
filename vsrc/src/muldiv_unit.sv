// 功能：实现按照始终的乘除法器。
// 接口情况：srca和b分别接入rs1和2.aluctrl：10 mul 11 div 12 divu 13 rem 14 remu；alusign：1时为带w的指令
//mdu_stall：1时把流水线都stall

module muldiv_unit (
    input  logic        clk,
    input  logic        reset,

    input  logic        req_valid,
    input  logic [63:0] req_srca,
    input  logic [63:0] req_srcb,
    input  logic [3:0]  req_op,
    input  logic        req_word,

    output logic        req_ready,

    output logic        resp_valid,
    output logic [63:0] resp_result
);

    typedef enum logic [1:0] {
        IDLE,
        MUL,
        DIV,
        DONE
    } state_t;

    state_t state;

    localparam logic [3:0] ALU_MUL  = 4'd10;
    localparam logic [3:0] ALU_DIV  = 4'd11;
    localparam logic [3:0] ALU_DIVU = 4'd12;
    localparam logic [3:0] ALU_REM  = 4'd13;
    localparam logic [3:0] ALU_REMU = 4'd14;

    assign req_ready   = (state == IDLE);
    assign resp_valid  = (state == DONE);
    assign resp_result = result_r;

    logic is_mul;
    logic is_div;
    logic is_rem;
    logic is_unsigned;

    assign is_mul      = req_op == ALU_MUL;
    assign is_div      = req_op == ALU_DIV || req_op == ALU_DIVU;
    assign is_rem      = req_op == ALU_REM || req_op == ALU_REMU;
    assign is_unsigned = req_op == ALU_DIVU || req_op == ALU_REMU;

    logic [3:0] op_r;
    logic       word_r;
    logic       unsigned_r;
    logic       rem_r;

    logic [6:0] cnt;

    logic [127:0] mul_product;
    logic [127:0] mul_multiplicand;
    logic [63:0]  mul_multiplier;

    logic [63:0] dividend;
    logic [63:0] divisor;
    logic [63:0] quotient;
    logic [64:0] remainder;

    logic quotient_neg;
    logic remainder_neg;

    logic [63:0] result_r;

    function automatic logic [63:0] abs64(input logic [63:0] x);
        abs64 = x[63] ? (~x + 64'd1) : x;
    endfunction

    function automatic logic [31:0] abs32(input logic [31:0] x);
        abs32 = x[31] ? (~x + 32'd1) : x;
    endfunction

    function automatic logic [63:0] sext32(input logic [31:0] x);
        sext32 = {{32{x[31]}}, x};
    endfunction

    always_ff @(posedge clk) begin
        logic [64:0]  rem_next;
        logic [63:0]  quo_next;
        logic [63:0]  q_signed;
        logic [63:0]  r_signed;
        logic [127:0] mul_next;

        if (reset) begin
            state            <= IDLE;
            cnt              <= 7'd0;
            result_r         <= 64'd0;

            mul_product      <= 128'd0;
            mul_multiplicand <= 128'd0;
            mul_multiplier   <= 64'd0;

            dividend         <= 64'd0;
            divisor          <= 64'd0;
            quotient         <= 64'd0;
            remainder        <= 65'd0;

            quotient_neg     <= 1'b0;
            remainder_neg    <= 1'b0;

            op_r             <= 4'd0;
            word_r           <= 1'b0;
            unsigned_r       <= 1'b0;
            rem_r            <= 1'b0;
        end else begin
            case (state)

                IDLE: begin
                    if (req_valid && req_ready) begin
                        op_r       <= req_op;
                        word_r     <= req_word;
                        unsigned_r <= is_unsigned;
                        rem_r      <= is_rem;
                        cnt        <= 7'd0;

                        if (is_mul) begin
                            mul_product <= 128'd0;

                            if (req_word) begin
                                mul_multiplicand <= {96'd0, req_srca[31:0]};
                                mul_multiplier   <= {32'd0, req_srcb[31:0]};
                            end else begin
                                mul_multiplicand <= {64'd0, req_srca};
                                mul_multiplier   <= req_srcb;
                            end

                            state <= MUL;
                        end else begin
                            quotient  <= 64'd0;
                            remainder <= 65'd0;

                            if (req_word) begin
                                if (is_unsigned) begin
                                    dividend      <= {req_srca[31:0], 32'd0};
                                    divisor       <= {32'd0, req_srcb[31:0]};
                                    quotient_neg  <= 1'b0;
                                    remainder_neg <= 1'b0;
                                end else begin
                                    dividend      <= {abs32(req_srca[31:0]), 32'd0};
                                    divisor       <= {32'd0, abs32(req_srcb[31:0])};
                                    quotient_neg  <= req_srca[31] ^ req_srcb[31];
                                    remainder_neg <= req_srca[31];
                                end
                            end else begin
                                if (is_unsigned) begin
                                    dividend      <= req_srca;
                                    divisor       <= req_srcb;
                                    quotient_neg  <= 1'b0;
                                    remainder_neg <= 1'b0;
                                end else begin
                                    dividend      <= abs64(req_srca);
                                    divisor       <= abs64(req_srcb);
                                    quotient_neg  <= req_srca[63] ^ req_srcb[63];
                                    remainder_neg <= req_srca[63];
                                end
                            end

                            if ((!req_word && req_srcb == 64'd0) ||
                                ( req_word && req_srcb[31:0] == 32'd0)) begin

                                if (is_div)
                                    result_r <= 64'hFFFF_FFFF_FFFF_FFFF;
                                else if (req_word)
                                    result_r <= sext32(req_srca[31:0]);
                                else
                                    result_r <= req_srca;

                                state <= DONE;
                            end else if (!is_unsigned && is_div &&
                                ((!req_word && req_srca == 64'h8000_0000_0000_0000 &&
                                               req_srcb == 64'hFFFF_FFFF_FFFF_FFFF) ||
                                 ( req_word && req_srca[31:0] == 32'h8000_0000 &&
                                               req_srcb[31:0] == 32'hFFFF_FFFF))) begin

                                if (req_word)
                                    result_r <= 64'hFFFF_FFFF_8000_0000;
                                else
                                    result_r <= 64'h8000_0000_0000_0000;

                                state <= DONE;
                            end else if (!is_unsigned && is_rem &&
                                ((!req_word && req_srca == 64'h8000_0000_0000_0000 &&
                                               req_srcb == 64'hFFFF_FFFF_FFFF_FFFF) ||
                                 ( req_word && req_srca[31:0] == 32'h8000_0000 &&
                                               req_srcb[31:0] == 32'hFFFF_FFFF))) begin

                                result_r <= 64'd0;
                                state <= DONE;
                            end else begin
                                state <= DIV;
                            end
                        end
                    end
                end

                MUL: begin
                    if (mul_multiplier[0])
                        mul_next = mul_product + mul_multiplicand;
                    else
                        mul_next = mul_product;

                    mul_product      <= mul_next;
                    mul_multiplicand <= mul_multiplicand << 1;
                    mul_multiplier   <= mul_multiplier >> 1;
                    cnt              <= cnt + 7'd1;

                    if ((!word_r && cnt == 7'd63) ||
                        ( word_r && cnt == 7'd31)) begin

                        if (word_r)
                            result_r <= sext32(mul_next[31:0]);
                        else
                            result_r <= mul_next[63:0];

                        state <= DONE;
                    end
                end

                DIV: begin
                    rem_next = {remainder[63:0], dividend[63]};
                    quo_next = quotient << 1;

                    if (rem_next >= {1'b0, divisor}) begin
                        rem_next = rem_next - {1'b0, divisor};
                        quo_next[0] = 1'b1;
                    end

                    remainder <= rem_next;
                    quotient  <= quo_next;
                    dividend  <= dividend << 1;
                    cnt       <= cnt + 7'd1;

                    if ((!word_r && cnt == 7'd63) ||
                        ( word_r && cnt == 7'd31)) begin

                        q_signed = quotient_neg  ? (~quo_next + 64'd1) : quo_next;
                        r_signed = remainder_neg ? (~rem_next[63:0] + 64'd1) : rem_next[63:0];

                        if (rem_r) begin
                            if (word_r)
                                result_r <= sext32(r_signed[31:0]);
                            else
                                result_r <= r_signed;
                        end else begin
                            if (word_r)
                                result_r <= sext32(q_signed[31:0]);
                            else
                                result_r <= q_signed;
                        end

                        state <= DONE;
                    end
                end

                DONE: begin
                    state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule