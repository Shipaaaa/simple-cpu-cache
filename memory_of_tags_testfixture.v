`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: 	  v.shipugin
//
// Create Date:   01:48:18 04/15/2020
// Design Name:   memory_of_tags
// Module Name:   Y:/my_project/v_shipugin_cache/memory_of_tags_testfixture.v
// Project Name:  v_shipugin_cache
// Target Device:
// Tool versions:
// Description:
//
// Verilog Test Fixture created by ISE for module: memory_of_tags
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

module memory_of_tags_testfixture;

logic clk = 1'b0;

reg not_reset;
reg [4:0] tag;
reg [7:0] index;
reg rewrite_tag;

wire is_hit;

wire need_use_fifo;
wire [1:0] channel;
wire [1:0] fifo_channel;

wire [4:0] fifo_tag_for_flush;

always #1 begin
    clk = ~clk;
end

memory_of_tags uut (
                   .clk(clk),
                   .not_reset(not_reset),
                   .tag(tag),
                   .index(index),
                   .rewrite_tag(rewrite_tag),
                   .is_hit(is_hit),
                   .need_use_fifo(need_use_fifo),
                   .channel(channel),
                   .fifo_channel(fifo_channel),
                   .fifo_tag_for_flush(fifo_tag_for_flush)
               );

initial begin
    $dumpvars;
    $display("Test started...");
end

task assert;

    input expected_is_hit;
    input expected_need_use_fifo;
    input [1:0] expected_channel;
    input [1:0] expected_fifo_channel;

    if (
        is_hit !== expected_is_hit ||
        need_use_fifo !== expected_need_use_fifo ||
        channel !== expected_channel ||
        fifo_channel !== expected_fifo_channel
    ) begin

        $display("%c[1;31m", 27);
        $display("TEST FAILED :(");

        $display(
                "[%0d] not_reset=%b, tag=%b, index=%x, rewrite_tag=%b, is_hit=%b, need_use_fifo=%b, channel=%x, fifo_channel=%x, fifo_tag_for_flush=%x",
                $time, not_reset, tag, index, rewrite_tag, is_hit, need_use_fifo, channel, fifo_channel, fifo_tag_for_flush
            );

        if (is_hit !== expected_is_hit) begin
            $display("expected_is_hit should be %b, but it is %b", expected_is_hit, is_hit);
        end

        if (need_use_fifo !== expected_need_use_fifo) begin
            $display("expected_need_use_fifo should be %b, but it is %b", expected_need_use_fifo, need_use_fifo);
        end

        if (channel !== expected_channel) begin
            $display("expected_channel should be %b, but it is %b", expected_channel, channel);
        end

        if (fifo_channel !== expected_fifo_channel) begin
            $display("expected_fifo_channel should be %b, but it is %b", expected_fifo_channel, fifo_channel);
        end
        $display("%c[0m",27);
        $finish;
    end
    else begin

        $display("%c[1;34m",27);

        $display(
                "[%0d] not_reset=%b, tag=%b, index=%x, rewrite_tag=%b, is_hit=%b, need_use_fifo=%b, channel=%x, fifo_channel=%x, fifo_tag_for_flush=%x",
                $time, not_reset, tag, index, rewrite_tag, is_hit, need_use_fifo, channel, fifo_channel, fifo_tag_for_flush
            );

        $display("%c[0m",27);
    end
endtask

initial @(negedge clk) begin

    // assert(
    //     expected_is_hit,
    //     expected_need_use_fifo;
    //     [1:0] expected_channel;
    //     [1:0] expected_fifo_channel
    // );

    not_reset=0; tag=5'b00000; index=7'b0000000; rewrite_tag=0; @(negedge clk);

    // Промах памяти тэгов по индексу 001
    not_reset=1; tag=5'b00000; index=7'b0000001; rewrite_tag=0; @(negedge clk) assert(0, 0, 0, 0);
    not_reset=1; tag=5'b00000; index=7'b0000001; rewrite_tag=1; @(negedge clk) assert(1, 0, 0, 1);
    not_reset=1; tag=5'b00001; index=7'b0000001; rewrite_tag=0; @(negedge clk) assert(0, 0, 0, 1);
    not_reset=1; tag=5'b00001; index=7'b0000001; rewrite_tag=1; @(negedge clk) assert(1, 0, 1, 2);
    not_reset=1; tag=5'b00010; index=7'b0000001; rewrite_tag=1; @(negedge clk) assert(1, 0, 2, 3);
    not_reset=1; tag=5'b00011; index=7'b0000001; rewrite_tag=1; @(negedge clk) assert(1, 0, 3, 0);
    not_reset=1; tag=5'b00100; index=7'b0000001; rewrite_tag=1; @(negedge clk) assert(1, 0, 0, 1);
    not_reset=1; tag=5'b00101; index=7'b0000001; rewrite_tag=1; @(negedge clk) assert(1, 0, 1, 2);
    not_reset=1; tag=5'b00110; index=7'b0000001; rewrite_tag=1; @(negedge clk) assert(1, 0, 2, 3);
    not_reset=1; tag=5'b00011; index=7'b0000001; rewrite_tag=0; @(negedge clk) assert(1, 0, 3, 3);

    // Записываем в заполененную память с выталкиванием
    not_reset=1; tag=5'b01000; index=7'b0000001; rewrite_tag=0; @(negedge clk) assert(0, 1, 0, 3);
    not_reset=1; tag=5'b01000; index=7'b0000001; rewrite_tag=1; @(negedge clk) assert(1, 0, 3, 0);
    not_reset=1; tag=5'b00000; index=7'b0000001; rewrite_tag=0; @(negedge clk) assert(0, 1, 0, 0);
    not_reset=1; tag=5'b00110; index=7'b0000001; rewrite_tag=0; @(negedge clk) assert(1, 0, 2, 0);
    not_reset=1; tag=5'b01001; index=7'b0000001; rewrite_tag=0; @(negedge clk) assert(0, 1, 0, 0);
    not_reset=1; tag=5'b01001; index=7'b0000001; rewrite_tag=1; @(negedge clk) assert(1, 0, 0, 1);
    not_reset=1; tag=5'b01000; index=7'b0000001; rewrite_tag=0; @(negedge clk) assert(1, 0, 3, 1);

    // Промах памяти тэгов по индексу 101
    not_reset=1; tag=5'b00010; index=7'b0000101; rewrite_tag=0; @(negedge clk) assert(0, 0, 0, 0);
    not_reset=1; tag=5'b00010; index=7'b0000101; rewrite_tag=1; @(negedge clk) assert(1, 0, 0, 1);
    not_reset=1; tag=5'b00011; index=7'b0000101; rewrite_tag=0; @(negedge clk) assert(0, 0, 0, 1);
    not_reset=1; tag=5'b00011; index=7'b0000101; rewrite_tag=1; @(negedge clk) assert(1, 0, 1, 2);
    not_reset=1; tag=5'b00100; index=7'b0000101; rewrite_tag=1; @(negedge clk) assert(1, 0, 2, 3);
    not_reset=1; tag=5'b00101; index=7'b0000101; rewrite_tag=1; @(negedge clk) assert(1, 0, 3, 0);
    not_reset=1; tag=5'b00110; index=7'b0000101; rewrite_tag=1; @(negedge clk) assert(1, 0, 0, 1);
    not_reset=1; tag=5'b00111; index=7'b0000101; rewrite_tag=1; @(negedge clk) assert(1, 0, 1, 2);
    not_reset=1; tag=5'b01000; index=7'b0000101; rewrite_tag=1; @(negedge clk) assert(1, 0, 2, 3);
    not_reset=1; tag=5'b01001; index=7'b0000101; rewrite_tag=1; @(negedge clk) assert(1, 0, 3, 0);
    not_reset=1; tag=5'b01010; index=7'b0000101; rewrite_tag=0; @(negedge clk) assert(0, 1, 0, 0);

    // Записываем в заполененную память с выталкиванием

    not_reset=1; tag=5'b11000; index=7'b0000101; rewrite_tag=0; @(negedge clk) assert(0, 1, 0, 0);
    not_reset=1; tag=5'b11000; index=7'b0000101; rewrite_tag=1; @(negedge clk) assert(1, 0, 0, 1);
    not_reset=1; tag=5'b10010; index=7'b0000101; rewrite_tag=0; @(negedge clk) assert(0, 1, 0, 1);
    not_reset=1; tag=5'b10110; index=7'b0000101; rewrite_tag=0; @(negedge clk) assert(0, 1, 0, 1);
    not_reset=1; tag=5'b11001; index=7'b0000101; rewrite_tag=0; @(negedge clk) assert(0, 1, 0, 1);
    not_reset=1; tag=5'b11001; index=7'b0000101; rewrite_tag=1; @(negedge clk) assert(1, 0, 1, 2);
    not_reset=1; tag=5'b11000; index=7'b0000001; rewrite_tag=0; @(negedge clk) assert(1, 1, 0, 1);

    $display("%c[1;34m", 27);
    $display("TEST PASSED :)");
    $display("%c[0m", 27);

    $finish;
end

endmodule
