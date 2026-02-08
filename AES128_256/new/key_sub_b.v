module key_sub_b(clk, addr, data);
input clk;
input [31:0] addr;
output reg [31:0] data;

reg [7:0] mem [0:255];

initial begin
    $readmemh("sbox.mem", mem);
end

always @(*) begin
data[31:24]   <= mem[addr[31:24]];
data[23:16]   <= mem[addr[23:16]];
data[15:8]    <= mem[addr[15:8]];
data[7:0]     <= mem[addr[7:0]];

end
endmodule

