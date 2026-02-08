`timescale 1ns/1ps
module keyexp(key_in,out,reset,clk,key_en, stall,type,c_reset,div_clk);
input clk,key_en,reset,stall,type,c_reset,div_clk;
//wire [7:0] count;
input [127:0] key_in;
output[127:0] out;
wire[31:0]round_out;
//wire[31:0]round_out32;
//wire[31:0]round_in;
wire [31:0] trans_out;
//wire[31:0]shifted;
//wire [31:0]subs;
//wire div_clk;
wire [31:0] out0;
wire [31:0] out1;
wire [31:0] out2;
wire [31:0] out3;
wire [31:0] mid0;
wire [31:0] mid1;
wire [31:0] mid2;
wire [31:0] mid3;
wire [31:0] feed1;
wire [31:0] feed2;
wire [31:0] feed3;
wire [31:0] feed0;
wire [31:0] feedout1;
wire [31:0] feedout2;
wire [31:0] feedout3;
wire [31:0] feedout0;
wire [31:0] data_in0;
wire [31:0] data_in1;
wire [31:0] data_in2;
wire [31:0] data_in3;
wire [31:0] subs;
wire [31:0] mux_in1;
wire [31:0] mux_in2;
wire [31:0] mux_in3;
wire [31:0] mux_in0;
wire round_sub_sel;
assign data_in0 = key_in[127:96];
assign data_in1 = key_in[95:64];
assign data_in2 = key_in[63:32];
assign data_in3 = key_in[31:0];

//clk_div divider(.clk_in(clk), .clk_out(div_clk),. reset(reset));


mux32 in_mux0(.in1(data_in0),.in0(feed0),.sel(key_en),.out(feedout0));
mux32 in_mux1(.in1(data_in1),.in0(feed1),.sel(key_en),.out(feedout1));
mux32 in_mux2(.in1(data_in2),.in0(feed2),.sel(key_en),.out(feedout2));
mux32 in_mux3(.in1(data_in3),.in0(feed3),.sel(key_en),.out(feedout3));

reg32 reg0(.in(feedout0),.out(mid0),.clk(clk),.reset(reset), .en(stall));
reg32 reg1(.in(feedout1),.out(mid1),.clk(clk),.reset(reset), .en(stall));
reg32 reg2(.in(feedout2),.out(mid2),.clk(clk),.reset(reset), .en(stall));
reg32 reg3(.in(feedout3),.out(mid3),.clk(clk),.reset(reset), .en(stall));


reg32 reg8(.in(mid0),.out(mux_in0),.clk(clk),.reset(reset), .en(stall));
reg32 reg9(.in(mid1),.out(mux_in1),.clk(clk),.reset(reset), .en(stall));
reg32 reg10(.in(mid2),.out(mux_in2),.clk(clk),.reset(reset), .en(stall));
reg32 reg11(.in(mid3),.out(mux_in3),.clk(clk),.reset(reset), .en(stall));
//assign round_in[0] = out3[7:0];
//assign round_in[1] = out3[15:8];
//assign round_in[2] = out3[23:16];
//assign round_in = out3;
mux32 type_mux0(.in1(mux_in0),.in0(mid0),.sel(type),.out(out0));
mux32 type_mux1(.in1(mux_in1),.in0(mid1),.sel(type),.out(out1));
mux32 type_mux2(.in1(mux_in2),.in0(mid2),.sel(type),.out(out2));
mux32 type_mux3(.in1(mux_in3),.in0(mid3),.sel(type),.out(out3));

keyround round(.in(mid3),.out(round_out),.clk0(clk),.reset(reset),.clk1(div_clk),.type(type),.c_reset(c_reset));
key_sub_b sub(.clk(clk),.addr(mid3),.data(subs));
mux32 trans_sel(.in0(round_out),.in1(subs),.sel(round_sub_sel),.out(trans_out));

assign round_sub_sel = type&div_clk;
//assign round_out32 = {round_out[3],round_out[2],round_out[1],round_out[0]};

assign feed0 = out0^trans_out;
assign feed1 = out1^feed0;
assign feed2 = out2^feed1;
assign feed3 = out3^feed2;

assign out = {mid0, mid1, mid2, mid3};
endmodule
