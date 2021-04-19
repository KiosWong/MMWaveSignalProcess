`timescale 1ns / 1ps

module mmwave_regfile
(
	input  clk,
	input  rst_n,
	input  reg_wr_en_i,
	input  [2:0]reg_wr_index_i,
	input  [63:0]reg_wr_value_i,
	
	output [295:0]sys_cfg_o
);

reg [7:0]mmwave_cfg_system_ctrl;
reg [63:0]mmwave_cfg_vco_ctrl;
reg [63:0]mmwave_cfg_ad_sample_ctrl;
reg [63:0]mmwave_cfg_udp_ip_ctrl;
reg [31:0]mmwave_cfg_udp_port_ctrl;
reg [63:0]mmwave_cfg_dsp_ctrl;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
//		mmwave_cfg_system_ctrl <= 8'd0;
//		mmwave_cfg_vco_ctrl <= 64'd0;
//		mmwave_cfg_ad_sample_ctrl <= 64'd0;
//		mmwave_cfg_udp_ip_ctrl <= 64'd0;
//		mmwave_cfg_udp_port_ctrl <= 32'd0;
//		mmwave_cfg_dsp_ctrl <= 64'd0;

		mmwave_cfg_system_ctrl <= {3'd5 ,3'd7, 1'b0, 1'b1};
		mmwave_cfg_vco_ctrl <= {10'd0, 32'd2_500_000, 5'd3, 16'd5, 1'd1};
		mmwave_cfg_ad_sample_ctrl <= {16'd0, 16'd2, 32'd5_000_000};
		mmwave_cfg_udp_ip_ctrl <= {32'hc0a80003, 32'hc0a80002};
		mmwave_cfg_udp_port_ctrl <= {32'd0, 16'd8080, 16'd8080};
		mmwave_cfg_dsp_ctrl <= 64'd0;
	end
	else if(reg_wr_en_i) begin
		case(reg_wr_index_i)
			3'd0: mmwave_cfg_system_ctrl <= reg_wr_value_i[7:0];
			3'd1: mmwave_cfg_vco_ctrl <= reg_wr_value_i;
			3'd2: mmwave_cfg_ad_sample_ctrl <= reg_wr_value_i;
			3'd3: mmwave_cfg_udp_ip_ctrl <= reg_wr_value_i;
			3'd4: mmwave_cfg_udp_port_ctrl <= reg_wr_value_i[31:0];
			3'd5: mmwave_cfg_dsp_ctrl <= reg_wr_value_i;
			default:;
		endcase
	end
end

assign sys_cfg_o = {mmwave_cfg_system_ctrl, mmwave_cfg_vco_ctrl, mmwave_cfg_ad_sample_ctrl, mmwave_cfg_udp_ip_ctrl, mmwave_cfg_udp_port_ctrl, mmwave_cfg_dsp_ctrl};

endmodule
