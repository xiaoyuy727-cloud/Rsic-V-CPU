//模块名称：if_id_reg
//接口：input logic [31:0] instr_f
//      input logic clk
//      input logic fetch_ok
//      input logic [63:0] pc_f
//      input logic reset
//      input logic if_id_stall
//      input logic flush
//      output logic [31:0] instr_d
//      output logic valid_d
//      output logic [63:0] pc_d
//功能：如果reset为1，那么全部归0。
//      如果flush为1，那么全部归0。
//每一拍，当fetch_ok为1且stall为0时，说明取到有效指令，将instr_f更新写到instr_d.pc_f写到pc_d，1写到valid_d
//       如果fetch_ok为0，valid为0.

module if_id_reg (
    input  logic [31:0] instr_f,
    input  logic        clk,
    input  logic        fetch_ok,
    input  logic [63:0] pc_f,
    input  logic        reset,
    input  logic        if_id_stall,
    input  logic        flush,
    input  logic        iaddr_exc_f,

    output logic        iaddr_exc_d,

    output logic [31:0] instr_d,
    output logic        valid_d,
    output logic [63:0] pc_d
);
`ifdef VERILATOR
longint dbg_cycle;
always_ff @(posedge clk) begin
    if (reset) begin
        dbg_cycle <= 0;
    end else begin
        dbg_cycle <= dbg_cycle + 1;
    
        if ((dbg_cycle >= 1288) && (dbg_cycle <= 1320)) begin

        if (if_id_stall && fetch_ok) begin
            $display(
                "[IFID_HOLD_WITH_FETCH_OK] fetch_ok=%b stall=%b pc_f=%h instr_f=%h pc_d=%h instr_d=%h valid_d=%b",
                fetch_ok,
                if_id_stall,
                pc_f,
                instr_f,
                pc_d,
                instr_d,
                valid_d
            );
        end

        if (!if_id_stall && fetch_ok) begin
            $display(
                "[IFID_ACCEPT] pc_f=%h instr_f=%h old_pc_d=%h old_instr_d=%h old_valid_d=%b",
                pc_f,
                instr_f,
                pc_d,
                instr_d,
                valid_d
            );
        end

        end
    end
end
`endif




    always_ff @(posedge clk) begin
        if (reset) begin
            instr_d <= 32'b0;
            valid_d <= 1'b0;
            pc_d    <= 64'b0;
            iaddr_exc_d <= 1'b0;
        end
        else if (flush) begin
            instr_d <= 32'b0;
            valid_d <= 1'b0;
            pc_d    <= 64'b0;
            iaddr_exc_d <= 1'b0;
        end
        else if (!if_id_stall) begin
            if (fetch_ok) begin
                instr_d <= instr_f;
                pc_d    <= pc_f;
                valid_d <= 1'b1;
                iaddr_exc_d <= iaddr_exc_f;
            end
            else begin
                instr_d <= 32'b0;
                pc_d    <= 64'b0;
                valid_d <= 1'b0;
                iaddr_exc_d <= 1'b0;
            end
        end
    end

endmodule