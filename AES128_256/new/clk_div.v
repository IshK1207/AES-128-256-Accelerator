`timescale 1ns / 1ps

module clk_div(clk_in, clk_out, reset);
input clk_in, reset;
output reg clk_out;

always @(posedge clk_in) begin
    if (reset) clk_out = 0;
    else  clk_out = ~clk_out;
end
endmodule
