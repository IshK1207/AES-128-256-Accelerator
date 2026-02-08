module keyround(in,out,clk0,reset,clk1,type,c_reset);
input [31:0] in;
input clk1,clk0,reset,type,c_reset;
output [31:0] out ;
wire [31:0] shifted;
wire [31: 0] subs;
//wire res;
//input done_reset;
//output [7:0]count;
wire [7:0]count_128,count_256,count;

assign count = type?count_256:count_128;
//assign res = (done_reset| reset);
assign shifted[31:24] = in[23:16];
assign shifted[23:16] = in[15:8];
assign shifted[15:8] = in[7:0];
assign shifted[7:0] = in[31:24];

key_sub_b sub(.clk(clk0),.addr(shifted),.data(subs));

sync_count counter(.clk(clk1),.reset(c_reset),.state(count_256));
sync_count_128 counter_128 (.clk(clk0),.reset(c_reset),.state(count_128));

assign out = {subs[31:24]^count,subs[23:0]};
endmodule
