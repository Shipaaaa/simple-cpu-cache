`timescale 1ns / 1ps

`include "utils_async_fifo.v"
`include "interface_ram_controller.v"
`include "utils_shift_reg.v"

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    17:35:21 06/03/2020
// Design Name:
// Module Name:    interface_ram
// Project Name:
// Target Devices:
// Tool versions:
// Description: Модуль взаимодействия с оперативной памятью
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
/*
    clk - clock
    not_reset - async reset
    tag - тэг
    idx - индекс
    ram_rnw - read(1), write(0)
    ram_rdata - данные, пришедшие с ОП (выставляется ОП)
    ram_rack - сигнал подтверждения (выставляется ОП)
    wdata - данные на запись из кэша
    ram_wdata - данные, которые побайтово уходят в ОП
    ram_addr - адрес ячейки памяти в ОП
    ram_avalid - сигнал, разрешающий взаимодействие с ОП
*/
module interface_ram
       #(
           parameter ADDR_SIZE = 13,
           parameter CASH_STR_WIDTH = 64,
           parameter WORD_SIZE = 16
       )
       (
           // Clock domain 1: RAM
           input  [WORD_SIZE-1:0]      ram_rdata,
           input                       ram_ack,
           input                       ram_rst_n,
           input                       ram_clk,

           output [WORD_SIZE-1:0]      ram_wdata,
           output [ADDR_SIZE-1:0]      ram_addr,
           output                      ram_avalid,
           output                      ram_rnw,

           // Clock domain 2: Cache
           input  [CASH_STR_WIDTH-1:0] cache_wdata,
           input  [ADDR_SIZE-1:0]      cache_addr,
           input                       cache_avalid,
           input                       cache_rnw,
           input                       cache_rst_n,
           input                       cache_clk,

           output [CASH_STR_WIDTH-1:0] cache_rdata,
           output                      cache_ack
       );

wire [CASH_STR_WIDTH-1:0]   sr_dout;
wire [WORD_SIZE-1:0]        ram_word = sr_dout[WORD_SIZE-1:0];
wire [ADDR_SIZE-1:0]        ram_addr_c;
wire                        ram_rnw_c;
wire                        ram_avalid_c;

assign cache_rdata = sr_dout;

wire [(WORD_SIZE+ADDR_SIZE+2)-1:0] ram_packet_i;

assign ram_packet_i = { ram_rnw_c, ram_avalid_c, ram_addr_c, ram_word };

wire fw_full;
wire fw_empty;
wire fw_read = ~fw_empty;
wire fw_write;

wire fr_full;
wire fr_empty;
wire fr_read;
wire fr_write;
wire [WORD_SIZE-1:0] fr_word;

wire sr_load;
wire sr_mode;
wire sr_shift;

reg fw_empty_g;
wire [(WORD_SIZE+ADDR_SIZE+2)-1:0] ram_packet_o;
assign ram_rnw      = ram_packet_o[WORD_SIZE+ADDR_SIZE+1];           //= ram_packet_o[45];
assign ram_avalid   = ram_packet_o[WORD_SIZE+ADDR_SIZE];             //= ram_packet_o[44];
assign ram_addr     = ram_packet_o[WORD_SIZE+ADDR_SIZE-1:WORD_SIZE]; //= ram_packet_o[43:32];
assign ram_wdata    = ram_packet_o[WORD_SIZE-1:0];                   //= ram_packet_o[31:0];

reg [WORD_SIZE-1:0] ram_rdata_d;
always @(posedge ram_clk) begin
    ram_rdata_d <= ram_rdata;
end

// слово + ram_aks
async_fifo #(17, 2)
           read_fifo (
               .not_reset(ram_rst_n),
               .rd_clk(cache_clk),
               .wr_clk(ram_clk),
               .din(ram_rdata_d),
               .read(fr_read),
               .write(ram_ack),

               .dout(fr_word),
               .empty(fr_empty),
               .full(fr_full)
           );

shift_reg #(CASH_STR_WIDTH, WORD_SIZE)
          shift_register(
              .clk(cache_clk),
              .not_reset(cache_rst_n),
              .din(cache_wdata),
              .din_b(fr_word),
              .load(sr_load),
              .shift(sr_shift),
              .mode(sr_mode),
              .dout(sr_dout)
          );

// адрес + слово + ram_rnw + ram_avalid
async_fifo #(31, 2)
           write_fifo(
               .not_reset(cache_rst_n),
               .rd_clk(ram_clk),
               .wr_clk(cache_clk),
               .din(ram_packet_i),
               .read(fw_read),
               .write(fw_write),

               .dout(ram_packet_o),
               .empty(fw_empty),
               .full(fw_full)
           );

interface_ram_controller #(13, 64)
                         controller(
                             .clk(cache_clk),
                             .not_reset(cache_rst_n),
                             .cache_avalid(cache_avalid),
                             .cache_rnw(cache_rnw),
                             .fifo_empty(fr_full),
                             .rfifo_empty(fr_empty),
                             .fifo_full(fw_full),
                             .cache_wdata(cache_wdata),
                             .cache_addr(cache_addr),

                             .write(fw_write),
                             .read(fr_read),
                             .cache_ack(cache_ack),
                             .ram_addr(ram_addr_c),
                             .ram_rnw(ram_rnw_c),
                             .ram_avalid(ram_avalid_c),
                             .sr_load(sr_load),
                             .sr_mode(sr_mode),
                             .sr_shift(sr_shift)
                         );
endmodule
