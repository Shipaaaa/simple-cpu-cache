`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:       v.shipugin
//
// Create Date:    22:22:28 04/13/2020
// Design Name:    memory_of_tags
// Module Name:    Y:/my_project/v_shipugin_cache/memory_of_tags.v
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
module bank_of_tags
       #(
           parameter TAG_SIZE = 5,
           parameter CHANNELS_COUNT = 4,
           parameter CH_NUM_WIDTH = 2
       )
       (
           input                         clk,
           input                         not_reset,
           input [TAG_SIZE-1:0]          tag,
           input                         rewrite_tag,

           output                        is_hit,
           output                        need_use_fifo,

           output reg [CH_NUM_WIDTH-1:0] channel,
           output reg [CH_NUM_WIDTH-1:0] fifo_channel,
           output reg [TAG_SIZE-1:0]     fifo_tag_for_flush
       );

reg     [TAG_SIZE-1:0]       memories_of_tags [CHANNELS_COUNT-1:0];
reg     [CH_NUM_WIDTH-1:0]   current_fifo;
reg     [CHANNELS_COUNT-1:0] valid_tags;
wire    [CHANNELS_COUNT-1:0] hits;

integer i;
genvar j;
wire is_full = & valid_tags;

always @* begin
    casex(hits)
        4'bxxx1: channel = 0;
        4'bxx1x: channel = 1;
        4'bx1xx: channel = 2;
        4'b1xxx: channel = 3;
        default: channel = 0;
    endcase
end

always @* begin
    fifo_channel = current_fifo;
    fifo_tag_for_flush = memories_of_tags[current_fifo];
end

generate
    for(j = 0; j < CHANNELS_COUNT; j = j + 1) begin : gen_hits
        assign hits[j] = (valid_tags[j] && (memories_of_tags[j] == tag));
    end
    endgenerate

        assign is_hit  = |hits;
assign need_use_fifo = !is_hit && is_full;

always @(posedge clk or negedge not_reset) begin
    if (!not_reset) begin
        valid_tags   <= 4'b0;
        current_fifo <= 0;

        for(i = 0; i < CHANNELS_COUNT; i = i + 1) begin
            memories_of_tags[i] <= 5'b0;
        end
    end
    else if (rewrite_tag) begin
        if (is_hit) begin
            memories_of_tags[channel] <= tag;
            valid_tags[channel]       <= 1;
        end
        else begin
            memories_of_tags[current_fifo] <= tag;
            valid_tags[current_fifo]       <= 1;
            current_fifo                   <= current_fifo + 1;
        end
    end
end
endmodule

module memory_of_tags
    #(
        parameter TAG_SIZE = 5,
        parameter INDEX_SIZE = 8,
        parameter CH_NUM_WIDTH = 2,
        parameter BANKS_COUNT = 256
    )
    (
        input                         clk,
        input                         not_reset,
        input [TAG_SIZE-1:0]          tag,
        input [INDEX_SIZE-1:0]        index,
        input                         rewrite_tag,

        output                        is_hit,
        output                        need_use_fifo,

        output reg [CH_NUM_WIDTH-1:0] channel,
        output reg [CH_NUM_WIDTH-1:0] fifo_channel,
        output reg [TAG_SIZE-1:0]     fifo_tag_for_flush
    );


wire [BANKS_COUNT-1:0] hits;

assign is_hit = | hits;
assign need_use_fifo = need_use_fifos[index];

wire [BANKS_COUNT-1:0]  tags_for_write;
wire [BANKS_COUNT-1:0]  need_use_fifos;

wire [CH_NUM_WIDTH-1:0] channels [BANKS_COUNT-1:0];
wire [CH_NUM_WIDTH-1:0] fifo_channels [BANKS_COUNT-1:0];
wire [TAG_SIZE-1:0]     fifo_tags_for_flush [BANKS_COUNT-1:0];

genvar i;
integer j;

for(i = 0; i < BANKS_COUNT; i = i + 1) begin : gen_writes
    assign tags_for_write[i] = (index == i) & rewrite_tag;
end


always @* begin
    for(j = 0; j < BANKS_COUNT; j = j + 1) begin
        if (index == j) begin
            channel = channels[j];
            fifo_channel = fifo_channels[j];
            fifo_tag_for_flush = fifo_tags_for_flush[j];
        end
    end
end


for(i = 0; i < BANKS_COUNT; i = i + 1) begin : gen_banks
    bank_of_tags bank(
                     .tag(tag),
                     .clk(clk),
                     .not_reset(not_reset),
                     .rewrite_tag(tags_for_write[i]),
                     .is_hit(hits[i]),
                     .need_use_fifo(need_use_fifos[i]),
                     .channel(channels[i]),
                     .fifo_channel(fifo_channels[i]),
                     .fifo_tag_for_flush(fifo_tags_for_flush[i])
                 );
end

endmodule
