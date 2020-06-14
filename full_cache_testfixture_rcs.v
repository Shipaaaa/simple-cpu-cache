`timescale 1 ns / 1 ps

`include "utils_ram_stub.v"
`include "full_cache.v"

module testbench_cache();

localparam TAG_SIZE         = 5;
localparam INDEX_SIZE       = 8;
localparam OFFSET_SIZE      = 3;

localparam ADDR_SIZE        = TAG_SIZE+INDEX_SIZE+OFFSET_SIZE;
localparam RAM_ADDR_SIZE    = TAG_SIZE+INDEX_SIZE;

localparam WORD_SIZE        = 32;
localparam RAM_WORD_SIZE    = 16;
localparam CASH_STR_WIDTH   = 64;

reg cache_clk               = 1'b0;
reg sys_clk                 = 1'b0;
reg ram_clk                 = 1'b0;

// inputs
reg    [ADDR_SIZE-1:0]      addr;
reg    [WORD_SIZE-1:0]      wdata;
reg    [3:0]                bval;
reg                         rd;
reg                         wr;
reg                         rst;

// ram connectors
wire                        ram_ack;
wire   [RAM_WORD_SIZE-1:0]  ram_data_in;
wire   [RAM_WORD_SIZE-1:0]  ram_data_out;
wire   [RAM_ADDR_SIZE-1:0]  ram_addr;
wire                        ram_aval;
wire                        ram_rnw;
wire                        rst_n;

// outputs
output [WORD_SIZE-1:0]      sys_rdata;
wire                        ack;
wire   [CASH_STR_WIDTH-1:0] backdoor;

assign                      rst_n = ~rst;

full_cache
    full_cache(
        .cache_clk(cache_clk),
        .cache_not_reset(rst_n),
        .sys_clk(sys_clk),
        .sys_rst_n(rst_n),
        .sys_addr(addr),
        .sys_wdata(wdata),
        .sys_rd(rd),
        .sys_wr(wr),
        .sys_bval(bval),
        .ram_clk(ram_clk),
        .ram_rst_n(rst_n),
        .ram_rdata(ram_data_in),
        .ram_rack(ram_ack),

        .sys_rdata(sys_rdata),
        .sys_ack(ack),
        .ram_addr(ram_addr),
        .ram_wdata(ram_data_out),
        .ram_avalid(ram_aval),
        .ram_rnw(ram_rnw)
    );

RAM # (RAM_ADDR_SIZE, RAM_WORD_SIZE, CASH_STR_WIDTH, 5.0) ram(
        .ram_wdata(ram_data_out),
        .ram_addr(ram_addr),
        .ram_avalid(ram_aval),
        .ram_rnw(ram_rnw),

        .ram_rdata(ram_data_in),
        .ram_ack(ram_ack),
        .ram_rst_n(rst_n),
        .ram_clk(ram_clk),
        .data_backdoor(backdoor)
    );


initial begin
    $dumpvars;      // Open for dump of signals
    $display("Test started...");   // Write to console
end

task expect_read;
    input [WORD_SIZE-1:0] exp_data;
    if (exp_data != sys_rdata) begin
        $display("<--- [%5d] rst=%b rd=%b wr=%b addr=%04x bval=%4b wdata=%08x sys_rdata=%08x/%08x",
                 $time, rst, rd, wr, addr, bval, wdata, sys_rdata, exp_data);
        $display("TEST FAILED");
        $finish;
    end else begin
        $display("<--- [%5d] rst=%b rd=%b wr=%b addr=%04x bval=%4b wdata=%08x sys_rdata=%08x",
                 $time, rst, rd, wr, addr, bval, wdata, sys_rdata);
    end
endtask

task expect_write;
    input [CASH_STR_WIDTH-1:0] exp_data;
    if (exp_data != backdoor) begin
        $display("<--- [%5d] rst=%b rd=%b wr=%b addr=%04x bval=%4b wdata=%08x data=%032x/%032x",
                 $time, rst, rd, wr, addr, bval, wdata, backdoor, exp_data);
        $display("TEST FAILED");
        $finish;
    end else begin
        $display("<--- [%5d] rst=%b rd=%b wr=%b addr=%04x bval=%4b wdata=%08x data=%032x",
                 $time, rst, rd, wr, addr, bval, wdata, backdoor);
    end
endtask

initial repeat (20000) begin #53 sys_clk   =~sys_clk;   end
initial repeat (10000) begin #16 cache_clk =~cache_clk; end
initial repeat (30000) begin #5  ram_clk   =~ram_clk;   end

initial @(negedge sys_clk) begin
    rst=1; rd=0; wr=0; addr=16'hABCD; bval=4'b1111; wdata=32'hdeadbeef; @(negedge sys_clk);
    rst=0; rd=1; wr=0; addr=16'hABCD; bval=4'b1111; wdata=32'hdeadbeef; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_read(16'h6000);              @(negedge sys_clk); // read miss
    rst=0; rd=1; wr=0; addr=16'hABCD; bval=4'b1111; wdata=32'hdeadbeef; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_read(16'h6000);              @(negedge sys_clk); // read hit
    rst=0; rd=0; wr=1; addr=16'hBBCD; bval=4'b1111; wdata=32'hdeadbeef; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'hdeadbeef10009bbc); @(negedge sys_clk); // write miss
    rst=0; rd=0; wr=1; addr=16'hABCD; bval=4'b1111; wdata=32'hdeadbeef; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'hdeadbeef10009abc); @(negedge sys_clk); // write hit
    rst=0; rd=1; wr=0; addr=16'hABCD; bval=4'b1111; wdata=32'hdeadbeef; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_read(16'hdead);              @(negedge sys_clk); // read hit, the same data
    rst=0; rd=0; wr=1; addr=16'hABC0; bval=4'b1111; wdata=32'hdeadf00d; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'hdeadbeefdeadf00d); @(negedge sys_clk); // write hit, same line
    rst=0; rd=0; wr=1; addr=16'hABC4; bval=4'b1001; wdata=32'hb44dc0d3; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'hdeadbeefdeadf00d); @(negedge sys_clk); // write hit, one byte
    rst=0; rd=0; wr=1; addr=16'hABC8; bval=4'b0010; wdata=32'hb44dc0d3; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'hdeadbeefdeadf00d); @(negedge sys_clk); // write hit, one byte

    rst=0; rd=0; wr=1; addr=16'hA00C; bval=4'b1111; wdata=32'ha000a000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'ha000a00010009a00); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'h700C; bval=4'b1111; wdata=32'h70007000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h7000700010009700); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'h100C; bval=4'b1111; wdata=32'h10001000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h1000100010009100); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'hF00C; bval=4'b1111; wdata=32'hf000f000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'hf000f00010009f00); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'hE00C; bval=4'b1111; wdata=32'he000e000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'he000e00010009e00); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'hA008; bval=4'b1111; wdata=32'ha000a000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h7000600010009a00); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'h1008; bval=4'b1111; wdata=32'h10001000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h1000100010009100); @(negedge sys_clk); // write hit,  bank X
    rst=0; rd=0; wr=1; addr=16'hF008; bval=4'b1111; wdata=32'hf000f000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'hf000f00010009f00); @(negedge sys_clk); // write hit,  bank X
    rst=0; rd=0; wr=1; addr=16'hE008; bval=4'b1111; wdata=32'he000e000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'he000e00010009e00); @(negedge sys_clk); // write hit,  bank X, get previously written instead of sudo-ram generated

    $display("TEST PASSED");
    $finish;
end

endmodule
