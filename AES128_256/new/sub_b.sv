module sub_b( addr, data);
input [127:0] addr;
output reg [127:0] data;

reg [7:0] mem [0:255];

initial begin
    $readmemh("sbox.mem", mem);
end

always @(*) begin
data[127:120] <= mem[addr[127:120]];
data[119:112] <= mem[addr[119:112]];
data[111:104] <= mem[addr[111:104]];
data[103:96]  <= mem[addr[103:96]];
data[95:88]   <= mem[addr[95:88]];
data[87:80]   <= mem[addr[87:80]];
data[79:72]   <= mem[addr[79:72]];
data[71:64]   <= mem[addr[71:64]];
data[63:56]   <= mem[addr[63:56]];
data[55:48]   <= mem[addr[55:48]];
data[47:40]   <= mem[addr[47:40]];
data[39:32]   <= mem[addr[39:32]];
data[31:24]   <= mem[addr[31:24]];
data[23:16]   <= mem[addr[23:16]];
data[15:8]    <= mem[addr[15:8]];
data[7:0]     <= mem[addr[7:0]];

end
endmodule

