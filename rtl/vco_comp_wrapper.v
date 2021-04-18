`timescale 1ns / 1ps

module vco_comp_wrapper
#(
	parameter SYS_CLK_FREQ_MHZ	= 50
)
(
	input clk,
	input rst_n,
	
	input  mode_sel_i,
	input  [31:0]trigger_freq_psc_i,
	input  [4:0]chirp_num_i,
	input  [15:0]chirp_freq_psc_i,
	output vco_da_clk_o,
	output [9:0]vco_out_o
);

localparam 	MODE_CW = 	1'b0,
			MODE_FMCW = 1'b1;

wire w_vco_out_done;

reg [31:0]trigger_freq_cnt;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		trigger_freq_cnt <= 32'b0;
	end
	else if(trigger_freq_cnt == trigger_freq_psc_i - 1) begin
		trigger_freq_cnt <= 32'b0;
	end
	else if(mode_sel_i == MODE_CW) begin
		trigger_freq_cnt <= trigger_freq_cnt <= 32'b0;
	end
	else begin
		trigger_freq_cnt <= trigger_freq_cnt + 32'b1;
	end
end

localparam	TRIGGER_IDLE = 2'b00,
			TRIGGER_ACTIVE = 2'b001,
			TRIGGER_WAITING = 2'b10;
			
reg [4:0]chirp_cnt;
reg [1:0]trigger_c_state;
reg [1:0]trigger_n_state;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		trigger_n_state <= TRIGGER_IDLE;
	end
	else if(mode_sel_i == MODE_CW) begin
		trigger_n_state <= TRIGGER_IDLE;
	end
	else begin
		case(trigger_c_state)
			TRIGGER_IDLE: begin
				if(trigger_freq_cnt == trigger_freq_psc_i - 1) begin
					trigger_n_state <= TRIGGER_ACTIVE;
				end
			end
			TRIGGER_ACTIVE: begin
				if(chirp_cnt == chirp_num_i - 1) begin
					trigger_n_state <= TRIGGER_IDLE;
				end
				else begin
					trigger_n_state <= TRIGGER_WAITING;
				end
			end
			TRIGGER_WAITING: begin
				if(w_vco_out_done) begin
					trigger_n_state <= TRIGGER_ACTIVE;
				end
			end
			default: trigger_n_state <= TRIGGER_IDLE;
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		trigger_c_state <= TRIGGER_IDLE;
	end
	else begin
		trigger_c_state <= trigger_n_state;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		chirp_cnt <= 5'd0;
	end
	else if(chirp_cnt == chirp_num_i) begin
		chirp_cnt <= 5'd0;
	end
	else if(mode_sel_i == MODE_CW) begin
		chirp_cnt <= 5'd0;
	end
	else if(w_vco_out_done) begin
		chirp_cnt <= chirp_cnt + 5'b1;
	end
end

wire w_trigger;
assign w_trigger = (trigger_c_state == TRIGGER_ACTIVE) ? 1 : 0;

vco_comp
#(
	.SYS_CLK_FREQ_MHZ(SYS_CLK_FREQ_MHZ)
)
u_vco_comp
(
	.clk(clk),
	.rst_n(rst_n),

	.vco_da_clk_o(vco_da_clk_o),
	.vco_freq_psc_cmp_i(chirp_freq_psc_i),
	.trigger_i(w_trigger),
	.vco_out_o(vco_out_o),
	.vco_out_done_o(w_vco_out_done)
);



endmodule
