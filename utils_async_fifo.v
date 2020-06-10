`timescale 1ns / 1ps
`include "gray_counter.v"

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    18:31:59 06/03/2020
// Design Name:
// Module Name:    async_fifo
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
module async_fifo
       #(
           parameter DATA_WIDTH = 128,
           parameter ADDR_WIDTH = 3,
           parameter FIFO_DEPTH = (1 << ADDR_WIDTH)
       )
       (
           input                        nRST,
           input                        RD_CLK,
           input                        WR_CLK,
           input       [DATA_WIDTH-1:0] DIN,
           input                        read,
           input                        write,

           output reg  [DATA_WIDTH-1:0] DOUT,
           output reg                   EMPTY,
           output reg                   FULL
       );

reg     [DATA_WIDTH-1:0] FIFO [FIFO_DEPTH-1:0];

wire    [ADDR_WIDTH-1:0] pRead;
wire    [ADDR_WIDTH-1:0] pWrite;
wire                     eq_addr;
wire                     write_en;
wire                     read_en;
wire                     setStatus;
wire                     rstStatus;
reg                      status;
wire                     preFull;
wire                     preEmpty;

assign eq_addr = (pRead == pWrite);
assign write_en = (write & ~FULL);
assign read_en = (read & ~EMPTY);

assign preEmpty = (~status & eq_addr);
assign preFull  = (status & eq_addr);

always @(posedge RD_CLK or posedge preEmpty) begin
    if(preEmpty) begin
        EMPTY <= 1;
    end
    else begin
        EMPTY <= 0;
    end
end

always @(posedge WR_CLK or posedge preFull) begin
    if(preFull) begin
        FULL <= 1;
    end
    else begin
        FULL <= 0;
    end
end

assign setStatus = ((pWrite[ADDR_WIDTH-2] ~^ pRead[ADDR_WIDTH-1]) &
                    (pWrite[ADDR_WIDTH-1] ^ pRead[ADDR_WIDTH-2]));

assign rstStatus = ((pWrite[ADDR_WIDTH-2] ^ pRead[ADDR_WIDTH-1])  &
                    (pWrite[ADDR_WIDTH-1] ~^ pRead[ADDR_WIDTH-2]));

always @(setStatus or rstStatus or nRST) begin
    if(rstStatus | ~nRST) begin
        status = 0;
    end
    else if(setStatus) begin
        status = 1;
    end
end

gray_counter #(ADDR_WIDTH) gc_rd(
                 .CLK(RD_CLK),
                 .EN(read_en),
                 .nRST(nRST),
                 .value(pRead)
             );

gray_counter #(ADDR_WIDTH) gc_wr(
                 .CLK(WR_CLK),
                 .EN(write_en),
                 .nRST(nRST),
                 .value(pWrite)
             );

always @(posedge RD_CLK or negedge nRST) begin
    if(~nRST) begin
        DOUT <= 0;
    end
    else if(read_en) begin
        //$display("[%3d] read  %07h to pos %0h", $time, FIFO[pRead], pRead);
        DOUT <= FIFO[pRead];
    end
end

integer i;
always @(posedge WR_CLK or negedge nRST) begin
    if(~nRST) begin
        for(i = 0; i < FIFO_DEPTH; i = i + 1) begin
            FIFO[i] <= 0;
        end
    end
    else if(write_en) begin
        FIFO[pWrite] <= DIN;
        //$display("[%3d] write %07h to pos %0h", $time, DIN, pWrite);
    end
end
endmodule
