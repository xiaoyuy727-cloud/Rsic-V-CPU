//模块名称：if_id_reg
//接口：input logic [31:0] instr_f
//      input logic clk
//      input logic fetch_ok
//      input logic [63:0] pc_f
//      input logic reset
//      input logic if_id_stall
//      output logic [31:0] instr_d
//      output logic valid_d
//      output logic [63:0] pc_d
//功能：如果reset为1，那么全部归0。
//每一拍，当fetch_ok为1且stall为0时，说明取到有效指令，将instr_f更新写到instr_d.pc_f写到pc_d，1写到valid_d
//       如果fetch_ok为0，valid为0.

module if_id_reg (
    input  logic [31:0] instr_f,
    input  logic        clk,
    input  logic        reset,
    input  logic        fetch_ok,
    input  logic [63:0] pc_f,
    input  logic        if_id_stall,

    output logic        valid_d,
    output logic [63:0] pc_d,
    output logic [31:0] instr_d
);

    always_ff @(posedge clk) begin
        if (reset) begin
            instr_d <= 32'b0;
            pc_d    <= 64'b0;
            valid_d <= 1'b0;
        end
        else if (!if_id_stall) begin
            if (fetch_ok) begin
                instr_d <= instr_f;
                pc_d    <= pc_f;
                valid_d <= 1'b1;
            end
            else begin
                valid_d <= 1'b0;
            end
        end
    end

endmodule
