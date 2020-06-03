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
module interface_cpu(
           input  [15:0] addr,
           input  [31:0] sys_wdata,
           input  [3:0]  sys_bval,
           input         sys_rd,
           input         sys_wr,

           output [31:0] sys_rdata,
           output        sys_ack,

           output [15:0] c_addr,
           output [31:0] c_wdata,
           output [3:0]  c_bval,
           output        c_rd,
           output        c_wr,

           input  [31:0] c_rdata,
           input         c_ack,

           input         nReset,
           input         c_clk,
           input         sys_clk
       );

wire [53:0] wr_fifo_din;
wire [53:0] wr_fifo_dout;
wire [32:0] rd_fifo_din;
wire [32:0] rd_fifo_dout;

assign wr_fifo_din[53]    = sys_rd;
assign wr_fifo_din[52]    = sys_wr;
assign wr_fifo_din[51:48] = sys_bval;
assign wr_fifo_din[47:32] = addr;
assign wr_fifo_din[31:0]  = sys_wdata;

assign sys_ack   = rd_fifo_dout[32];
assign sys_rdata = rd_fifo_dout[31:0];

assign c_rd    = wr_fifo_dout[53];
assign c_wr    = wr_fifo_dout[52];
assign c_bval  = wr_fifo_dout[51:48];
assign c_addr  = wr_fifo_dout[47:32];
assign c_wdata = wr_fifo_dout[31:0];

assign rd_fifo_din[32]   = c_ack;
assign rd_fifo_din[31:0] = c_rdata;

reg c_ack_buf;
reg sys_rd_buf;
reg sys_wr_buf;

wire write_rd_fifo;
wire write_wr_fifo;

assign write_rd_fifo = c_ack_buf != c_ack;
assign write_wr_fifo = (sys_rd != sys_rd_buf) || (sys_wr != sys_wr_buf);

always @(posedge c_clk) begin

    if (!nReset) begin
        c_ack_buf  <= 0;
    end

    c_ack_buf <= c_ack;
    if (c_ack) begin
        //$display("[%3d] ack %b data %08x", $time, c_ack, c_rdata);
    end
end

always @(posedge sys_clk) begin
    if (!nReset) begin
        //$display("RST");
        sys_rd_buf <= 0;
        sys_wr_buf <= 0;
    end

    //if (sys_wr != sys_wr_buf) $display("flipping wr -> %b", sys_wr);
    //if (sys_rd != sys_rd_buf) $display("flipping rd -> %b", sys_rd);
    sys_rd_buf <= sys_rd;
    sys_wr_buf <= sys_wr;
end

async_fifo #(33, 2, 4) ReadFIFO (
               .nRST(nReset),            // input rst
               .WR_CLK(c_clk),           // input wr_clk
               .RD_CLK(sys_clk),         // input rd_clk
               .DIN(rd_fifo_din),        // input [32 : 0] din
               .write(write_rd_fifo),    // input wr_en
               .read(1'b1),              // input rd_en
               .DOUT(rd_fifo_dout)       // output [32 : 0] dout
           );

async_fifo #(54, 2, 4) WriteFIFO (
               .nRST(nReset),            // input rst
               .WR_CLK(sys_clk),         // input wr_clk
               .RD_CLK(c_clk),           // input rd_clk
               .DIN(wr_fifo_din),        // input [53 : 0] din
               .write(write_wr_fifo),    // input wr_en
               .read(1'b1),              // input rd_en
               .DOUT(wr_fifo_dout)       // output [53 : 0] dout
           );

endmodule
