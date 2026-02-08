module par_enc(data,clk,data_en,reset,key,out,sel1,sel2, stall);
input clk,sel1,sel2,data_en,reset, stall;
wire [31:0] data_in0;
wire [31:0] data_in1;
wire [31:0] data_in2;
wire [31:0] data_in3;
wire [31:0] feed1;
wire [31:0] feed2;
wire [31:0] feed3;
wire [31:0] feed0;
wire [31:0] feedout1;
wire [31:0] feedout2;
wire [31:0] feedout3;
wire [31:0] feedout0;
input [127:0]key;
input [127:0]data;
output [127:0]out;
wire [127:0]sub_out;
wire [127:0]shifted;
//output [7:0]count;
wire [31:0]mix_in0;
wire [31:0]mix_in1;
wire [31:0]mix_in2;
wire [31:0]mix_in3;
wire [31:0]mix_out0;
wire [31:0]mix_out1;
wire [31:0]mix_out2;
wire [31:0]mix_out3;
wire [127:0]mixout;
wire [127:0]into_addkey;
wire [127:0]into_mux2;
wire [31:0] out1;
wire [31:0] out2;
wire [31:0] out3;
wire [31:0] out0;

//keyexp keygen(.key_in(key_in),.out(key),.reset(reset),.clk(clk),.key_en(data_en),.count(count));

assign data_in0 = data[127:96];
assign data_in1 = data[95:64];
assign data_in2 = data[63:32];
assign data_in3 = data[31:0];

mux32 in_mux0(.in1(data_in0),.in0(feed0),.sel(data_en),.out(feedout0));
mux32 in_mux1(.in1(data_in1),.in0(feed1),.sel(data_en),.out(feedout1));
mux32 in_mux2(.in1(data_in2),.in0(feed2),.sel(data_en),.out(feedout2));
mux32 in_mux3(.in1(data_in3),.in0(feed3),.sel(data_en),.out(feedout3));

reg32 reg0(.in(feedout0),.out(out0),.clk(clk),.reset(reset), .en(stall));
reg32 reg1(.in(feedout1),.out(out1),.clk(clk),.reset(reset), .en(stall));
reg32 reg2(.in(feedout2),.out(out2),.clk(clk),.reset(reset), .en(stall));
reg32 reg3(.in(feedout3),.out(out3),.clk(clk),.reset(reset), .en(stall));

assign out[103:96] = out0[7:0];
assign out[111:104] = out0[15:8];
assign out[119:112] = out0[23:16];
assign out [127:120] = out0[31:24];
assign out[71:64] = out1[17:0];
assign out[79:72] = out1[15:8];
assign out[87:80] = out1[23:16];
assign out[95:88] = out1[31:24];
assign out[39:32] = out2[7:0];
assign out[47:40]  = out2[15:8];
assign out[55:48] = out2[23:16];
assign out[63:56] = out2[31:24];
assign out[7:0] = out3[7:0];
assign out[15:8] = out3[15:8];
assign out[23:16] = out3[23:16];
assign out[31:24] = out3[31:24];


sub_b sub(.addr(out),.data(sub_out));
shiftrow shifter(.in(sub_out),.out(shifted));

mux844 mux1(.in1(out),.in0(shifted),.sel(sel1),.out(into_mux2));

assign mix_in0 = shifted[127:96];
assign mix_in1 = shifted[95:64];
assign mix_in2 = shifted[63:32];
assign mix_in3 = shifted[31:0];

mixcol mc0(.in32(mix_in0),.mix_out32(mix_out0));
mixcol mc1(.in32(mix_in1),.mix_out32(mix_out1));
mixcol mc2(.in32(mix_in2),.mix_out32(mix_out2));
mixcol mc3(.in32(mix_in3),.mix_out32(mix_out3));


assign mixout = {mix_out0,mix_out1,mix_out2,mix_out3};
mux844 mux2(.in1(into_mux2),.in0(mixout),.sel(sel2),.out(into_addkey));
addkey add(.in0(into_addkey[127:96]),.in1(into_addkey[95:64]),.in2(into_addkey[63:32]),.in3(into_addkey[31:0]),.out0(feed0),.out1(feed1),.out2(feed2),.out3(feed3),.key0(key[127:96]),.key1(key[95:64]),.key2(key[63:32]),.key3(key[31:0]));


endmodule


