//模块名称：reg_file
//接口： input logic [4:0] rs1
//      input logic [4:0] rs2
//      input logic [63:0] writedata
//      input logic [4:0] rd
//      input logic regwrite
//      input logic clk
//      output logic [63:0] rs1_val_d
//      output logic [63:0] rs2_val_d
//      output logic [63:0] test_reg_x0
//      output logic [63:0] test_reg_x1
//      output logic [63:0] test_reg_x2
//      output logic [63:0] test_reg_x3
//      output logic [63:0] test_reg_x4
//      output logic [63:0] test_reg_x5
//      output logic [63:0] test_reg_x6
//      output logic [63:0] test_reg_x7
//      output logic [63:0] test_reg_x8
//      output logic [63:0] test_reg_x9
//      output logic [63:0] test_reg_x10
//      output logic [63:0] test_reg_x11
//      output logic [63:0] test_reg_x12
//      output logic [63:0] test_reg_x13
//      output logic [63:0] test_reg_x14
//      output logic [63:0] test_reg_x15
//      output logic [63:0] test_reg_x16
//      output logic [63:0] test_reg_x17
//      output logic [63:0] test_reg_x18
//      output logic [63:0] test_reg_x19
//      output logic [63:0] test_reg_x20
//      output logic [63:0] test_reg_x21
//      output logic [63:0] test_reg_x22
//      output logic [63:0] test_reg_x23
//      output logic [63:0] test_reg_x24
//      output logic [63:0] test_reg_x25
//      output logic [63:0] test_reg_x26
//      output logic [63:0] test_reg_x27
//      output logic [63:0] test_reg_x28
//      output logic [63:0] test_reg_x29
//      output logic [63:0] test_reg_x30
//      output logic [63:0] test_reg_x31

//功能：保存32个寄存器的值，[63:0] reg_x0一直到[63:0] reg_x31
//reset为高电平的时候全部清零。
//组合地将rs1对应编号的值输出写到rs1_val_d，将rs2对应编号的值输出写到rs2_val_d
//每一个时钟上升沿，当regwrite为1时，将writedata写入rd对应编号的寄存器。但是当rd为0时，不写入。
//组合地将32个寄存器的值对应写入test_reg

module reg_file(
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [63:0] writedata,
    input  logic [4:0]  rd,
    input  logic        regwrite,
    input  logic        clk,
    input  logic        reset,

    output logic [63:0] rs1_val_d,
    output logic [63:0] rs2_val_d,

    output logic [63:0] test_reg_x0,
    output logic [63:0] test_reg_x1,
    output logic [63:0] test_reg_x2,
    output logic [63:0] test_reg_x3,
    output logic [63:0] test_reg_x4,
    output logic [63:0] test_reg_x5,
    output logic [63:0] test_reg_x6,
    output logic [63:0] test_reg_x7,
    output logic [63:0] test_reg_x8,
    output logic [63:0] test_reg_x9,
    output logic [63:0] test_reg_x10,
    output logic [63:0] test_reg_x11,
    output logic [63:0] test_reg_x12,
    output logic [63:0] test_reg_x13,
    output logic [63:0] test_reg_x14,
    output logic [63:0] test_reg_x15,
    output logic [63:0] test_reg_x16,
    output logic [63:0] test_reg_x17,
    output logic [63:0] test_reg_x18,
    output logic [63:0] test_reg_x19,
    output logic [63:0] test_reg_x20,
    output logic [63:0] test_reg_x21,
    output logic [63:0] test_reg_x22,
    output logic [63:0] test_reg_x23,
    output logic [63:0] test_reg_x24,
    output logic [63:0] test_reg_x25,
    output logic [63:0] test_reg_x26,
    output logic [63:0] test_reg_x27,
    output logic [63:0] test_reg_x28,
    output logic [63:0] test_reg_x29,
    output logic [63:0] test_reg_x30,
    output logic [63:0] test_reg_x31
);

    logic [63:0] regs [31:0];
    integer i;

    // 时序写 + reset 清零
    always_ff @(posedge clk) begin
        if (reset == 1'b1) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 64'd0;
        end else begin
            if (regwrite == 1'b1 && rd != 5'd0)
                regs[rd] <= writedata;
        end
    end

    // 组合读：x0 恒为 0
    always_comb begin
        if (rs1 == 5'd0)
            rs1_val_d = 64'd0;
        else
            rs1_val_d = regs[rs1];

        if (rs2 == 5'd0)
            rs2_val_d = 64'd0;
        else
            rs2_val_d = regs[rs2];
    end

    // 调试输出：x0 恒为 0
    assign test_reg_x0  = 64'd0;
    assign test_reg_x1  = regs[1];
    assign test_reg_x2  = regs[2];
    assign test_reg_x3  = regs[3];
    assign test_reg_x4  = regs[4];
    assign test_reg_x5  = regs[5];
    assign test_reg_x6  = regs[6];
    assign test_reg_x7  = regs[7];
    assign test_reg_x8  = regs[8];
    assign test_reg_x9  = regs[9];
    assign test_reg_x10 = regs[10];
    assign test_reg_x11 = regs[11];
    assign test_reg_x12 = regs[12];
    assign test_reg_x13 = regs[13];
    assign test_reg_x14 = regs[14];
    assign test_reg_x15 = regs[15];
    assign test_reg_x16 = regs[16];
    assign test_reg_x17 = regs[17];
    assign test_reg_x18 = regs[18];
    assign test_reg_x19 = regs[19];
    assign test_reg_x20 = regs[20];
    assign test_reg_x21 = regs[21];
    assign test_reg_x22 = regs[22];
    assign test_reg_x23 = regs[23];
    assign test_reg_x24 = regs[24];
    assign test_reg_x25 = regs[25];
    assign test_reg_x26 = regs[26];
    assign test_reg_x27 = regs[27];
    assign test_reg_x28 = regs[28];
    assign test_reg_x29 = regs[29];
    assign test_reg_x30 = regs[30];
    assign test_reg_x31 = regs[31];

endmodule