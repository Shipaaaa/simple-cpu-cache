`timescale 1ns / 1ps

`include "utils_grey_counter.v"

module async_bin_fifo
       #(
           parameter CASH_STR_WIDTH = 64
       )
       (
           input                           not_reset,
           input                           rd_clk,
           input                           wr_clk,
           input [CASH_STR_WIDTH-1:0]      din,
           input                           read,
           input                           write,

           output reg [CASH_STR_WIDTH-1:0] dout,
           output reg                      empty,
           output reg                      full
       );

parameter ADDR_WIDTH = 1;
parameter FIFO_DEPTH = 2;

reg [CASH_STR_WIDTH-1:0] FIFO [FIFO_DEPTH-1:0];

reg     [ADDR_WIDTH-1:0] p_read;
reg     [ADDR_WIDTH-1:0] p_write;
wire                     eq_addr;
wire                     write_en;
wire                     read_en;
wire                     setStatus;
wire                     rstStatus;
reg                      status;
wire                     preFull;
wire                     preEmpty;

always @(posedge rd_clk or not_reset) begin
    if (!not_reset)
        p_read <= 0;
    else if (read_en)
        p_read <= p_read + 1;
end

always @(posedge wr_clk or not_reset) begin
    if (!not_reset)
        p_write <= 0;
    else if (write_en)
        p_write <= p_write + 1;
end

assign eq_addr = (p_read == p_write);
assign write_en = (write & ~full);
assign read_en = (read & ~empty);

assign preEmpty = (~status & eq_addr);
assign preFull  = (status & eq_addr);

always @(posedge rd_clk or posedge preEmpty) begin
    if(preEmpty) begin
        empty <= 1;
    end
    else begin
        empty <= 0;
    end
end

always @(posedge wr_clk or posedge preFull) begin
    if(preFull) begin
        full <= 1;
    end
    else begin
        full <= 0;
    end
end

assign setStatus = write_en & (p_write ^ p_read);
assign rstStatus = read_en & (p_write ^ p_read);

always @(setStatus or rstStatus or not_reset) begin
    if(rstStatus | ~not_reset) begin
        status = 0;
    end
    else if(setStatus) begin
        status = 1;
    end
end

always @(posedge rd_clk or negedge not_reset) begin
    if(~not_reset) begin
        dout <= 0;
    end
    else if(read_en) begin
        $display("[%3d] read  %07h to pos %0h", $time, FIFO[p_read], p_read);
        dout <= FIFO[p_read];
    end
end

integer i;

always @(posedge wr_clk or negedge not_reset) begin
    if(~not_reset) begin
        for(i = 0; i < FIFO_DEPTH; i = i + 1) begin
            FIFO[i] <= 0;
        end
    end
    else if(write_en) begin
        FIFO[p_write] <= din;
        $display("[%3d] write %07h to pos %0h", $time, din, p_write);
    end
end

endmodule
