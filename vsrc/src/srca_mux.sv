//模块名称：srca_mux
//接口： input logic [63:0] rs1_val_e
//      input logic [1:0] alusrca_e
//      input logic [63:0] pc_e
//      output logic [63:0] srca_e
//功能：复用器。
//      当alusrc_e=0时，将0写到srca_e
//      当alusrc_e=1时，将rs1_val_e写到srca_e
//      当alusrc_e=2时，将pc_e写到srca_e

module srca_mux (
    input  logic [63:0] rs1_val_e,
    input  logic [1:0]  alusrca_e,
    input  logic [63:0] pc_e,
    output logic [63:0] srca_e
);

always_comb begin
    case (alusrca_e)
        2'd0:    srca_e = 64'd0;
        2'd1:    srca_e = rs1_val_e;
        2'd2:    srca_e = pc_e;
        default: srca_e = 64'd0;
    endcase
end

endmodule
