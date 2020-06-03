`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date:   18:54:32 05/27/2020
// Design Name:   control_unit
// Module Name:   Y:/my_project/v_shipugin_cache/control_unit_testfixture.v
// Project Name:  v_shipugin_cache
// Target Device:
// Tool versions:
// Description:
//
// Verilog Test Fixture created by ISE for module: control_unit
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////

module control_unit_testfixture;

// Inputs
logic clk = 1'b0;

reg not_reset;

reg sys_rd;
reg sys_wr;

reg hit;
reg fifo;
reg ram_ack;

// Outputs
wire ram_avalid;
wire ram_wr;

wire wr_tag;
wire wr;

wire select_data;
wire select_channel;

wire sys_ack;

always #1 begin
    clk = ~clk;
end

// Instantiate the Unit Under Test (UUT)
control_unit uut (
                 .clk(clk),
                 .not_reset(not_reset),
                 .sys_rd(sys_rd),
                 .sys_wr(sys_wr),
                 .hit(hit),
                 .fifo(fifo),
                 .ram_ack(ram_ack),
                 .ram_avalid(ram_avalid),
                 .ram_wr(ram_wr),
                 .wr_tag(wr_tag),
                 .wr(wr),
                 .select_data(select_data),
                 .select_channel(select_channel),
                 .sys_ack(sys_ack)
             );

initial begin
    $dumpvars;
    $display("Test started...");
end

task assert;

    input expected_ram_avalid;
    input expected_ram_wr;

    input expected_wr_tag;
    input expected_wr;

    input expected_select_data;
    input expected_select_channel;

    input expected_sys_ack;

    if (
        ram_avalid !== expected_ram_avalid ||
        ram_wr !== expected_ram_wr ||
        wr_tag !== expected_wr_tag ||
        wr !== expected_wr ||
        select_data !== expected_select_data ||
        select_channel !== expected_select_channel ||
        sys_ack !== expected_sys_ack
    ) begin

        $display("%c[1;31m", 27);
        $display("TEST FAILED :(");

        $display(
                "[%0d] not_reset=%b, sys_rd=%b, sys_wr=%b, hit=%b, fifo=%b, ram_ack=%b, ram_avalid=%b, ram_wr=%b, wr_tag=%b, wr=%b, select_data=%b, select_channel=%b, sys_ack=%b",
                $time, not_reset, sys_rd, sys_wr, hit, fifo, ram_ack, ram_avalid, ram_wr, wr_tag, wr, select_data, select_channel, sys_ack
            );

        if (ram_avalid !== expected_ram_avalid) begin
            $display("expected_ram_avalid should be %b, but it is %b", expected_ram_avalid, ram_avalid);
        end

        if (ram_wr !== expected_ram_wr) begin
            $display("expected_ram_wr should be %b, but it is %b", expected_ram_wr, ram_wr);
        end

        if (wr_tag !== expected_wr_tag) begin
            $display("expected_wr_tag should be %b, but it is %b", expected_wr_tag, wr_tag);
        end

        if (wr !== expected_wr) begin
            $display("expected_wr should be %b, but it is %b", expected_wr, wr);
        end

        if (select_data !== expected_select_data) begin
            $display("expected_select_data should be %b, but it is %b", expected_select_data, select_data);
        end

        if (select_channel !== expected_select_channel) begin
            $display("expected_select_channel should be %b, but it is %b", expected_select_channel, select_channel);
        end

        if (sys_ack !== expected_sys_ack) begin
            $display("expected_sys_ack should be %b, but it is %b", expected_sys_ack, sys_ack);
        end

        $display("%c[0m",27);
        $finish;
    end
    else begin

        $display("%c[1;34m",27);

        $display(
                "[%0d] not_reset=%b, sys_rd=%b, sys_wr=%b, hit=%b, fifo=%b, ram_ack=%b, ram_avalid=%b, ram_wr=%b, wr_tag=%b, wr=%b, select_data=%b, select_channel=%b, sys_ack=%b",
                $time, not_reset, sys_rd, sys_wr, hit, fifo, ram_ack, ram_avalid, ram_wr, wr_tag, wr, select_data, select_channel, sys_ack
            );

        $display("%c[0m",27);
    end
endtask

initial @(negedge clk) begin

    // assert(
    //		expected_ram_avalid;
    // 		expected_ram_wr;
    //		expected_wr_tag;
    //		expected_wr;
    // 		expected_select_data;
    //		expected_select_channel;
    //		expected_sys_ack
    // );

    not_reset=0; sys_rd=0; sys_wr=0; hit=0; fifo=0; ram_ack=0; @(negedge clk);

    // Проверка чтения из кэша
    not_reset=1; sys_rd=1; sys_wr=0; hit=1; fifo=0; ram_ack=0; @(negedge clk) assert(0, 0, 0, 0, 0, 0, 0);
    not_reset=1; sys_rd=1; sys_wr=0; hit=1; fifo=0; ram_ack=0; @(negedge clk) assert(0, 0, 0, 0, 0, 0, 1);

	// Проверка записи в кэш
	not_reset=1; sys_rd=0; sys_wr=1; hit=1; fifo=0; ram_ack=0; @(negedge clk) assert(0, 0, 0, 0, 0, 0, 0);
    not_reset=1; sys_rd=0; sys_wr=1; hit=1; fifo=0; ram_ack=0; @(negedge clk) assert(0, 0, 0, 1, 0, 0, 1);

    $display("%c[1;34m", 27);
    $display("TEST PASSED :)");
    $display("%c[0m", 27);

    $finish;
end

endmodule

