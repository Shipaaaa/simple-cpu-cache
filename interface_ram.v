`timescale 1ns / 1ps
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
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module interface_ram
       #(
           parameter CASH_MEM_WIDTH = 128,
           parameter WORD_SIZE = 32,
           parameter ADDR_SIZE = 14
       )
       (
           input c_clk,
           input ram_clk,
           input c_nReset,

           input c_aval,
           input c_wr,
           input ram_ack,
           input [CASH_MEM_WIDTH - 1:0] c_data_in,
           input [WORD_SIZE - 1:0]  ram_data_in,
           input [ADDR_SIZE - 1:0]  c_addr,

           output ram_aval,
           output ram_wr,
           output reg c_ack,
           output [CASH_MEM_WIDTH - 1:0] c_data_out,
           output [WORD_SIZE - 1:0]  ram_data_out,
           output [ADDR_SIZE - 1:0]  ram_addr
       );

// reg [11:0]  input_addr_reg;
reg [CASH_MEM_WIDTH - 1:0] io_shift_reg;
wire [WORD_SIZE - 1:0] to_rd_fifo;
wire [WORD_SIZE + ADDR_SIZE + 1:0] to_wr_fifo;
wire [WORD_SIZE - 1:0] from_rd_fifo;
wire [WORD_SIZE + ADDR_SIZE + 1:0] from_wr_fifo;

reg mode_wr;
reg write_rd_fifo;
reg write_wr_fifo;

wire read_rd_fifo;
wire read_wr_fifo;
wire rd_empty;
wire wr_empty;

assign read_rd_fifo = 1;
assign read_wr_fifo = 1;

wire n_rst;

async_fifo #(32, 4, 16) RamReadFIFO (
               .nRST(c_nReset),          // input rst
               .WR_CLK(ram_clk),         // input wr_clk
               .RD_CLK(c_clk),           // input rd_clk
               .DIN(to_rd_fifo),         // input [15 : 0] din
               .write(write_rd_fifo),    // input wr_en
               .read(read_rd_fifo),      // input rd_en
               .DOUT(from_rd_fifo),      // output [15 : 0] dout
               .EMPTY(rd_empty)          // output empty
           );

async_fifo #(48, 4, 16) RamWriteFIFO (
               .nRST(c_nReset),          // input rst
               .WR_CLK(c_clk),           // input wr_clk
               .RD_CLK(ram_clk),         // input rd_clk
               .DIN(to_wr_fifo),         // input [29 : 0] din
               .write(write_wr_fifo),    // input wr_en
               .read(read_wr_fifo),      // input rd_en
               .DOUT(from_wr_fifo),      // output [29 : 0] dout
               .EMPTY(wr_empty)          // output empty
           );

parameter S_IDLE = 0;
parameter S_WAIT_ACK = 1;
parameter S_READ = 2;
parameter S_WRITE = 3;

reg [2:0] state;
reg [2:0] rw_ctr;
reg wr_empty_buff;
reg rd_empty_buff;
reg c_aval_state;

reg c_aval_buf;


assign to_wr_fifo[47]      = c_aval_buf;
assign to_wr_fifo[46]      = state == S_IDLE ?  c_wr : (state == S_WRITE ? 1 : 0);
assign to_wr_fifo[45:32]   = c_addr;
assign to_wr_fifo[31:0]    = io_shift_reg[31:0];
assign c_data_out          = io_shift_reg;


always @* begin


    case(state)
        S_IDLE: begin
            write_wr_fifo <= 0;
            if (c_aval) begin
                c_ack <= 0;
            end
        end

        S_READ: begin
            if (!rd_empty_buff) begin
                if (rw_ctr == 3) begin
                    c_ack <= 1;
                end
            end
        end

        S_WRITE: begin
            write_wr_fifo <= 1;
            if (rw_ctr == 3) begin
                c_ack <= 1;
            end
        end
    endcase
end

always @(posedge c_clk) begin
    //write_wr_fifo <= (state == S_WRITE);// || (state == S_IDLE && c_aval);
    rd_empty_buff <= rd_empty;

    if (!c_nReset) begin
        state         <= S_IDLE;
        rw_ctr        <= 0;
        io_shift_reg  <= 1;
        //wr_empty_buff <= 1;
        rd_empty_buff <= 1;
        c_aval_buf    <= 0;
    end


    case(state)
        S_IDLE: begin

            if (c_aval) begin
                //$display("got aval: wr=%b", c_wr);
                state <= c_wr ? S_WRITE : S_READ;
                if (c_wr) io_shift_reg <= c_data_in;
                rw_ctr <= 0;
                mode_wr <= c_wr;
                c_aval_buf <= 1;
            end else
                c_aval_buf <= 0;

        end
        S_WAIT_ACK: begin
            c_aval_buf <= 0;
            //$display("waiting ack: wr=%b empty=%b", mode_wr, rd_empty);
            if (!rd_empty_buff) begin
                if (mode_wr) begin
                    state <= S_IDLE;
                end else
                    state <= S_READ;
            end
        end
        S_READ: begin
            c_aval_buf <= 0;
            if (!rd_empty_buff) begin
                //$display("reading: got data %x", from_rd_fifo[31:0]);
                io_shift_reg <= {from_rd_fifo[31:0], io_shift_reg[127:32]};
                if (rw_ctr == 3) begin
                    state <= S_IDLE;
                end else
                    rw_ctr <= rw_ctr + 1;
            end

        end
        S_WRITE: begin
            c_aval_buf <= 0;
            io_shift_reg <= io_shift_reg >> 32;
            if (rw_ctr == 3) begin
                state <= S_IDLE;
            end else
                rw_ctr <= rw_ctr + 1;
        end
    endcase
end

wire recv_ram_wr;
wire recv_ram_aval;

assign recv_ram_aval = from_wr_fifo[47];
assign recv_ram_wr   = from_wr_fifo[46];
assign ram_addr      = from_wr_fifo[45:32];
assign ram_data_out  = from_wr_fifo[31:0];

assign ram_aval      = wr_empty_buff ? 0 : recv_ram_aval;
assign ram_wr        = recv_ram_wr;


assign to_rd_fifo[WORD_SIZE - 1:0]  = ram_data_in;

always @(posedge ram_clk) begin
    wr_empty_buff <= wr_empty;
    write_rd_fifo <= ram_ack && state == S_READ;
end
endmodule
