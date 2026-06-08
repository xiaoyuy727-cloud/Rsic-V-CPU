//模块名称：saf_unit
//接口：input logic mem_stall
//      input logic redirect_valid
//      input logic is_ecall
//      input logic is_mret
//      output logic pc_stall
//      output logic if_id_stall
//      output logic id_ex_stall
//      output logic ex_mem_stall
//      output logic mem_wb_stall
//      output logic if_id_flush
//      output logic id_ex_flush
//功能：将memstall的值写给所有output的stall信号。
//同时，如果redirect_valid是1，将ifid和idex的flush写为1.

module saf_unit (
    input  logic mem_stall,
    input  logic redirect_valid,
    input  logic load_use_stall,
    input  logic is_ecall,
    input  logic is_mret,

    input logic swint,
    input logic trint,
    input logic exint,

    input logic iaddr_exc_w,
    input logic daddr_exc_w,


    output logic pc_stall,
    output logic if_id_stall,
    output logic id_ex_stall,
    output logic ex_mem_stall,
    output logic mem_wb_stall,
    output logic if_id_flush,
    output logic id_ex_flush,
    output logic ex_mem_flush,
    output logic mem_wb_flush
);
    logic interrupt,exception;
    assign interrupt = swint | trint | exint;
    assign exception = is_ecall | iaddr_exc_w | daddr_exc_w;

    always_comb begin
        pc_stall     = mem_stall | load_use_stall;
        
        if_id_stall  = mem_stall | load_use_stall;
        id_ex_stall  = mem_stall;
        ex_mem_stall = mem_stall;
        mem_wb_stall = mem_stall;

        if_id_flush  = redirect_valid | interrupt | exception | is_mret ;
        id_ex_flush  = redirect_valid | load_use_stall | interrupt | exception | is_mret;
        ex_mem_flush  = interrupt | exception | is_mret;
        mem_wb_flush  = interrupt | exception | is_mret;



    end

endmodule