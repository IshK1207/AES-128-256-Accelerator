`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module encrypt_aes(
    input [127:0] in,
    input [255:0] key,
    input clk,
    input enable,
    input type,
    input reset_n,
    output [127:0] out,
    output done
    //input done_reset
    );
wire div_clk;
wire sel1,sel2,data_en;
wire [1:0] mode;
wire key_sel;
wire [127:0] key_in;
wire d_en,k_en,res_out;
//wire done_reset;
wire [127:0] key_out;

wire res_in,fsm_reset;
assign res_in = ~reset_n;
assign fsm_reset = res_in || enable;
assign sel1 = mode[0];
assign sel2 = mode[1];


assign key_in = key_sel?key[127:0]:key[255:128];

par_enc uut(.stall(done), .data(in),.reset(res_in),.data_en(d_en),.clk(clk),.key(key_out),.out(out),.sel1(sel1),.sel2(sel2));

keyexp key_uut(.stall(done), .key_en(k_en),.clk(clk),.key_in(key_in),.out(key_out),.reset(res_in),.type(type),.c_reset(fsm_reset),.div_clk(div_clk));

fsm_enc fsm(.stall(done),.clk(clk),.d_en(d_en),.k_en(k_en), .mode(mode),.reset_in(enable),.reset_out(res_out),.done(done),.type(type),.key_sel(key_sel),.div_clk(div_clk));

endmodule

