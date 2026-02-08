`timescale 1ns/1ps
module sync_count_128 (clk,reset,state);
output [7:0] state;
input clk,reset;
reg [7:0] out;
//wire res;
//assign res = reset & clk;
assign state = out;
always @(posedge clk or posedge reset) begin
	if (reset) out <= 0;
	else begin
		out[7] <= out[6];
		out[6] <= out[5]&(~out[4]);
		out[5] <= out[4]&(~out[5]);
		out[4] <= out[7]|(out[3]&(~out[2]));
		out[3] <= (out[2] & (~out[1]))|out[7];
		out[2] <= out[1]&(~out[2]);
		out[1] <= out[0]|out[7];
		out[0] <= ~|out[6:0];
	end
end
endmodule