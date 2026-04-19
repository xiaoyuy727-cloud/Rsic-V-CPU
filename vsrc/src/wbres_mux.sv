//模块名称：wbres_mux
//接口：input logic wb_result_w
//      input logic [1:0]is_baj_w
//      input logic [63:0] aluout_w
//      input logic [63:0] mem_write_data_w
//      input logic [63:0] pc_w
//      output logic [63:0] wb_write_data
//功能：选择最后写回的数据是什么。
//      当is_baj_w是2或者3，将pc_w+4写到wb_write_data。否则，考虑wb_result_W.
//      当wb_result_w是1时，将mem_write_data_w写到wb_write_data。
//      当wb_result_w是0时，将aluout_w写到wb_write_data。
module wbres_mux (
    input  logic        wb_result_w,
    input  logic [1:0]  is_baj_w,
    input  logic [63:0] aluout_w,
    input  logic [63:0] mem_write_data_w,
    input  logic [63:0] pc_w,
    output logic [63:0] wb_write_data
);

    always_comb begin
        if (is_baj_w == 2'd2 || is_baj_w == 2'd3) begin
            wb_write_data = pc_w + 64'd4;
        end
        else if (wb_result_w == 1'b1) begin
            wb_write_data = mem_write_data_w;
        end
        else begin
            wb_write_data = aluout_w;
        end
    end

endmodule