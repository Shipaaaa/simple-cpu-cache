`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:    17:35:21 06/03/2020
// Design Name:
// Module Name:    interface_ram_controller
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
module interface_ram_controller
       #(
           parameter ADDR_SIZE       = 13,
           parameter CACHE_STR_WIDTH = 64
       )
       (
           input                             clk,
           input                             not_reset,
           input                             cache_avalid,
           input       [ADDR_SIZE-1:0]       cache_addr,
           input                             cache_rnw,
           input                             fifo_empty,
           input                             fifo_full,
           input                             rfifo_empty,
           input       [CACHE_STR_WIDTH-1:0] cache_wdata,

           output reg                        write,
           output reg                        read,
           output reg                        cache_ack,
           output reg  [ADDR_SIZE-1:0]       ram_addr,
           output reg                        ram_rnw,
           output reg                        ram_avalid,
           output reg                        sr_load,
           output reg                        sr_mode,
           output reg                        sr_shift
       );

localparam S_IDLE       = 0;

localparam S_ADDR2FIFO  = 1;
localparam S_WAITACK    = 2;
localparam S_WAITACK1   = 14;
localparam S_FIFO2REG0  = 3;
localparam S_FIFO2REG1  = 4;
localparam S_FIFO2REG2  = 5;
localparam S_FIFO2REG3  = 6;
localparam S_ACK        = 13;

localparam S_WR2RAM     = 7;
localparam S_REG2FIFO0  = 8;
localparam S_REG2FIFO1  = 9;
localparam S_REG2FIFO2  = 10;
localparam S_REG2FIFO3  = 11;
localparam S_WR_LOAD    = 12;

reg [3:0] state;

always @(posedge clk or negedge not_reset) begin
    if(~not_reset) begin
        state <= S_IDLE;
        read <= 0;
        write <= 0;
        sr_load <= 0;
        sr_mode <= 0;
        sr_shift <= 0;
        ram_addr <= 0;
        ram_rnw <= 0;
        ram_avalid <= 0;
        cache_ack <= 0;
    end
    else begin
        case(state)
            S_IDLE: begin
                cache_ack <= 0;
                if((cache_avalid == 1) && (cache_rnw == 1)) begin
                    state <= S_ADDR2FIFO;
                end
                else if((cache_avalid == 1) && (cache_rnw == 0)) begin
                    state <= S_WR_LOAD;
                end
            end
            /* Read from RAM*/
            S_ADDR2FIFO: begin
                ram_addr <= cache_addr;
                ram_rnw <= 1;
                write <= 1;
                ram_avalid <= 1;
                state <= S_WAITACK1;
            end
            S_WAITACK1: begin
                ram_avalid <= 0;
                ram_rnw <= 0;
                state <= S_WAITACK;
            end
            S_WAITACK: begin
                write <= 0;
                if(fifo_empty) begin
                    sr_mode <= 1;
                    sr_load <= 1;
                    sr_shift <= 0;
                    read <= 1;
                    state <= S_FIFO2REG0;
                end
            end
            S_FIFO2REG0: begin
                state <= S_FIFO2REG1;
            end
            S_FIFO2REG1: begin
                state <= S_FIFO2REG2;
            end
            S_FIFO2REG2: begin
                state <= S_FIFO2REG3;
            end
            S_FIFO2REG3: begin
                state <= S_ACK;
            end
            S_ACK: begin
                cache_ack <= 1;
                sr_load <= 0;
                read <= 0;
                state <= S_IDLE;
            end
            S_WR_LOAD: begin
                sr_mode <= 0;
                ram_addr <= cache_addr;
                ram_rnw <= 0;
                sr_load <= 1;
                state <= S_WR2RAM;
            end
            /* Write to RAM */
            S_WR2RAM: begin
                if(!fifo_full) begin
                    sr_load <= 0;
                    sr_shift <= 1;
                    write <= 1;
                    state <= S_REG2FIFO0;
                    ram_avalid <= 1;
                end
            end
            S_REG2FIFO0: begin
                ram_avalid <= 0;
                state <= S_REG2FIFO1;
            end
            S_REG2FIFO1: begin
                state <= S_REG2FIFO2;
            end
            S_REG2FIFO2: begin
                state <= S_REG2FIFO3;
            end
            S_REG2FIFO3: begin
                write <= 0;
                sr_shift <= 0;
                read <= 1;
                if(~rfifo_empty) begin
                    read <= 0;
                    state <= S_IDLE;
                end
            end
        endcase
    end
end

endmodule
