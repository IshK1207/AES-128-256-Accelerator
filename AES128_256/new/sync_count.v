`timescale 1ns/1ps
module sync_count (clk,reset,state);
output [7:0] state;
input clk,reset;
reg [7:0] out;

assign state = out;
always @(posedge clk, posedge reset) begin
	if (reset) out = 8'h0;
	else begin
		out[7] <= out[6];
		out[6] <= out[5];
		out[5] <= out[4];
		out[4] <= out[3];
		out[3] <= out[2];
		out[2] <= out[1];
		out[1] <= out[0];
		out[0] <= (out == 0);
	end
end
endmodule
