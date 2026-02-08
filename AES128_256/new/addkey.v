module addkey(in0, in1, in2, in3, out0, out1, out2, out3, key0, key1, key2, key3);
  input [31:0] key0;
  input [31:0] key1;
  input [31:0] key2;
  input [31:0] key3;
  input [31:0] in0;
  input [31:0] in1;
  input [31:0] in2;
  input [31:0] in3;
  output [31:0] out0;
  output [31:0] out1;
  output [31:0] out2;
  output [31:0] out3;
        //parameter size = 4;

	    assign out0 = key0^in0;
	    assign out1 = key1^in1;
	    assign out2 = key2^in2;
	    assign out3 = key3^in3;
	    



endmodule
