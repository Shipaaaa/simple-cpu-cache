`timescale 1ns / 1ps

`include "utils_async_fifo_bin.v"

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
           parameter DATA_SIZE = 32,
           parameter BVAL_SIZE = 4
       )
       (
           input  [ADDR_SIZE-1:0]  addr,
           input  [DATA_SIZE-1:0]  sys_wdata,
           input  [BVAL_SIZE-1:0]  sys_bval,
           input                   sys_rd,
           input                   sys_wr,

           output [DATA_SIZE-1:0]  sys_rdata,
           output                  sys_ack,

           output [ADDR_SIZE-1:0]  c_addr,
           output [DATA_SIZE-1:0]  c_wdata,
           output [BVAL_SIZE-1:0]  c_bval,
           output                  c_rd,
           output                  c_wr,

           input  [DATA_SIZE-1:0]  c_rdata,
           input                   c_ack,

           input                   rst,
           input                   c_clk,
           input                   sys_clk
       );

parameter BUS_SIZE = ADDR_SIZE + DATA_SIZE + BVAL_SIZE + 2;

wire not_reset;

assign not_reset = ~rst;

wire [BUS_SIZE-1:0] wr_fifo_din;
wire [BUS_SIZE-1:0] wr_fifo_dout;
wire [DATA_SIZE:0]  rd_fifo_din;
wire [DATA_SIZE:0]  rd_fifo_dout;

assign wr_fifo_din[BUS_SIZE-1]                      = sys_rd;
assign wr_fifo_din[BUS_SIZE-2]                      = sys_wr;
assign wr_fifo_din[BUS_SIZE-3:DATA_SIZE+ADDR_SIZE]  = sys_bval;
assign wr_fifo_din[DATA_SIZE+ADDR_SIZE-1:DATA_SIZE] = addr;
assign wr_fifo_din[DATA_SIZE-1:0]                   = sys_wdata;

assign sys_ack   = rd_fifo_dout[DATA_SIZE];
assign sys_rdata = rd_fifo_dout[DATA_SIZE-1:0];

assign c_rd    = wr_fifo_dout[BUS_SIZE-1];
assign c_wr    = wr_fifo_dout[BUS_SIZE-2];
assign c_bval  = wr_fifo_dout[BUS_SIZE-3:DATA_SIZE+ADDR_SIZE];
assign c_addr  = wr_fifo_dout[DATA_SIZE+ADDR_SIZE-1:DATA_SIZE];
assign c_wdata = wr_fifo_dout[DATA_SIZE-1:0];

assign rd_fifo_din[DATA_SIZE]   = c_ack;
assign rd_fifo_din[DATA_SIZE-1:0] = c_rdata;

reg c_ack_buf;
reg sys_rd_buf;
reg sys_wr_buf;
reg read_rd_fifo;
reg read_wr_fifo;

wire write_rd_fifo;
wire write_wr_fifo;
wire rd_fifo_full;
wire wr_fifo_full;
wire rd_fifo_empty;
wire wr_fifo_empty;

assign write_rd_fifo = c_ack_buf != c_ack;
assign write_wr_fifo = (sys_rd != sys_rd_buf) || (sys_wr != sys_wr_buf);

always @* if (rst) begin
        $display("RST");
        sys_wr_buf <= 0;
        sys_rd_buf <= 0;
        c_ack_buf  <= 0;

        read_rd_fifo <= 0;
        read_wr_fifo <= 0;
    end

always @(posedge c_clk) begin
    if (wr_fifo_full)  read_wr_fifo <= 1; else
        if (wr_fifo_empty) read_wr_fifo <= 0;

    c_ack_buf <= c_ack;
    if (c_ack) begin
        $display("[%3d] ack %b data %08x", $time, c_ack, c_rdata);
    end
end

always @(posedge sys_clk) begin
    if (rd_fifo_full)  read_rd_fifo <= 1; else
        if (rd_fifo_empty) read_rd_fifo <= 0;

    if (sys_wr != sys_wr_buf) $display("flipping wr -> %b", sys_wr);
    if (sys_rd != sys_rd_buf) $display("flipping rd -> %b", sys_rd);
    sys_rd_buf <= sys_rd;
    sys_wr_buf <= sys_wr;
end

async_bin_fifo #(DATA_SIZE+1) ReadFIFO (
                   .not_reset(not_reset),    // input rst
                   .wr_clk(c_clk),           // input wr_clk
                   .rd_clk(sys_clk),         // input rd_clk
                   .din(rd_fifo_din),        // input din
                   .write(write_rd_fifo),    // input wr_en
                   .read(read_rd_fifo),      // input rd_en
                   .dout(rd_fifo_dout),      // output dout
                   .full(rd_fifo_full),      // output full
                   .empty(rd_fifo_empty)     // output empty
               );

async_bin_fifo #(BUS_SIZE) WriteFIFO (
                   .not_reset(not_reset),    // input rst
                   .wr_clk(sys_clk),         // input wr_clk
                   .rd_clk(c_clk),           // input rd_clk
                   .din(wr_fifo_din),        // input din
                   .write(write_wr_fifo),    // input wr_en
                   .read(read_wr_fifo),      // input rd_en
                   .dout(wr_fifo_dout),      // output dout
                   .full(wr_fifo_full),      // output full
                   .empty(wr_fifo_empty)     // output empty
               );

endmodule
