//模块名称：srcb_mux
//接口： input logic [63:0] imm_e
//      input logic [63:0] rs2_val_e
//      input logic alusrc_e
//      output logic [63:0] srcb_e
//功能：复用器。
//      当alusrc_e=0时，将rs2_val_e写到srcb_e
//      当alusrc_e=1时，将imm_e写到srcb_e

module srcb_mux(
    input  logic [63:0] imm_e,
    input  logic [63:0] rs2_val_e,
    input  logic        alusrcb_e,
    output logic [63:0] srcb_e
);

    always_comb begin
        if (alusrcb_e == 1'b0)
            srcb_e = rs2_val_e;
        else
            srcb_e = imm_e;
    end

endmodule