module gray_counter
       #(
           parameter WIDTH = 3
       )
       (
           input CLK,
           input nRST,
           input EN,

           output reg [WIDTH-1:0] value
       );

reg [WIDTH-1:0] cnt;

always @(posedge CLK or negedge nRST) begin
    if(~nRST) begin
        cnt <= 1;
        value <= 0;
    end
    else if(EN) begin
        cnt <= cnt + 1;
        value <= {cnt[WIDTH-1], cnt[WIDTH-2:0] ^ cnt[WIDTH-1:1]};
    end
end
endmodule
