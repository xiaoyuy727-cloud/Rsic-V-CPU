// 模块名称：saf_unit
// 功能：统一生成流水线 stall / flush
//
// 语义：
//   mem_stall       ：全流水线保持
//   load_use_stall  ：PC、IF/ID stall，同时 ID/EX 插 bubble
//   branch_redirect ：清 IF/ID、ID/EX
//   trap/mret       ：清 IF/ID、ID/EX、EX/MEM，
//                    不清 MEM/WB，避免把正在提交的 trap/mret 自己刷掉
module saf_unit (
    input  logic mem_stall,
    input  logic load_use_stall,

    input  logic branch_redirect_valid,
    input  logic trap_valid,
    input  logic mret_valid,
    input  logic mdu_stall,
    input  logic sret_valid,

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

`ifdef VERILAT

always_comb begin
    if (mem_stall || mdu_stall || load_use_stall) begin
        $display(
"[SAF] mem_stall=%b mdu_stall=%b load_use_stall=%b | stall pc=%b ifid=%b idex=%b exmem=%b memwb=%b | flush ifid=%b idex=%b exmem=%b memwb=%b",
            mem_stall, mdu_stall, load_use_stall,
            pc_stall, if_id_stall, id_ex_stall, ex_mem_stall, mem_wb_stall,
            if_id_flush, id_ex_flush, ex_mem_flush, mem_wb_flush
        );
    end
end

`endif


    logic control_redirect;
    logic commit_redirect;

    assign control_redirect = branch_redirect_valid | trap_valid | mret_valid | sret_valid;
    assign commit_redirect  = trap_valid | mret_valid | sret_valid;

    always_comb begin



pc_stall     = mdu_stall | mem_stall | load_use_stall;

if_id_stall  = mdu_stall | mem_stall | load_use_stall;
id_ex_stall  = mdu_stall | mem_stall;

ex_mem_stall = mdu_stall | mem_stall;
mem_wb_stall = mem_stall;

        //====================================================
        // Flush
        //====================================================
        if_id_flush  = control_redirect;
        id_ex_flush  = branch_redirect_valid | load_use_stall | commit_redirect;

        // trap/mret 在 W 阶段提交，需要清掉更年轻指令。
        // 不清 MEM/WB，避免当前 W 阶段事件被自己清掉。
        ex_mem_flush = commit_redirect;
        mem_wb_flush = 1'b0;
    end

endmodule