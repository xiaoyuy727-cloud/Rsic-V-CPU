module data_valid_unit(
    input  logic [63:0] address,
    input  logic [1:0]  mem_digit_m,
    input  logic        mem_read_m,
    input  logic        mem_write_m,
    output logic        daddr_exc_m
);
    always_comb begin
        daddr_exc_m = 1'b0;

        if (mem_read_m || mem_write_m) begin
            unique case (mem_digit_m)
                2'd0: daddr_exc_m = 1'b0;              // byte: lb/lbu/sb
                2'd1: daddr_exc_m = address[0];        // halfword: lh/lhu/sh
                2'd2: daddr_exc_m = |address[1:0];     // word: lw/lwu/sw
                2'd3: daddr_exc_m = |address[2:0];     // doubleword: ld/sd
                default: daddr_exc_m = 1'b0;
            endcase
        end
    end
endmodule