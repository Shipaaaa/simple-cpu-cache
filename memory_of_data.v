`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    19:16:42 06/03/2020
// Design Name:
// Module Name:    memory_of_data
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module memory_of_data
       #(
           parameter CHANNELS        = 4,
           parameter AINDEX_WIDTH    = 8,
           parameter CH_NUM_WIDTH    = 2,
           parameter BANKS           = 256,
           parameter CACHE_STR_WIDTH = 64
       )
       (
           input                            clk,
           input                            not_reset,

           input      [AINDEX_WIDTH-1:0]    index,
           input      [CH_NUM_WIDTH-1:0]    channel,
           
           input                            need_write_data,
           input      [CACHE_STR_WIDTH-1:0] data_in,

           output reg [CACHE_STR_WIDTH-1:0] data_out
       );

reg     [CACHE_STR_WIDTH-1:0] data_mem     [BANKS-1:0] [CHANNELS-1:0];
wire    [CACHE_STR_WIDTH-1:0] data_mem_idx [CHANNELS-1:0];

genvar g, h;

integer i, j;

for(g = 0; g < CHANNELS; g = g + 1) begin : gen_bank_wires
    assign data_mem_idx[g] = data_mem[index][g];
end

always @* begin
    for(i = 0; i < CHANNELS; i = i + 1) begin
        if (channel == i) begin
            data_out = data_mem_idx[i];
        end
    end
end

always @(posedge clk or negedge not_reset) begin
    if(!not_reset) begin
        for(i = 0; i < BANKS; i = i + 1) begin
            for(j = 0; j < CHANNELS; j = j + 1) begin
                data_mem[i][j] <= 0;
            end
        end
    end
    else begin
        if(need_write_data == 1) begin
            data_mem[index][channel] <= data_in;
            `ifndef SYNTHESIS
                    $display("[DATA MEM %0t] write %0h (index=%0h, channel=%0h)", $time, data_in, index, channel);
                `endif
        end
    end
end

endmodule
