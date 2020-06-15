`timescale 1ns / 1ps

`include "utils_grey_counter.v"

module async_fifo
       #(
           parameter CACHE_STR_WIDTH = 64,
           parameter ADDR_WIDTH      = 2,
           parameter FIFO_DEPTH      = (1 << ADDR_WIDTH)
       )
       (
           input                            not_reset,
           input                            rd_clk,
           input                            wr_clk,
           input      [CACHE_STR_WIDTH-1:0] din,
           input                            read,
           input                            write,

           output reg [CACHE_STR_WIDTH-1:0] dout,
           output reg                       empty,
           output reg                       full
       );

reg  [CACHE_STR_WIDTH-1:0]  FIFO [FIFO_DEPTH-1:0];

wire [ADDR_WIDTH-1:0]       p_read;
wire [ADDR_WIDTH-1:0]       p_write;
wire                        eq_addr;
wire                        write_en;
wire                        read_en;
wire                        setStatus;
wire                        rstStatus;
reg                         status;
wire                        preFull;
wire                        preEmpty;

assign eq_addr  = (p_read == p_write);
assign write_en = (write & ~full);
assign read_en  = (read & ~empty);

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

assign setStatus = (
           (p_write[ADDR_WIDTH-2] ~^ p_read[ADDR_WIDTH-1]) &
           (p_write[ADDR_WIDTH-1] ^ p_read[ADDR_WIDTH-2])
       );

assign rstStatus = (
           (p_write[ADDR_WIDTH-2] ^ p_read[ADDR_WIDTH-1])  &
           (p_write[ADDR_WIDTH-1] ~^ p_read[ADDR_WIDTH-2])
       );

always @(setStatus or rstStatus or not_reset) begin
    if(rstStatus | ~not_reset) begin
        status = 0;
    end
    else if(setStatus) begin
        status = 1;
    end
end

gray_counter #(ADDR_WIDTH)
             gc_rd(
                 .clk(rd_clk),
                 .en(read_en),
                 .not_reset(not_reset),
                 .value(p_read)
             );

gray_counter #(ADDR_WIDTH)
             gc_wr(
                 .clk(wr_clk),
                 .en(write_en),
                 .not_reset(not_reset),
                 .value(p_write)
             );

always @(posedge rd_clk or negedge not_reset) begin
    if(~not_reset) begin
        dout <= 0;
    end
    else if(read_en) begin
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
        $display("[FIFO] [%0t] write %0h to pos %0h", $time, din, p_write);
    end
end

endmodule
