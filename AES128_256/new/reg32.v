`timescale 1ns/1ps;
module reg32(in, out, clk, reset,en);
input [31:0]in;
input clk,reset,en;
output reg [31:0] out;

always @(posedge clk or posedge reset) begin
	if (reset) out <= 0;
	else if (~en) out <= in;
end
endmodule

