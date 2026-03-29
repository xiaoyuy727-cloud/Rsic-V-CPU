//模块名称：wbres_mux
//接口：input logic wbresult_w
//      input logic [63:0] aluout_w
//      input logic [63:0] mem_write_data_w
//      output logic [63:0] wb_write_data
//功能：选择最后写回的数据是什么。
//      当wbresult_w是1时，将mem_write_data_w写到wb_write_data。
//      当wbresult_w是0时，将aluout_w写到wb_write_data。
module wbres_mux (
    input  logic        wbresult_w,
    input  logic [63:0] aluout_w,
    input  logic [63:0] mem_write_data_w,
    output logic [63:0] wb_write_data
);

    always_comb begin
        if (wbresult_w) begin
            wb_write_data = mem_write_data_w;
        end else begin
            wb_write_data = aluout_w;
        end
    end

endmodule