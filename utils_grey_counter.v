`timescale 1ns / 1ps

module gray_counter
       #(
           parameter WIDTH = 3
       )
       (
           input clk,
           input not_reset,
           input en,

           output reg [WIDTH-1:0] value
       );

reg [WIDTH-1:0] counter;

always @(posedge clk or negedge not_reset) begin
    if(~not_reset) begin
        counter <= 1;
        value <= 0;
    end
    else if(en) begin
        counter <= counter + 1;
        value <= {counter[WIDTH-1], counter[WIDTH-2:0] ^ counter[WIDTH-1:1]};
    end
end

endmodule
