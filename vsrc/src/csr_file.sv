`ifdef VERILATOR
`include "include/common.sv"
`include "include/csr.sv"
`endif

//模块名称：csr_file
//模块接口
//input logic [31:0]instr
//input logic [11:0]new_csr_num
//input logic [63:0] new_csr_value
//input logic csrwrite
//output logic [63:0] csr_value
//output logic [11:0] csr_num

//模块功能：读取instr,将[31:20]位写入csr_num，将这个csr号对应的寄存器的值写入csr_value
//当csrwrite为1时，考虑instr[14:12]。
//                如果为001/101，将new_csr_value写入new_csr_num对应的寄存器。
//                如果为010/110，将new_csr_value中为1的位在new_csr_num对应的寄存器中置为1。
//                如果为011/111，将new_csr_value中为1的位在new_csr_num对应的寄存器中置为0。


module csr_file import common::*;import csr_pkg::*;(
    input logic clk,
    input logic reset,
    input logic [31:0]instr_d,
    input logic [31:0]instr_w,
    input logic [11:0]new_csr_num,
    input logic [63:0] new_csr_value,
    input logic csrwrite,
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
    output logic [63:0] csr_satp    
);



    //output部分
    assign csr_num=instr_d[31:20];

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
            default:      csr_value = 64'b0;
        endcase
    end

    //input部分
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
            default:      old_value = 64'b0;
        endcase
    end

    always_comb begin
        unique case (instr_w[14:12])
            3'b001, 3'b101: begin
                // CSRRW / CSRRWI
                write_value = new_csr_value;
            end

            3'b010, 3'b110: begin
                // CSRRS / CSRRSI
                write_value = old_value | new_csr_value;
            end

            3'b011, 3'b111: begin
                // CSRRC / CSRRCI
                write_value = old_value & ~new_csr_value;
            end

            default: begin
                write_value = old_value;
            end
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
        end else begin
            csr_mcycle <= csr_mcycle + 64'd1;

            if (csrwrite) begin
                unique case (new_csr_num)
                    CSR_MSTATUS:  csr_mstatus  <= write_value & MSTATUS_MASK;
                    CSR_MIE:      csr_mie      <= write_value;
                    CSR_MIP:      csr_mip      <= write_value & MIP_MASK;
                    CSR_MTVEC:    csr_mtvec    <= write_value & MTVEC_MASK;
                    CSR_MSCRATCH: csr_mscratch <= write_value;
                    CSR_MEPC:     csr_mepc     <= write_value;
                    CSR_MCAUSE:   csr_mcause   <= write_value;
                    CSR_MTVAL:    csr_mtval    <= write_value;
                    CSR_MCYCLE:   csr_mcycle   <= write_value;
                    CSR_SATP:     csr_satp     <= write_value;

                    default: ;
                endcase
            end
        end
    end

endmodule