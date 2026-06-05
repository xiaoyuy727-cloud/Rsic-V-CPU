//模块名称：final_redirect_pc_unit
//接口
//input logic [63:0] branch_redirect_pc
//input logic [63:0] csr_mepc
//input logic [63:0] csr_mtvec
//input logic is_ecall
//input logic is_mret
//output logic [63:0] final_redirect_pc
//功能：如果是ecall，输出mtvec，如果是mret，输出mepc，否则输出branch_redirect_pc

module final_redirect_pc_unit(

    input logic [63:0] branch_redirect_pc,
    input logic [63:0] csr_mepc,
    input logic [63:0] csr_mtvec,
    input logic is_ecall,
    input logic is_mret,
    output logic [63:0] final_redirect_pc 

    input logic swint,
    input logic trint,
    input logic exint,

    input logic iaddr_exc_w,
    input logic daddr_exc_w
  
);

    logic interrupt,exception;
    assign interrupt = swint | trint | exint;
    assign exception = is_ecall | iaddr_exc_w | daddr_exc_w;

    always_comb begin

            if(interruption | exception)begin
                // to do
                final_redirect_pc = csr_mtvec;
            end else if (is_mret) begin
                final_redirect_pc = csr_mepc;
            end else begin
                final_redirect_pc = branch_redirect_pc;
            end

    end

endmodule