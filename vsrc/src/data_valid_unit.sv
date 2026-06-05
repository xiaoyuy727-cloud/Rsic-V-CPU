module data_valid_unit(
    input logic [63:0] address,
    output logic daddr_exc_m
);
    always_comb begin
        if (address[1:0]) daddr_exc_m = 1'b1;
        else daddr_exc_m = 1'b0;
    end
endmodule