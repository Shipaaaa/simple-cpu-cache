`timescale 1 ns / 1 ps

`include "utils_ram_stub.v"
`include "full_cache.v"

module testbench_cache();

localparam TAG_SIZE          = 5;
localparam INDEX_SIZE        = 8;
localparam OFFSET_SIZE       = 3;

localparam ADDR_SIZE         = TAG_SIZE+INDEX_SIZE+OFFSET_SIZE;
localparam RAM_ADDR_SIZE     = TAG_SIZE+INDEX_SIZE;

localparam WORD_SIZE         = 32;
localparam RAM_WORD_SIZE     = 16;
localparam CACHE_STR_WIDTH   = 64;

reg cache_clk                = 1'b0;
reg sys_clk                  = 1'b0;
reg ram_clk                  = 1'b0;

// inputs
reg    [ADDR_SIZE-1:0]       addr;
reg    [WORD_SIZE-1:0]       wdata;
reg    [3:0]                 bval;
reg                          rd;
reg                          wr;
reg                          rst;

// ram connectors
wire                         ram_ack;
wire   [RAM_WORD_SIZE-1:0]   ram_data_in;
wire   [RAM_WORD_SIZE-1:0]   ram_data_out;
wire   [RAM_ADDR_SIZE-1:0]   ram_addr;
wire                         ram_aval;
wire                         ram_rnw;
wire                         rst_n;

// outputs
output [WORD_SIZE-1:0]       sys_rdata;
wire                         ack;
wire   [CACHE_STR_WIDTH-1:0] backdoor;

assign                       rst_n = ~rst;

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

RAM # (RAM_ADDR_SIZE, RAM_WORD_SIZE, CACHE_STR_WIDTH, 5.0) ram(
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
        $display("---> read [%5d] rst=%b; rd=%b; wr=%b; addr=16'h%04x; bval=4'b%4b; wdata=32'h%08x; sys_rdata=%08x/%08x;",
                 $time, rst, rd, wr, addr, bval, wdata, sys_rdata, exp_data);
        $display("TEST FAILED");
        $finish;
    end else begin
        $display("---> read [%5d] rst=%b; rd=%b; wr=%b; addr=16'h%04x; bval=4'b%4b; wdata=32'h%08x; sys_rdata=%08x;",
                 $time, rst, rd, wr, addr, bval, wdata, sys_rdata);
    end
endtask

task expect_write;
    input [CACHE_STR_WIDTH-1:0] exp_data;
    if (exp_data != backdoor) begin
        $display("<--- write [%5d] rst=%b; rd=%b; wr=%b; addr=16'h%04x; bval=4'b%4b; wdata=32'h%08x; data=%016x/%016x;",
                 $time, rst, rd, wr, addr, bval, wdata, backdoor, exp_data);
        $display("TEST FAILED");
        $finish;
    end else begin
        $display("<--- write [%5d] rst=%b; rd=%b; wr=%b; addr=16'h%04x; bval=4'b%4b; wdata=32'h%08x; data=%016x;",
                 $time, rst, rd, wr, addr, bval, wdata, backdoor);
    end
endtask

initial repeat (20000) begin #16 sys_clk   =~sys_clk;   end
initial repeat (10000) begin #16 cache_clk =~cache_clk; end
initial repeat (30000) begin #16 ram_clk   =~ram_clk;   end


initial @(negedge sys_clk) begin
    rst=1; rd=0; wr=0; addr=16'b0000000000000000; bval=4'b0000; wdata=32'h00000000; @(negedge sys_clk);
    rst=0; rd=1; wr=0; addr=16'b0000100000001000; bval=4'b0000; wdata=32'h00000000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_read(32'h1000080f);          @(negedge sys_clk); // read miss
    rst=0; rd=1; wr=0; addr=16'b0000100000001000; bval=4'b0000; wdata=32'h00000000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_read(32'h1000080f);          @(negedge sys_clk); // read hit
    rst=0; rd=0; wr=1; addr=16'b0001100000011100; bval=4'b1111; wdata=32'hBEEFF00D; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000080f); @(negedge sys_clk); // write miss
    rst=0; rd=0; wr=1; addr=16'b0001100000011100; bval=4'b1111; wdata=32'hBEEFF00D; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000181f); @(negedge sys_clk); // write hit
    rst=0; rd=1; wr=0; addr=16'b0001100000011100; bval=4'b0000; wdata=32'h00000000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_read(32'hbeeff00d);          @(negedge sys_clk); // read hit, the same data
    rst=0; rd=0; wr=1; addr=16'b0001100000011000; bval=4'b1111; wdata=32'hBEEFF00D; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000181f); @(negedge sys_clk); // write hit, same line
    rst=0; rd=0; wr=1; addr=16'b0011100000011000; bval=4'b0001; wdata=32'hBEEFF00D; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000381f); @(negedge sys_clk); // write hit, one byte
    rst=0; rd=0; wr=1; addr=16'b0001100000011000; bval=4'b0010; wdata=32'hBEEFF00D; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000381f); @(negedge sys_clk); // write hit, one byte

    rst=0; rd=0; wr=1; addr=16'b1111100000111000; bval=4'b1111; wdata=32'ha000a000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000381f); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'b1111100001011000; bval=4'b1111; wdata=32'h70007000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000f83f); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'b1111100010011000; bval=4'b1111; wdata=32'h10001000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000f83f); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'b1111100100011000; bval=4'b1111; wdata=32'hf000f000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000f83f); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'b1111101000011000; bval=4'b1111; wdata=32'he000e000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000f83f); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'b1111110000011000; bval=4'b1111; wdata=32'ha000a000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000f83f); @(negedge sys_clk); // write miss, bank X
    rst=0; rd=0; wr=1; addr=16'b1111100000111000; bval=4'b1111; wdata=32'h10001000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000f83f); @(negedge sys_clk); // write hit,  bank X
    rst=0; rd=0; wr=1; addr=16'b1111100001011000; bval=4'b1111; wdata=32'hf000f000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000f83f); @(negedge sys_clk); // write hit,  bank X
    rst=0; rd=0; wr=1; addr=16'b1111100000011000; bval=4'b1111; wdata=32'he000e000; @(negedge sys_clk) rd=0; wr=0; @(negedge ack) expect_write(64'h300020001000f83f); @(negedge sys_clk); // write hit,  bank X, get previously written instead of sudo-ram generated

    $display("TEST PASSED");
    $finish;
end

endmodule
