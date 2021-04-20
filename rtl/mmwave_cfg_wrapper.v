`timescale 1ns / 1ps

module mmwave_cfg_wrapper
#(
	parameter SYS_CLK_FREQ_MHZ = 50
)
(
	input  clk,
	input  rst_n,
	
	input  rs232_rx_data_i,
	
	output mmwave_cfg_sys_en_o,
	output mmwave_cfg_sys_use_eth_o,
	output [2:0]mmwave_cfg_sys_uart_tx_baud_sel_o,
	output [7:0]mmwave_cfg_sys_eth_packsize_o,
	
	output mmwave_cfg_vco_enable_o,
	output [15:0]mmwave_cfg_chirp_freq_psc_o,
	output [4:0]mmwave_cfg_chirp_num_o,
	output [31:0]mmwave_cfg_period_psc_o,
	
	output [31:0]mmwave_cfg_ad_samplerate_psc_o,
	output [15:0]mmwave_cfg_down_samplerate_psc_o,
	
	output [31:0]mmwave_cfg_udp_src_ip_o,
	output [31:0]mmwave_cfg_udp_dst_ip_o,
	output [15:0]mmwave_cfg_udp_src_port_o,
	output [15:0]mmwave_cfg_udp_dst_port_o
);

wire w_mmwave_cfg_wr_en;
wire [2:0]w_mmwave_cfg_wr_index;
wire [63:0]w_mmwave_cfg_wr_value;

uart_cfg_wrapper
#(
	.UART_CLK_MHZ(SYS_CLK_FREQ_MHZ)
)
u_uart_cfg_wrapper
(
	.clk(clk),
	.rst_n(rst_n),
	.rs232_rx_data_i(rs232_rx_data_i),
	.mmwave_cfg_wr_en_o(w_mmwave_cfg_wr_en),
	.mmwave_cfg_wr_index_o(w_mmwave_cfg_wr_index),
	.mmwave_cfg_wr_data_o(w_mmwave_cfg_wr_value)
);


wire [295:0]w_mmwave_cfg_out;
mmwave_regfile u_mmwave_regfile
(
	.clk(clk),
	.rst_n(rst_n),
	.reg_wr_en_i(w_mmwave_cfg_wr_en),
	.reg_wr_index_i(w_mmwave_cfg_wr_index),
	.reg_wr_value_i(w_mmwave_cfg_wr_value),

	.sys_cfg_o(w_mmwave_cfg_out)
);

wire [7:0]mmwave_cfg_system_ctrl;
wire [63:0]mmwave_cfg_vco_ctrl;
wire [63:0]mmwave_cfg_ad_sample_ctrl;
wire [63:0]mmwave_cfg_udp_ip_ctrl;
wire [31:0]mmwave_cfg_udp_port_ctrl;
wire [63:0]mmwave_cfg_dsp_ctrl;

assign mmwave_cfg_system_ctrl = w_mmwave_cfg_out[295:288];
assign mmwave_cfg_vco_ctrl = w_mmwave_cfg_out[287:224];
assign mmwave_cfg_ad_sample_ctrl = w_mmwave_cfg_out[223:160];
assign mmwave_cfg_udp_ip_ctrl = w_mmwave_cfg_out[159:96];
assign mmwave_cfg_udp_port_ctrl = w_mmwave_cfg_out[95:64];
assign mmwave_cfg_dsp_ctrl = w_mmwave_cfg_out[63:0];

assign mmwave_cfg_sys_en_o = mmwave_cfg_system_ctrl[0];
assign mmwave_cfg_sys_use_eth_o = mmwave_cfg_system_ctrl[1];
assign mmwave_cfg_sys_uart_tx_baud_sel_o = mmwave_cfg_system_ctrl[4:2];
assign mmwave_cfg_sys_eth_packsize_o = 8'd1 << mmwave_cfg_system_ctrl[7:5];

assign mmwave_cfg_vco_enable_o = mmwave_cfg_vco_ctrl[0];
assign mmwave_cfg_chirp_freq_psc_o = mmwave_cfg_vco_ctrl[16:1];
assign mmwave_cfg_chirp_num_o = mmwave_cfg_vco_ctrl[21:17];
assign mmwave_cfg_period_psc_o = mmwave_cfg_vco_ctrl[53:22];

assign mmwave_cfg_ad_samplerate_psc_o = mmwave_cfg_ad_sample_ctrl[31:0];
assign mmwave_cfg_down_samplerate_psc_o = mmwave_cfg_ad_sample_ctrl[47:32];

assign mmwave_cfg_udp_src_ip_o = mmwave_cfg_udp_ip_ctrl[31:0];
assign mmwave_cfg_udp_dst_ip_o = mmwave_cfg_udp_ip_ctrl[63:32];
assign mmwave_cfg_udp_src_port_o = mmwave_cfg_udp_port_ctrl[15:0];
assign mmwave_cfg_udp_dst_port_o = mmwave_cfg_udp_port_ctrl[31:16];

endmodule
