`timescale 1ns / 1ps

module dowm_sample
#(

	parameter SYS_CLK_FREQ_MHZ	= 50
)
(
	input  clk,
	input  rst_n,

	input  [15:0]sample_psc_i,
	input  raw_data_valid_i,
	input  [12:0]raw_data_i,
	output sampled_data_valid_o,
	output [12:0]sampled_data_o
);

reg [15:0]sample_cnt;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sample_cnt <= 0;
	end
	else if(sample_cnt == sample_psc_i - 1) begin
		sample_cnt <= 0;
	end
	else if(raw_data_valid_i) begin
		sample_cnt <= sample_cnt + 1'b1;
	end
end

assign sampled_data_valid_o = (sample_cnt == sample_psc_i - 1) ? 1 : 0;
assign sampled_data_o = (sample_cnt == sample_psc_i - 1) ? raw_data_i : 13'b0;

endmodule
