//模块名称：srca_mux
//接口： input logic [63:0] rs1_val_e
//      input logic alusrca_e
//      output logic [63:0] srca_e
//功能：复用器。
//      当alusrc_e=0时，将0写到srca_e
//      当alusrc_e=1时，将rs1_val_e写到srca_e

module srca_mux (
    input  logic [63:0] rs1_val_e,
    input  logic        alusrca_e,
    output logic [63:0] srca_e
);

    always_comb begin
        if (alusrca_e) begin
            srca_e = rs1_val_e;
        end else begin
            srca_e = 64'b0;
        end
    end

endmodule