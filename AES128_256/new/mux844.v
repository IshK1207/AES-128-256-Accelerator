module mux844(in0,in1,sel,out);
input sel;
input [127:0]in0;
input [127:0]in1;
output [127:0] out;

assign out = sel?(in1):(in0);

endmodule
