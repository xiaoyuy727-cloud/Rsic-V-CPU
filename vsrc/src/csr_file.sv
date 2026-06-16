`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`endif

module csr_file import common::*; import csr_pkg::*;(
    input logic clk,
    input logic reset,

    input logic [31:0] instr_d,
    input logic [31:0] instr_w,

    input logic [11:0] new_csr_num,
    input logic [63:0] new_csr_value,
    input logic        csrwrite,

    input logic        trap_valid,
    input logic        trap_is_interrupt,
    input logic [63:0] trap_cause,
    input logic [63:0] trap_pc,
    input logic [1:0]  trap_priv,

    input logic        mret_valid,

    input logic swint,
    input logic trint,
    input logic exint,

    input logic [1:0] trap_target_priv,
    input logic       sret_valid,

    output logic [63:0] csr_value,
    output logic [11:0] csr_num,

    output logic [63:0] csr_mstatus,
    output logic [63:0] csr_mtvec,
    output logic [63:0] csr_mip,
    output logic [63:0] csr_mie,
    output logic [63:0] csr_mscratch,
    output logic [63:0] csr_mcause,
    output logic [63:0] csr_mtval,
    output logic [63:0] csr_mepc,
    output logic [63:0] csr_mcycle,
    output logic [63:0] csr_mhartid,
    output logic [63:0] csr_satp,

    output logic [63:0] csr_medeleg,
    output logic [63:0] csr_mideleg,
    output logic [63:0] csr_stvec,
    output logic [63:0] csr_sscratch,
    output logic [63:0] csr_sepc,
    output logic [63:0] csr_scause,
    output logic [63:0] csr_stval,
    output logic [63:0] csr_sstatus,
    output logic [63:0] csr_sie,
    output logic [63:0] csr_sip
);

    assign csr_num = instr_d[31:20];

    assign csr_sstatus = csr_mstatus & SSTATUS_MASK;
    assign csr_sie     = csr_mie     & S_INT_MASK;
    assign csr_sip     = csr_mip     & S_INT_MASK;

    always_comb begin
        unique case (csr_num)
            CSR_MHARTID:  csr_value = csr_mhartid;
            CSR_MSTATUS:  csr_value = csr_mstatus;
            CSR_MIE:      csr_value = csr_mie;
            CSR_MIP:      csr_value = csr_mip;
            CSR_MTVEC:    csr_value = csr_mtvec;
            CSR_MSCRATCH: csr_value = csr_mscratch;
            CSR_MEPC:     csr_value = csr_mepc;
            CSR_MCAUSE:   csr_value = csr_mcause;
            CSR_MTVAL:    csr_value = csr_mtval;
            CSR_MCYCLE:   csr_value = csr_mcycle;
            CSR_SATP:     csr_value = csr_satp;

            CSR_MEDELEG:  csr_value = csr_medeleg;
            CSR_MIDELEG:  csr_value = csr_mideleg;
            CSR_STVEC:    csr_value = csr_stvec;
            CSR_SSTATUS:  csr_value = csr_sstatus;
            CSR_SSCRATCH: csr_value = csr_sscratch;
            CSR_SEPC:     csr_value = csr_sepc;
            CSR_SCAUSE:   csr_value = csr_scause;
            CSR_STVAL:    csr_value = csr_stval;
            CSR_SIE:      csr_value = csr_sie;
            CSR_SIP:      csr_value = csr_sip;

            default:      csr_value = 64'b0;
        endcase
    end

    logic [63:0] old_value;
    logic [63:0] write_value;

    always_comb begin
        unique case (new_csr_num)
            CSR_MHARTID:  old_value = csr_mhartid;
            CSR_MSTATUS:  old_value = csr_mstatus;
            CSR_MIE:      old_value = csr_mie;
            CSR_MIP:      old_value = csr_mip;
            CSR_MTVEC:    old_value = csr_mtvec;
            CSR_MSCRATCH: old_value = csr_mscratch;
            CSR_MEPC:     old_value = csr_mepc;
            CSR_MCAUSE:   old_value = csr_mcause;
            CSR_MTVAL:    old_value = csr_mtval;
            CSR_MCYCLE:   old_value = csr_mcycle;
            CSR_SATP:     old_value = csr_satp;

            CSR_MEDELEG:  old_value = csr_medeleg;
            CSR_MIDELEG:  old_value = csr_mideleg;
            CSR_STVEC:    old_value = csr_stvec;
            CSR_SSTATUS:  old_value = csr_sstatus;
            CSR_SSCRATCH: old_value = csr_sscratch;
            CSR_SEPC:     old_value = csr_sepc;
            CSR_SCAUSE:   old_value = csr_scause;
            CSR_STVAL:    old_value = csr_stval;
            CSR_SIE:      old_value = csr_sie;
            CSR_SIP:      old_value = csr_sip;

            default:      old_value = 64'b0;
        endcase
    end

    always_comb begin
        unique case (instr_w[14:12])
            3'b001, 3'b101: write_value = new_csr_value;
            3'b010, 3'b110: write_value = old_value | new_csr_value;
            3'b011, 3'b111: write_value = old_value & ~new_csr_value;
            default:        write_value = old_value;
        endcase
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            csr_mhartid  <= 64'b0;
            csr_mstatus  <= 64'b0;
            csr_mie      <= 64'b0;
            csr_mip      <= 64'b0;
            csr_mtvec    <= 64'b0;
            csr_mscratch <= 64'b0;
            csr_mepc     <= 64'b0;
            csr_mcause   <= 64'b0;
            csr_mtval    <= 64'b0;
            csr_mcycle   <= 64'b0;
            csr_satp     <= 64'b0;

            csr_medeleg  <= 64'b0;
            csr_mideleg  <= 64'b0;
            csr_stvec    <= 64'b0;
            csr_sscratch <= 64'b0;
            csr_sepc     <= 64'b0;
            csr_scause   <= 64'b0;
            csr_stval    <= 64'b0;
        end
        else begin
            csr_mcycle <= csr_mcycle + 64'd1;

            csr_mip[3]  <= swint;
            csr_mip[7]  <= trint;
            csr_mip[11] <= exint;

            if (trap_valid) begin
                unique case (trap_target_priv)
                    PRIV_S: begin
                        csr_sepc   <= trap_pc;
                        csr_scause <= {trap_is_interrupt, trap_cause[62:0]};
                        csr_stval  <= 64'b0;

                        csr_mstatus[8] <= trap_priv[0];   // SPP
                        csr_mstatus[5] <= csr_mstatus[1]; // SPIE <= SIE
                        csr_mstatus[1] <= 1'b0;           // SIE = 0
                    end

                    default: begin
                        csr_mepc   <= trap_pc;
                        csr_mcause <= {trap_is_interrupt, trap_cause[62:0]};
                        csr_mtval  <= 64'b0;

                        csr_mstatus[12:11] <= trap_priv;      // MPP
                        csr_mstatus[7]     <= csr_mstatus[3]; // MPIE <= MIE
                        csr_mstatus[3]     <= 1'b0;           // MIE = 0
                    end
                endcase
            end
            else if (mret_valid) begin
                csr_mstatus[3]     <= csr_mstatus[7];
                csr_mstatus[7]     <= 1'b1;
                csr_mstatus[12:11] <= 2'b00;
                csr_mstatus[16:15] <= 2'b00;
            end
            else if (sret_valid) begin
                csr_mstatus[1] <= csr_mstatus[5]; // SIE <= SPIE
                csr_mstatus[5] <= 1'b1;           // SPIE <= 1
                csr_mstatus[8] <= 1'b0;           // SPP <= U
            end
            else if (csrwrite) begin
                unique case (new_csr_num)
                    CSR_MSTATUS: begin
                        csr_mstatus <= write_value & MSTATUS_MASK;
                    end

                    CSR_MIE: begin
                        csr_mie <= write_value;
                    end

                    CSR_MIP: begin
                        csr_mip     <= write_value & MIP_MASK;
                        csr_mip[3]  <= swint;
                        csr_mip[7]  <= trint;
                        csr_mip[11] <= exint;
                    end

                    CSR_MTVEC: begin
                        csr_mtvec <= write_value & MTVEC_MASK;
                    end

                    CSR_MSCRATCH: begin
                        csr_mscratch <= write_value;
                    end

                    CSR_MEPC: begin
                        csr_mepc <= write_value;
                    end

                    CSR_MCAUSE: begin
                        csr_mcause <= write_value;
                    end

                    CSR_MTVAL: begin
                        csr_mtval <= write_value;
                    end

                    CSR_MCYCLE: begin
                        csr_mcycle <= write_value;
                    end

                    CSR_SATP: begin
                        csr_satp <= write_value;
                    end

                    CSR_MEDELEG: begin
                        csr_medeleg <= write_value & MEDELEG_MASK;
                    end

                    CSR_MIDELEG: begin
                        csr_mideleg <= write_value & MIDELEG_MASK;
                    end

                    CSR_STVEC: begin
                        csr_stvec <= write_value & MTVEC_MASK;
                    end

                    CSR_SSTATUS: begin
                        csr_mstatus <= (csr_mstatus & ~SSTATUS_MASK)
                                     | (write_value  &  SSTATUS_MASK);
                    end

                    CSR_SSCRATCH: begin
                        csr_sscratch <= write_value;
                    end

                    CSR_SEPC: begin
                        csr_sepc <= write_value;
                    end

                    CSR_SCAUSE: begin
                        csr_scause <= write_value;
                    end

                    CSR_STVAL: begin
                        csr_stval <= write_value;
                    end

                    CSR_SIE: begin
                        csr_mie <= (csr_mie & ~S_INT_MASK)
                                 | (write_value & S_INT_MASK);
                    end

                    CSR_SIP: begin
                        csr_mip <= (csr_mip & ~S_INT_MASK)
                                 | (write_value & S_INT_MASK);

                        csr_mip[3]  <= swint;
                        csr_mip[7]  <= trint;
                        csr_mip[11] <= exint;
                    end

                    default: ;
                endcase
            end
        end
    end

`ifdef DEBUG
    always_ff @(posedge clk) begin
        if (!reset) begin
            if (trap_valid) begin
                $display("[CSR_TRAP] trap_pc=%h instr_w=%h cause=%h interrupt=%b trap_priv=%b mstatus_before=%h",
                    trap_pc, instr_w, trap_cause, trap_is_interrupt, trap_priv, csr_mstatus);
            end

            if (mret_valid) begin
                $display("[CSR_MRET] instr_w=%h csr_mepc=%h csr_mstatus=%h mpp=%b",
                    instr_w, csr_mepc, csr_mstatus, csr_mstatus[12:11]);
            end

            if (csrwrite && new_csr_num == CSR_MEPC) begin
                $display("[CSR_WRITE_MEPC] instr_w=%h new_csr_value=%h write_value=%h old_mepc=%h",
                    instr_w, new_csr_value, write_value, csr_mepc);
            end

            if (csrwrite && new_csr_num == CSR_SATP) begin
                $display("[CSR_WRITE_SATP] instr_w=%h new_csr_value=%h write_value=%h old_satp=%h",
                    instr_w, new_csr_value, write_value, csr_satp);
            end
        end
    end
`endif

endmodule