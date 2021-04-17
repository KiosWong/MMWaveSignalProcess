`timescale 1ns / 1ps

module ad9226
(
	input clk,
	input rst_n,
	input en,
	input [31:0]clk_psc_period_i,
	input [12:0]ad_data_i,
	output reg ad_clk_o,
	output reg [12:0]ad_data_o,
	output ad_data_valid_o
);

reg [31:0]clk_cnt;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
		clk_cnt <= 32'd0;
	else if(en) begin
		if (clk_cnt == (clk_psc_period_i - 1)) begin
			clk_cnt <= 32'd0;
		end
		else begin
			clk_cnt <= clk_cnt + 32'd1;
		end
	end
end
	
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		ad_clk_o <= 1'd0;
		ad_data_o <= 13'd0;
	end
	else if(clk_cnt == (clk_psc_period_i >> 1) - 1) begin
		ad_clk_o <= 1'd1;
		ad_data_o <= ad_data_i;
	end
	else if(clk_cnt == clk_psc_period_i - 1) begin
		ad_clk_o <= 1'd0;
		ad_data_o <= ad_data_o;
	end
	else begin
		ad_clk_o <= ad_clk_o;
		ad_data_o <= ad_data_o;
	end
end

assign ad_data_valid_o = (clk_cnt == clk_psc_period_i >> 1) ? 1 : 0;

endmodule
