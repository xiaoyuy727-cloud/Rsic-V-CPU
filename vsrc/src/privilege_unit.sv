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
module privilege_unit import common ::*;(
    input  logic clk,
    input  logic rst,

    input  logic trap_valid,
    input  logic mret_valid,

    input  logic [1:0] mpp,
    input logic [1:0] trap_target_priv,
    input logic       sret_valid,
    input logic       spp,

    output logic [1:0] privil_mode
);


    always_ff @(posedge clk) begin
        if (rst) begin
            privil_mode <= PRIV_M;
        end
        else begin
            if (trap_valid) begin
                privil_mode <= trap_target_priv;
            end
            else if (mret_valid) begin
                privil_mode <= mpp;
            end
            else if (sret_valid) begin
                privil_mode <= spp ? PRIV_S : PRIV_U;
            end
        end
    end

endmodule