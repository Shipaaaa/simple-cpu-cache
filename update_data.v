`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    18:31:13 06/03/2020
// Design Name:
// Module Name:    update_data
// Project Name:
// Target Devices:
// Tool versions:
// Description:
//      Строка состоит из 64 байт = 2 набора по 32 байта.
//      Старшие два бита смещения отвечают за то, с каким набором из 4 байт мы работаем
//      sys_bval отвечает за то, с каким  байтом мы работаем в выбранном наборе
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module update_data
       #(
           parameter CACHE_STR_WIDTH = 64,
           parameter OFFSET_WIDTH    = 3
       )(
           input      [31:0]                sys_wdata,
           input      [CACHE_STR_WIDTH-1:0] cache_data,

           input      [OFFSET_WIDTH-1:0]    offset,
           input      [3:0]                 sys_bval,

           output reg [CACHE_STR_WIDTH-1:0] out_data
       );

reg  [31:0] c_frame;
wire [31:0] frame;

always @* begin
    case(offset[2])
        1'b0: begin
            c_frame  = cache_data[31:0];
            out_data = { cache_data[63:32], frame};
        end

        1'b1: begin
            c_frame  = cache_data[63:32];
            out_data = {frame, cache_data[31:0]};
        end
    endcase
end

assign frame[7:0]   = sys_bval[0] ? sys_wdata[7:0]      : c_frame[7:0];
assign frame[15:8]  = sys_bval[1] ? sys_wdata[15:8]     : c_frame[15:8];
assign frame[23:16] = sys_bval[2] ? sys_wdata[23:16]    : c_frame[23:16];
assign frame[31:24] = sys_bval[3] ? sys_wdata[31:24]    : c_frame[31:24];

endmodule
