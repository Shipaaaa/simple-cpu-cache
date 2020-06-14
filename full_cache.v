`timescale 1ns / 1ps

`include "memory_of_tags.v"
`include "memory_of_data.v"
`include "control_unit.v"
`include "update_data.v"
`include "interface_ram.v"
`include "interface_cpu.v"

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
           parameter TAG_SIZE = 5,
           parameter INDEX_SIZE = 8,
           parameter OFFSET_SIZE = 3,
           parameter CHANNELS = 4,
           parameter CH_NUM_WIDTH = 2,
           parameter BANKS = 256,
           parameter WORD_SIZE = 32,
           parameter CASH_STR_WIDTH = 64
       )
       (
           input                                             cache_clk,         // CPU
           input                                             cache_not_reset,   // CPU

           input                                             sys_clk,           // CPU
           input                                             sys_rst_n,         // CPU

           input       [TAG_SIZE+INDEX_SIZE+OFFSET_SIZE-1:0] sys_addr,          // CPU
           input       [WORD_SIZE-1:0]                       sys_wdata,         // CPU
           input                                             sys_rd,            // CPU
           input                                             sys_wr,            // CPU
           input       [3:0]                                 sys_bval,          // CPU

           input                                             ram_clk,           // RAM_IF IN
           input                                             ram_rst_n,         // RAM_IF IN
           input       [WORD_SIZE-1:0]                       ram_rdata,         // RAM_IF IN
           input                                             ram_rack,          // RAM_IF IN

           output  reg [WORD_SIZE-1:0]                       sys_rdata,         // CPU
           output  reg                                       sys_ack,           // CPU

           output      [TAG_SIZE+INDEX_SIZE-1:0]             ram_addr,          // RAM_IF OUT
           output      [WORD_SIZE-1:0]                       ram_wdata,         // RAM_IF OUT
           output                                            ram_avalid,        // RAM_IF OUT
           output                                            ram_rnw            // RAM_IF OUT
       );

localparam ADDR_SIZE     = TAG_SIZE+INDEX_SIZE+OFFSET_SIZE;
localparam RAM_ADDR_SIZE = TAG_SIZE+INDEX_SIZE;

wire   [ADDR_SIZE-1:0]          sys_addr_in;            // CPU_IF IN
wire   [WORD_SIZE-1:0]          sys_wdata_in;           // CPU_IF IN
wire                            sys_wr_in;              // CPU_IF IN
wire                            sys_rd_in;              // CPU_IF IN
wire   [3:0]                    sys_bval_in;            // CPU_IF IN

reg    [WORD_SIZE-1:0]          sys_rdata_out;          // CPU_IF OUT
reg                             sys_ack_out;            // CPU_IF OUT

wire   [TAG_SIZE-1:0]           tag    = sys_addr_in[15:11];
wire   [INDEX_SIZE-1:0]         index  = sys_addr_in[10:3];
wire   [OFFSET_SIZE-1:0]        offset = sys_addr_in[2:0];

wire                            rewrite_tag;            // memory_of_tags IN <- control_unit OUT

wire                            is_hit;                 // memory_of_tags OUT
wire                            need_use_fifo;          // memory_of_tags OUT -> control_unit IN
wire   [CH_NUM_WIDTH-1:0]       channel;                // memory_of_tags OUT -> memory_of_data IN
wire   [CH_NUM_WIDTH-1:0]       fifo_channel;           // memory_of_tags OUT
wire   [TAG_SIZE-1:0]           fifo_tag_for_flush;     // memory_of_tags OUT
reg    [CH_NUM_WIDTH - 1:0]     data_channel;           // memory_of_data IN

wire                            need_write_data;        // memory_of_data IN <- control_unit OUT

wire                            cache_ack;              // control_unit IN
wire                            cache_avalid;           // control_unit OUT -> RAM_IF IN

wire                            select_data;            // control_unit OUT -> memory_of_data IN
wire                            select_channel;         // control_unit OUT -> memory_of_data IN


wire   [CASH_STR_WIDTH-1:0]     cache_rdata;            // RAM_IF OUT
wire   [CASH_STR_WIDTH-1:0]     cpu_data;               // update_data OUT
reg    [CASH_STR_WIDTH-1:0]     data_in;                // memory_of_data IN <- RAM_IF OUT
wire   [CASH_STR_WIDTH-1:0]     cache_data;             // memory_of_data OUT -> RAM_IF IN

wire                            sys_ack_d;              // control_unit OUT

wire   [RAM_ADDR_SIZE:0]        cache_addr;             // RAM_IF IN

always @(posedge cache_clk or negedge cache_not_reset) begin
    if(~cache_not_reset) begin
        sys_rdata_out <= 32'b0;
        sys_ack_out <= 0;
    end
    else begin
        sys_ack_out <= sys_ack_d;
        if(sys_ack_d) begin
            case(offset[2])
                0: sys_rdata_out <= cache_data[31:0];
                1: sys_rdata_out <= cache_data[63:32];
            endcase
        end
    end
end

interface_cpu #(ADDR_SIZE, WORD_SIZE)
              interface_cpu(
                  // in from CPU
                  .sys_addr(sys_addr),
                  .sys_wdata(sys_wdata),
                  .sys_rd(sys_rd),
                  .sys_wr(sys_wr),
                  .sys_bval(sys_bval),
                  .sys_clk(sys_clk),
                  .sys_rst_n(sys_rst_n),
                  .cache_clk(cache_clk),
                  .cache_not_reset(cache_not_reset),

                  // in from cache
                  .cache_ack(sys_ack_out),
                  .cache_rdata(sys_rdata_out),

                  // out to cpu
                  .sys_rdata(sys_rdata),
                  .sys_ack(sys_ack),

                  // out to cache
                  .cache_addr(sys_addr_in),
                  .cache_wdata(sys_wdata_in),
                  .cache_rd(sys_rd_in),
                  .cache_wr(sys_wr_in),
                  .cache_bval(sys_bval_in)
              );

memory_of_tags
    memory_of_tags(
        .clk(cache_clk),                // in
        .not_reset(cache_not_reset),    // in
        .tag(tag),                      // in
        .index(index),                  // in
        .rewrite_tag(rewrite_tag),      // in

        .is_hit(is_hit),

        .need_use_fifo(need_use_fifo),
        .channel(channel),
        .fifo_channel(fifo_channel),

        .fifo_tag_for_flush(fifo_tag_for_flush)
    );

control_unit
    control_unit (
        .clk(cache_clk),                // in
        .not_reset(cache_not_reset),    // in
        .sys_rd(sys_rd_in),             // in
        .sys_wr(sys_wr_in),             // in
        .is_hit(is_hit),                // in
        .need_use_fifo(need_use_fifo),  // in

        .ram_ack(cache_ack),            // in

        .ram_avalid(cache_avalid),
        .ram_rnw(cache_rnw),

        .rewrite_tag(rewrite_tag),
        .need_write_data(need_write_data),

        .select_data(select_data),
        .select_channel(select_channel),

        .sys_ack(sys_ack_d)
    );

always @* begin
    data_channel = select_channel ? fifo_channel : channel;
    data_in = select_data ? cache_rdata : cpu_data;
end

memory_of_data #(CHANNELS, INDEX_SIZE, CH_NUM_WIDTH, BANKS, CASH_STR_WIDTH)
               memory_of_data(
                   .clk(cache_clk),
                   .not_reset(cache_not_reset),
                   .index(index),
                   .channel(data_channel),
                   .need_write_data(need_write_data),
                   .data_in(data_in),

                   .data_out(cache_data)
               );

update_data
    update_data (
        .offset(offset),
        .sys_wdata(sys_wdata_in),
        .cache_data(cache_data),
        .sys_bval(sys_bval_in),
        .out_data(cpu_data)
    );

assign cache_addr = cache_rnw ? {tag, index} : {fifo_tag_for_flush, index};

interface_ram #(RAM_ADDR_SIZE, CASH_STR_WIDTH, WORD_SIZE)
              interface_ram (
                  .ram_clk(ram_clk),
                  .ram_rst_n(ram_rst_n),
                  .ram_rdata(ram_rdata),
                  .ram_ack(ram_rack),

                  .ram_addr(ram_addr),
                  .ram_wdata(ram_wdata),
                  .ram_avalid(ram_avalid),
                  .ram_rnw(ram_rnw),

                  .cache_clk(cache_clk),
                  .cache_not_reset(cache_not_reset),
                  .cache_addr(cache_addr),
                  .cache_wdata(cache_data),
                  .cache_avalid(cache_avalid),
                  .cache_rnw(cache_rnw),

                  .cache_rdata(cache_rdata),
                  .cache_ack(cache_ack)
              );

endmodule
