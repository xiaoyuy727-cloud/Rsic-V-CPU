//模块名称：stall_unit
//接口：input logic mem_stall
//      output logic pc_stall
//      output logic if_id_stall
//      output logic id_ex_stall
//      output logic ex_mem_stall
//      output logic mem_wb_stall
//功能：将memstall的值写给所有output的stall信号。

module stall_unit (
    input  logic mem_stall,
    output logic pc_stall,
    output logic if_id_stall,
    output logic id_ex_stall,
    output logic ex_mem_stall,
    output logic mem_wb_stall
);

    always_comb begin
        pc_stall     = mem_stall;
        if_id_stall  = mem_stall;
        id_ex_stall  = mem_stall;
        ex_mem_stall = mem_stall;
        mem_wb_stall = mem_stall;
    end

endmodule