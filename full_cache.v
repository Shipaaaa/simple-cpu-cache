`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    18:05:18 06/03/2020
// Design Name:
// Module Name:    full_cache
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
module full_cache
       #(
           parameter AINDEX_WIDTH = 3,
           parameter ATAG_WIDTH = 11,
           parameter AOFFSET_WIDTH = 2,
           parameter CH_NUM_WIDTH = 3,
           parameter CASH_MEM_WIDTH = 128,
           parameter CPU_DATA_WIDTH = 32,
           parameter WORD_SIZE = 32,
           parameter ADDR_SIZE = 14
       )
       (
           input 														sys_clk,
           input 														sys_nReset,
           input 														cache_clk,
           input 														cache_nReset,
           input 														ram_clk,
           input 														ram_nReset,
           input	[CPU_DATA_WIDTH - 1:0] 								sys_wdata,
           input	[ATAG_WIDTH + AINDEX_WIDTH + AOFFSET_WIDTH - 1:0]	sys_addr,
           input           												sys_rd,
           input           												sys_wr,
           input    [3:0]   											sys_bval,

           input    [WORD_SIZE-1:0] 									ram_rdata,
           input       		   											ram_ack,

           output	[CASH_MEM_WIDTH - 1:0] 								mem_data,
           output	[CPU_DATA_WIDTH - 1:0] 								sys_rdata,
           output 	[WORD_SIZE-1:0]   									ram_wdata,
           output 														sys_ack
       );

wire hit;
wire fifo;
wire wr_tag;
wire wr;
wire ram_aval;
wire cache_aval;
wire ram_write;
wire ram_rnw;
wire selD;
wire selN;
wire cache_ram_ack;
wire cache_ack;
wire c_rd;
wire c_wr;

wire [CH_NUM_WIDTH - 1:0]  	    chan;
wire [CH_NUM_WIDTH - 1:0]  	    fifo_chan;
wire [ATAG_WIDTH - 1:0] 		fifo_tag;
wire [CASH_MEM_WIDTH - 1:0] 	comb_out;
wire [3:0] 						state;
wire [CASH_MEM_WIDTH - 1:0] 	ram_data;
wire [ADDR_SIZE-1:0] 			ram_addr;
wire [CPU_DATA_WIDTH - 1:0] 	cache_rdata;
wire [3:0] 						c_bval;
wire [CPU_DATA_WIDTH - 1:0]     c_wdata;

reg [CH_NUM_WIDTH - 1:0]  		data_chan;
reg [CASH_MEM_WIDTH-1:0]  		data_in;

wire [ATAG_WIDTH + AINDEX_WIDTH + AOFFSET_WIDTH - 1:0] c_addr;
wire [ATAG_WIDTH - 1:0] tag = c_addr[15:5];
wire [AINDEX_WIDTH-1:0] index = c_addr[4:2];
wire [AOFFSET_WIDTH-1:0] offset = c_addr[1:0];

always @* begin
    data_chan <= selN ? fifo_chan : chan;
    data_in <= selD ? ram_data : comb_out;
end


memory_of_tags mem_of_tags(
                   .clk(cache_clk),
                   .nReset(cache_nReset),
                   .tag(tag),
                   .index(index),
                   .wr_tag(wr_tag),
                   .chan(chan),
                   .fifo_chan(fifo_chan),
                   .fifo_tag(fifo_tag),
                   .hit(hit),
                   .fifo(fifo)
               );

control_unit control(
                 .clk(cache_clk),
                 .nReset(cache_nReset),
                 .sys_rd(c_rd),
                 .sys_wr(c_wr),
                 .ram_ack(cache_ram_ack),
                 .hit(hit),
                 .fifo(fifo),
                 .sys_ack(cache_ack),
                 .wr_tag(wr_tag),
                 .wr(wr),
                 .selD(selD),
                 .selN(selN),
                 .ram_avalid(cache_aval),
                 .ram_wr(ram_wr)
             );

update_data comb(
                .offset(offset),
                .sys_wdata(c_wdata),
                .c_data(mem_data),
                .sys_bval(c_bval),
                .out_data(comb_out)
            );

memory_of_data mem_of_data(
                   .clk(cache_clk),
                   .nReset(cache_nReset),
                   .index(index),
                   .chan(data_chan),
                   .wr(wr),
                   .data_in(data_in),
                   .data_out(mem_data)
               );

wire [13:0] cache_addr = {tag, index};

interface_ram ram_interface(
                  .c_clk(cache_clk),
                  .ram_clk(ram_clk),
                  .c_nReset(ram_nReset),

                  .c_aval(cache_aval),
                  .c_wr(ram_wr),
                  .ram_ack(ram_ack),
                  .c_data_in(mem_data),
                  .ram_data_in(ram_rdata),
                  .c_addr(cache_addr),

                  .ram_aval(ram_aval),
                  .ram_wr(ram_rnw),
                  .c_ack(cache_ram_ack),
                  .c_data_out(ram_data),
                  .ram_data_out(ram_wdata),
                  .ram_addr(ram_addr)
              );

interface_cpu cpu_interface(
                  .addr(sys_addr),
                  .sys_wdata(sys_wdata),
                  .sys_bval(sys_bval),
                  .sys_rd(sys_rd),
                  .sys_wr(sys_wr),

                  .sys_rdata(sys_rdata),
                  .sys_ack(sys_ack),

                  .c_addr(c_addr),
                  .c_wdata(c_wdata),
                  .c_bval(c_bval),
                  .c_rd(c_rd),
                  .c_wr(c_wr),

                  .c_rdata(cache_rdata),
                  .c_ack(cache_ack),

                  .nReset(sys_nReset),
                  .c_clk(cache_clk),
                  .sys_clk(sys_clk)
              );

assign cache_rdata = offset == 0 ? mem_data[31:0]  :
       offset == 1 ? mem_data[63:32] :
       offset == 2 ? mem_data[95:64] :
       mem_data[127:96];

endmodule
