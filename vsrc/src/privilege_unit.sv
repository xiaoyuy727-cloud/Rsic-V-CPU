// 模块名称：privilege_unit
//
// 功能：维护当前 privilege mode
//
// trap:
//     mode <- M
//
// mret:
//     mode <- mpp
//
module privilege_unit (
    input  logic clk,
    input  logic rst,

    input  logic trap_valid,
    input  logic mret_valid,

    input  logic [1:0] mpp,

    output logic [1:0] privil_mode
);

    localparam logic [1:0] PRIV_U = 2'b00;
    localparam logic [1:0] PRIV_S = 2'b01;
    localparam logic [1:0] PRIV_M = 2'b11;

    always_ff @(posedge clk) begin
        if (rst) begin
            privil_mode <= PRIV_M;
        end
        else begin
            if (trap_valid) begin
                privil_mode <= PRIV_M;
            end
            else if (mret_valid) begin
                privil_mode <= mpp;
            end
        end
    end

endmodule