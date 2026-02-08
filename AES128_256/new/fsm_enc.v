module fsm_enc(clk,d_en,k_en,stall, mode,reset_in,reset_out,done,ready, type,key_sel,div_clk);
input clk,reset_in,stall,type;
output reg d_en,k_en,reset_out;
output reg [1:0]mode;
output reg done;
output reg ready;
output reg key_sel;
output div_clk;
//output reg key_enable;
reg [3:0] counter;
assign div_clk = counter[0];
always @(posedge clk) begin
	if (reset_in) begin 
		counter <= 0;
		reset_out <= 1;
		mode <=2'b11;
		d_en <= 1;
		k_en <= 1;
		done <= 0;
		key_sel <= 0;
	end
	else if (~stall) begin 
		counter <= counter + 1;
		if (~type) begin
            if (counter == 11) begin
                d_en <= 1;
                k_en <= 1;
                reset_out <=1;
                counter <=0;
                done <=1;
                mode <= 2'b11;
            end
            else if (counter == 12) done <=0;
            else if (counter == 0)begin
                   d_en <=0;
                   k_en <=0;
                    reset_out <=0;
                    done <= 0;
                mode <= 2'b11;
            end
            else if (counter == 10) begin
                mode <=2'b10;
            end
            else begin
                mode <= 2'b00;
            end
        end
        
        else begin
            if (counter == 15) begin
                d_en <= 1;
                k_en <=1;
                reset_out <=1;
                counter <=0;
                done <=1;
                mode <= 2'b11;
            end
            else if (counter == 16) done <=0;
            else if (counter == 0)begin
                   d_en <=0;
                   key_sel<=1;
                    reset_out <=0;
                    done <= 0;
                mode <= 2'b11;
            end
            //else if (counter ==1) key_sel<=1;
            else if (counter == 1) begin 
                mode <= 2'b00;
                k_en <=0;
            end
            else if (counter == 14) begin
                mode <=2'b10;
            end
            else begin
                mode <= 2'b00;
            end
        end
	end
end
endmodule

			
		
	

