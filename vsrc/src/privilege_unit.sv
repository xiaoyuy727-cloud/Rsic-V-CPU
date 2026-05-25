//模块名称 privilege_unit
//接口
//input logic is_mret,
//input logic is_ecall,
//input logic [1:0] mpp,
//output logic [1:0] privil_mode
//功能：u/s/m 0/1/3
//功能：每一拍，当is_mret为1，将mpp写给privil_mode。当is_ecall为1，将0写给privil_mode

module privilege_unit (
    input logic clk,
    input logic rst,
    input logic is_mret,
    input logic is_ecall,
    input logic [1:0] mpp,
    output logic [1:0] privil_mode
);
    localparam logic [1:0] PRIV_U=2'b00;
    localparam logic [1:0] PRIV_S=2'b01;
    localparam logic [1:0] PRIV_M=2'b11;

    always_ff @(posedge clk)begin
        if(rst) begin
            privil_mode<=PRIV_M;
        end else begin
            if(is_mret) begin
                privil_mode<=mpp;
            end else if(is_ecall) begin
                privil_mode<=PRIV_M;
            end
        end
    end

endmodule

