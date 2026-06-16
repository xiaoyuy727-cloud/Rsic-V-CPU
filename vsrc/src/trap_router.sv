`ifdef VERILATOR
`include "include/common.sv"
`endif

module trap_router import common::*; (
    input  logic        trap_valid,
    input  logic        trap_is_interrupt,
    input  logic [63:0] trap_cause,

    input  logic [1:0]  current_priv,

    input  logic [63:0] csr_medeleg,
    input  logic [63:0] csr_mideleg,

    output logic [1:0]  trap_target_priv
);

    always_comb begin
        trap_target_priv = PRIV_M;

        if (trap_valid && current_priv != PRIV_M) begin
            if (trap_is_interrupt) begin
                if (csr_mideleg[trap_cause[5:0]]) begin
                    trap_target_priv = PRIV_S;
                end
            end
            else begin
                if (csr_medeleg[trap_cause[5:0]]) begin
                    trap_target_priv = PRIV_S;
                end
            end
        end
    end

endmodule