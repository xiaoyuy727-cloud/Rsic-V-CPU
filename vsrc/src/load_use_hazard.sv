module load_use_hazard (
    input  logic        mem_read_e,
    input  logic [4:0]  rd_e,
    input  logic [4:0]  rs1_d,
    input  logic [4:0]  rs2_d,
    output logic        load_use_stall
);

    always_comb begin
        load_use_stall = 1'b0;

        if (mem_read_e && (rd_e != 5'd0) &&
           ((rd_e == rs1_d) || (rd_e == rs2_d))) begin
            load_use_stall = 1'b1;
        end
    end

endmodule