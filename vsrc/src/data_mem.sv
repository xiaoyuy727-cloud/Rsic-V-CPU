`include "include/common.sv"
import common::*;

//模块名称：data_mem
//接口：input logic [63:0] address
//      input logic [63:0] mem_write_data
//      input logic mem_write_m
//      input logic mem_read_m
//      input logic [1:0] mem_digit_m (0则8个bit，1则16个bit，2则32个bit，3则64个bit)
//      input logic mem_sign_m  (1时零扩展，0时符号扩展)
//      output logic [63:0] mem_read_data
//      output logic mem_stall

//功能：
//     当mem_write_m为1时，将mem_write_data写到mem[addr]。具体写的规则如下：
//              如果mem_digit_m是0，那么将mem_write_data0-7位的8个bit数据，写到mem[address]中。
//              如果mem_digit_m是1，那么将mem_write_data0-15位的16个bit数据，写到mem[address]和mem[address+1]中。
//              如果mem_digit_m是2，那么将mem_write_data0-31位的32个bit数据，写到mem[address]到mem[address+3]中。
//              如果mem_digit_m是3，那么将mem_write_data0-63位的64个bit数据，写到mem[address]到mem[address+7]中。
//     在这种情况下，如果dataok是0，那么一直锁住所有流水寄存器和pc，也就是将memstall一直置为1.
//     当mem_read_m为1时，将mem[address]的数据存入rd。具体存放规则如下：
//              如果mem_digit_m是0，那么读mem[address]中8个bit的数据。在此基础上，如果mem_sign_m是1，零扩展，否则符号扩展到64位，写到mem_read_data
//              如果mem_digit_m是1，那么读mem[address]和mem[address+1]中16个bit的数据。在此基础上，如果mem_sign_m是1，零扩展，否则符号扩展到64位，写到mem_read_data
//              如果mem_digit_m是2，那么读mem[address]到mem[address+3]中32个bit的数据。在此基础上，如果mem_sign_m是1，零扩展，否则符号扩展到64位，写到mem_read_data
//              如果mem_digit_m是3，那么读mem[address]到mem[address+7]中64个bit的数据。在此基础上，如果mem_sign_m是1，零扩展，否则符号扩展到64位，写到mem_read_data
//     在这种情况下，如果dataok是0，那么一直锁住所有流水寄存器和pc，也就是将memstall一直置为1.



module data_mem (
    input  logic [63:0] address,
    input  logic [63:0] mem_write_data,
    input  logic        mem_write_m,
    input  logic        mem_read_m,
    input  logic [1:0]  mem_digit_m,    // 0:8bit, 1:16bit, 2:32bit, 3:64bit
    input  logic        mem_sign_m,     // 1:零扩展, 0:符号扩展

    input  dbus_resp_t  dresp,
    output dbus_req_t   dreq,

    output logic [63:0] mem_read_data,
    output logic        mem_stall
);

    logic [2:0]  offset;
    logic [7:0]  base_strobe;
    logic [63:0] shifted_rdata;

    assign offset = address[2:0];

    // 只要当前是读/写访存，且 data_ok 还没到，就要求流水线 stall
    assign mem_stall = (mem_read_m | mem_write_m) & (~dresp.data_ok);

    // 把返回的 64bit 数据按地址低 3 位右移到最低位
    assign shifted_rdata = dresp.data >> (offset * 8);

    // 生成 dbus 请求
    always_comb begin
        dreq.valid  = mem_read_m | mem_write_m;
        dreq.addr   = address;
        dreq.size   = MSIZE1;
        dreq.strobe = 8'b0;
        dreq.data   = 64'b0;
        base_strobe = 8'b0;

        // size
        case (mem_digit_m)
            2'd0: dreq.size = MSIZE1;
            2'd1: dreq.size = MSIZE2;
            2'd2: dreq.size = MSIZE4;
            2'd3: dreq.size = MSIZE8;
            default: dreq.size = MSIZE1;
        endcase

        // 写请求时，设置 strobe 和 data
        if (mem_write_m) begin
            case (mem_digit_m)
                2'd0: base_strobe = 8'b0000_0001; // 1 byte
                2'd1: base_strobe = 8'b0000_0011; // 2 byte
                2'd2: base_strobe = 8'b0000_1111; // 4 byte
                2'd3: base_strobe = 8'b1111_1111; // 8 byte
                default: base_strobe = 8'b0000_0000;
            endcase

            dreq.strobe = base_strobe << offset;
            dreq.data   = mem_write_data << (offset * 8);
        end
    end

    // 读回数据并扩展
    always_comb begin
        mem_read_data = 64'b0;

        case (mem_digit_m)
            // 8 bit
            2'd0: begin
                if (mem_sign_m) begin
                    mem_read_data = {56'b0, shifted_rdata[7:0]};
                end else begin
                    mem_read_data = {{56{shifted_rdata[7]}}, shifted_rdata[7:0]};
                end
            end

            // 16 bit
            2'd1: begin
                if (mem_sign_m) begin
                    mem_read_data = {48'b0, shifted_rdata[15:0]};
                end else begin
                    mem_read_data = {{48{shifted_rdata[15]}}, shifted_rdata[15:0]};
                end
            end

            // 32 bit
            2'd2: begin
                if (mem_sign_m) begin
                    mem_read_data = {32'b0, shifted_rdata[31:0]};
                end else begin
                    mem_read_data = {{32{shifted_rdata[31]}}, shifted_rdata[31:0]};
                end
            end

            // 64 bit
            2'd3: begin
                mem_read_data = shifted_rdata[63:0];
            end

            default: begin
                mem_read_data = 64'b0;
            end
        endcase
    end

endmodule
