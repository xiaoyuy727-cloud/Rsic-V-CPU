module alu_md_result_mux (
    input logic [63:0] alu_result,
    input logic [63:0] md_result,
    input logic [3:0] aluctrl_e,
    output logic [63:0] alu_md_result 
);

    always_comb begin
        if (aluctrl_e <= 4'd9) begin
            alu_md_result = alu_result;
        end else begin
            alu_md_result = md_result;
        end
    end

endmodule