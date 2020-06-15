module RAM
       #(
           parameter       ADDR_SIZE   = 13,       // разрядность адреса ОП
           parameter       WORD_SIZE   = 16,       // разрядность шины данных
           parameter       DATA_SIZE   = 64,       // разрядность блока данных
           parameter       DELAY       = 5.0       // задержка при ответе на запрос (ns)
       )
       (
           input [WORD_SIZE-1:0]   ram_wdata,
           input [ADDR_SIZE-1:0]   ram_addr,
           input                   ram_avalid,
           input                   ram_rnw,
           input                   ram_clk,
           input                   ram_rst_n,

           output reg [WORD_SIZE-1:0] ram_rdata,
           output reg                 ram_ack,
           output reg [DATA_SIZE-1:0] data_backdoor
       );

localparam ITER_COUNT = DATA_SIZE / WORD_SIZE;
reg [DATA_SIZE-1:0] data;
reg [ADDR_SIZE-1:0] addr;

always @* if (!ram_rst_n) begin
        ram_rdata = 0;
        ram_ack = 0;
        data = 0;
        addr = 0;
    end
always @(posedge ram_clk) begin
    if (ram_avalid)
        if(!ram_rnw) begin // Запись в RAM
            addr <= ram_addr;
            repeat (ITER_COUNT) begin
                $display("[RAM_STUB] [%3d] RAM writing %4x", $time, ram_wdata);
                data <= {ram_wdata, data[DATA_SIZE-1:WORD_SIZE]};
                data_backdoor <= {ram_wdata, data[DATA_SIZE-1:WORD_SIZE]};
                @(posedge ram_clk);
            end

            $display("[RAM_STUB] [%3d] RAM next time ack", $time, ram_wdata);
            ram_ack <= 1;
            @(posedge ram_clk);
            ram_ack <= 0;
            $display("[RAM_STUB] [%3d] RAM WRITE ok! addr = %0h, data = %0h", $time, ram_addr, data);
        end
        else begin
            addr = ram_addr;
            repeat(DELAY) begin
                @(posedge ram_clk);
            end
            data = {32'h30002000, 16'h1000, addr, 3'b111};
            data_backdoor <= {32'h30002000, 16'h1000, addr, 3'b111};
            $display("[RAM_STUB] [%0d] RAM READ ok! addr = %0h, data = %0h", $time, ram_addr, data);
            repeat(ITER_COUNT) begin
                @(posedge ram_clk);
                $display("[RAM_STUB] [%3d] RAM acking %4x", $time, data[WORD_SIZE-1:0]);
                ram_ack = 1;
                ram_rdata <= data[WORD_SIZE-1:0];
                data <= (data >> WORD_SIZE);
            end
            @(posedge ram_clk);
            ram_ack = 0;
        end
end

endmodule
