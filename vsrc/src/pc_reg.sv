//现在的实现没有使用它了，不过先保留一下吧。

//模块名称:pc_reg
//接口:input logic reset
//     input logic [63:0] pcinit
//     input logic [63:0] pc_next
//     input logic clk
//     input logic pc_en
//     output logic [63:0] pc
//功能：每一拍时钟，当reset为1时，将pcinit的值写入 pc。
//      当reset为0，且pc_en=1时，将pc_next的值写入pc。

module pc_reg (
    input  logic        reset,
    input  logic [63:0] pcinit,
    input  logic [63:0] pc_next,
    input  logic        clk,
    input  logic        pc_en,
    output logic [63:0] pc
);

    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= pcinit;
        end
        else if (pc_en) begin
            pc <= pc_next;
        end
    end

endmodule
