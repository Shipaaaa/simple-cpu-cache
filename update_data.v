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
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module update_data(
           input       [1:0]   offset,
           input       [31:0]  sys_wdata,
           input       [127:0] c_data,
           input       [3:0]   sys_bval,

           output reg  [127:0] out_data
       );

reg [31:0]  c_frame;
wire [31:0] frame;

always @* begin
    case(offset[1:0])
        2'b00: begin
            c_frame = c_data[31:0];
            out_data = {c_data[127:96], c_data[95:64], c_data[63:32], frame};
        end

        2'b01: begin
            c_frame = c_data[63:32];
            out_data = {c_data[127:96], c_data[95:64], frame, c_data[31:0]};
        end

        2'b10: begin
            c_frame = c_data[95:64];
            out_data = {c_data[127:96], frame, c_data[63:32], c_data[31:0]};
        end

        2'b11: begin
            c_frame = c_data[127:96];
            out_data = {frame, c_data[95:64], c_data[63:32], c_data[31:0]};
        end
    endcase
end

assign frame[7:0]   = sys_bval[0] ? sys_wdata[7:0]      : c_frame[7:0];
assign frame[15:8]  = sys_bval[1] ? sys_wdata[15:8]     : c_frame[15:8];
assign frame[23:16] = sys_bval[2] ? sys_wdata[23:16]    : c_frame[23:16];
assign frame[31:24] = sys_bval[3] ? sys_wdata[31:24]    : c_frame[31:24];
endmodule
