`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    17:35:03 06/03/2020
// Design Name:
// Module Name:    interface_cpu
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
module interface_cpu
       #(
           parameter ADDR_SIZE = 16,
           parameter WORD_SIZE = 32
       )
       (
           // from CPU
           input [ADDR_SIZE-1:0]   sys_addr,
           input [WORD_SIZE-1:0]   sys_wdata,
           input                   sys_rd,
           input                   sys_wr,
           input [3:0]             sys_bval,

           input                   sys_clk,
           input                   sys_rst_n,
           input                   cache_clk,
           input                   cache_not_reset,

           // from cache
           input                   cache_ack,
           input  [WORD_SIZE-1:0]  cache_rdata,

           // to CPU
           output [WORD_SIZE-1:0]  sys_rdata,
           output                  sys_ack,
           // to cache
           output [ADDR_SIZE-1:0]   cache_addr,
           output [WORD_SIZE-1:0]   cache_wdata,
           output                   cache_rd,
           output                   cache_wr,
           output [3:0]             cache_bval
       );
/*
    CPU -> Cache
*/
reg [ADDR_SIZE-1:0] sys_addr_d1;
reg [ADDR_SIZE-1:0] sys_addr_d2;

reg [ADDR_SIZE-1:0] sys_wdata_d1;
reg [ADDR_SIZE-1:0] sys_wdata_d2;

reg [3:0] sys_bval_d1;
reg [3:0] sys_bval_d2;

reg sys_rd_t;
reg sys_rd_d1;
reg sys_rd_d2;
reg sys_rd_d3;

reg sys_wr_t;
reg sys_wr_d1;
reg sys_wr_d2;
reg sys_wr_d3;

always @(posedge cache_clk or negedge cache_not_reset) begin
    if(~cache_not_reset) begin
        sys_rd_d1 <= 0;
        sys_rd_d2 <= 0;
        sys_rd_d3 <= 0;

        sys_wr_d1 <= 0;
        sys_wr_d2 <= 0;
        sys_wr_d3 <= 0;
    end
    else begin
        sys_rd_d1 <= sys_rd_t;
        sys_rd_d2 <= sys_rd_d1;
        sys_rd_d3 <= sys_rd_d2;

        sys_wr_d1 <= sys_wr_t;
        sys_wr_d2 <= sys_wr_d1;
        sys_wr_d3 <= sys_wr_d2;

        sys_bval_d1 <= sys_bval;
        sys_bval_d2 <= sys_bval_d1;

        sys_wdata_d1 <= sys_wdata;
        sys_wdata_d2 <= sys_wdata_d1;

        sys_addr_d1 <= sys_addr;
        sys_addr_d2 <= sys_addr_d1;
    end
end
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(~sys_rst_n) begin
        sys_rd_t <= 0;
        sys_wr_t <= 0;
    end
    else if(sys_wr == 1) begin
        sys_wr_t <= ~sys_wr_t;
    end
    else if(sys_rd == 1) begin
        sys_rd_t <= ~sys_rd_t;
    end
end
assign cache_wr = (sys_wr_d2 ^ sys_wr_d3);
assign cache_rd = (sys_rd_d2 ^ sys_rd_d3);
assign cache_bval = sys_bval_d2;
assign cache_addr = sys_addr_d2;
assign cache_wdata = sys_wdata_d2;
/*
    Cache -> CPU
*/
reg [31:0] sys_rdata_d1;
reg [31:0] sys_rdata_d2;
reg sys_ack_t;
reg sys_ack_d1;
reg sys_ack_d2;
reg sys_ack_d3;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(~sys_rst_n) begin
        sys_rdata_d1 <= 0;
        sys_rdata_d2 <= 0;
        sys_ack_d1 <= 0;
        sys_ack_d2 <= 0;
        sys_ack_d3 <= 0;
    end
    else begin
        sys_rdata_d1 <= cache_rdata;
        sys_rdata_d2 <= sys_rdata_d1;

        sys_ack_d1 <= sys_ack_t;
        sys_ack_d2 <= sys_ack_d1;
        sys_ack_d3 <= sys_ack_d2;


    end
end
always @(posedge cache_ack or negedge cache_not_reset) begin
    if(~cache_not_reset) begin
        sys_ack_t <= 0;
    end
    else if(cache_ack == 1) begin
        sys_ack_t <= ~sys_ack_t;
    end
end
assign sys_ack = (sys_ack_d3 ^ sys_ack_d2);
assign sys_rdata = sys_rdata_d2;

endmodule
