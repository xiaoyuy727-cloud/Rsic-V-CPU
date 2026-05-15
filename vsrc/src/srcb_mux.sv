//模块名称：srcb_mux
//接口： input logic [63:0] imm_e
//      input logic [63:0] rs2_val_e
//      input logic [1:0]alusrcb_e
//      output logic [63:0] srcb_e
//功能：复用器。
//      当alusrc_e=0时，将rs2_val_e写到srcb_e
//      当alusrc_e=1时，将imm_e写到srcb_e
//      当alusrc_e=时，将0到srcb_e

module srcb_mux(
    input  logic [63:0] imm_e,
    input  logic [63:0] rs2_val_e,
    input  logic [1:0]  alusrcb_e,
    output logic [63:0] srcb_e
);

    always_comb begin
        if (alusrcb_e == 2'b0)
            srcb_e = rs2_val_e;
        else if (alusrcb_e == 2'b01)
            srcb_e = imm_e;
        else 
            srcb_e = 0;
    end

endmodule
