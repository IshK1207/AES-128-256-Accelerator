module shiftrow(in,out);
	input [127:0] in;
	output [127:0] out;
	//parameter size = 4;

/*	generate
		for ( i = 0; i < size; i++) begin
			for ( j = 0; j < i;j++) begin	
				assign out[i][i+j] = in[i][j];
			end
			for ( j = i; j <size; j++) begin
				assign out[i][j-i] = in[i][j];
			end
		end
	endgenerate*/

//       assign out[ = in[0];
//       assign out[1] = '{in[1][1],in[1][2],in[1][3],in[1][0]};	
//	assign out[2] = '{in[2][2],in[2][3],in[2][0],in[2][1]};
//	assign out[3] = '{in[3][3],in[3][0],in[3][1],in[3][2]};
	
assign out[127:120] = in[127:120];
assign out[119:112] = in[87:80];
assign out[111:104] = in[47:40];
assign out[103:96]  = in[7:0];
assign out[95:88]   = in[95:88];
assign out[87:80]   = in[55:48];
assign out[79:72]   = in[15:8];
assign out[71:64]   = in[103:96];
assign out[63:56]   = in[63:56];
assign out[55:48]   = in[23:16];
assign out[47:40]   = in[111:104];
assign out[39:32]   = in[71:64];
assign out[31:24]   = in[31:24];
assign out[23:16]   = in[119:112];
assign out[15:8]    = in[79:72];
assign out[7:0]     = in[39:32];

endmodule
