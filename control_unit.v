`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       v.shipugin
//
// Create Date:    20:11:25 05/06/2020
// Design Name:    control_unit
// Module Name:    Y:/my_project/v_shipugin_cache/control_unit.v
// Project Name:   v_shipugin_cache
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
module control_unit(
           input         clk,
           input         not_reset,

           input         sys_rd,
           input         sys_wr,

           input         is_hit,
           input         need_use_fifo,     // Что использовать chan или fifo_chan

           input         ram_ack,       

           output reg    ram_avalid,        // ram_avalid - сигнал, разрешающий взаимодействие с ОП
           output reg    ram_rnw,           // ram_rnw - read(1), write(0)

           output reg    rewrite_tag,       // rewrite_tag - перезапись тэга
           output reg    need_write_data,   // запись в память тэгов

           output reg    select_data,
           output reg    select_channel,

           output reg    sys_ack
       );

parameter IDLE_STATE    	= 0;
parameter RCACHE_STATE      = 1;
parameter WCACHE_STATE      = 2;
parameter FIFO_STATE        = 3;
parameter RRAM_STATE        = 4;
parameter UPDATE_STATE      = 5;
parameter ACK_STATE         = 6;

reg [3:0] state;

always @* begin
    select_channel <= !is_hit;

    case(state)
        IDLE_STATE: begin
            need_write_data <= 0;
            rewrite_tag <= 0;
            sys_ack <= 0;
            ram_rnw <= 1;
            ram_avalid <= 0;
        end

        RCACHE_STATE: begin
            select_data <= 0;
            rewrite_tag <= 0;
            need_write_data <= 0;
        end

        WCACHE_STATE: begin
            need_write_data <= 1;
        end

        FIFO_STATE: begin
            ram_rnw <= 0;
            ram_avalid <= 1;
        end

        RRAM_STATE: begin
            ram_rnw <= 1;
            ram_avalid <= 1;
        end

        UPDATE_STATE: begin
            select_data <= 1;
            rewrite_tag <= 1;
            need_write_data <= 1;
            ram_avalid <= 0;
        end

        ACK_STATE: begin
            sys_ack <= 1;
            rewrite_tag <= 0;
            need_write_data <= 0;
            select_data <= 0;
        end
    endcase
end

always @(posedge clk or negedge not_reset) begin
    if(!not_reset) begin
        state <= IDLE_STATE;
    end
    else begin
        case(state)
            IDLE_STATE: begin
                if(is_hit) begin
                    if(sys_rd ^ sys_wr) begin
                        state <= RCACHE_STATE;
                    end;
                end
                else if(sys_rd ^ sys_wr) begin
                    if(need_use_fifo) begin
                        state <= RCACHE_STATE;
                    end
                    else begin
                        state <= RRAM_STATE;
                    end
                end
            end

            RCACHE_STATE: begin
                if(need_use_fifo) begin
                    state <= FIFO_STATE;
                end else
                    if(sys_rd) begin
                        state <= ACK_STATE;
                    end
                    else if(sys_wr) begin
                        state <= WCACHE_STATE;
                    end
            end

            WCACHE_STATE: begin
                state <= ACK_STATE;
            end

            FIFO_STATE: begin
                if(ram_ack) begin
                    state <= RRAM_STATE;
                end
            end

            RRAM_STATE: begin
                if(ram_ack) begin
                    state <= UPDATE_STATE;
                end
            end

            UPDATE_STATE: begin
                if(sys_rd ^ sys_wr) begin
                    state <= RCACHE_STATE;
                end
            end

            ACK_STATE: begin
                if(sys_rd == 0 && sys_wr == 0) begin
                    state <= IDLE_STATE;
                end
            end
        endcase
    end
end

endmodule
