`timescale 1ns / 1ps

/*
    clk - clock
    not_reset - async reset
    din - входные данные
    load - загрузка данных
    mode - режим загрузки (0 - параллельная загрузка, 1 - последовательная со старших разрядов)
    shift - сдвиг
    dout - выходные данные
*/
module shift_reg
       #(
           parameter CASH_STR_WIDTH = 64,
           parameter SHIFT_LEN = 32
       )
       (
           input                       clk,
           input                       not_reset,
           input [CASH_STR_WIDTH-1:0]  din,
           input [SHIFT_LEN-1:0]       din_b,
           input                       load,
           input                       mode,
           input                       shift,

           output [CASH_STR_WIDTH-1:0] dout
       );

reg [CASH_STR_WIDTH-1:0] data;

always @(posedge clk or negedge not_reset) begin
    if(~not_reset) begin
        data <= 0;
    end
    else if(load & ~mode) begin
        data <= din;
    end
    else if(load & mode) begin
        data <= {din_b, data[CASH_STR_WIDTH-1:SHIFT_LEN]};
    end
    else if(~load && shift) begin
        data <= (data >> SHIFT_LEN);
    end
end

assign dout = data;

endmodule
