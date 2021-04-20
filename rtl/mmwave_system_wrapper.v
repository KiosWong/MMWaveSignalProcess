`timescale 1ns / 1ps

module mmwave_system_wrapper
#(
	parameter SYS_CLK_FREQ_MHZ	= 50
)
(

	input clk,
	input rst_n,
	
	output vco_da_clk_o,
	output [9:0]vco_out_o,
	
	input  [12:0]ad_data_i,
	output ad_clk_o,
	
	input  rs232_rx_data_i,
	output rs232_tx_data_o,
	
	output e_rst,
	output e_mdc,
	inout  e_mdio,
	
	input  e_rxc,                       //125Mhz ethernet gmii rx clock
	input  e_rxdv,	
	input  e_rxer,						
	input  [7:0] e_rxd,        
	
	input  e_txc,                     //25Mhz ethernet mii tx clock         
	output e_gtxc,                    //25Mhz ethernet gmii tx clock  
	output e_txen, 
	output e_txer, 					
	output [7:0] e_txd
);

wire w_mmwave_cfg_sys_en;
wire w_mmwave_cfg_sys_use_eth;
wire [2:0]w_mmwave_cfg_sys_uart_tx_baud_sel;
wire [7:0]w_mmwave_cfg_sys_eth_packsize;

wire w_mmwave_cfg_vco_enable;
wire [15:0]w_mmwave_cfg_chirp_freq_psc;
wire [4:0]w_mmwave_cfg_chirp_num;
wire [31:0]w_mmwave_cfg_period_psc;

wire [31:0]w_mmwave_cfg_ad_samplerate_psc;
wire [15:0]w_mmwave_cfg_down_samplerate_psc;

wire [31:0]w_mmwave_cfg_udp_src_ip;
wire [31:0]w_mmwave_cfg_udp_dst_ip;
wire [15:0]w_mmwave_cfg_udp_src_port;
wire [15:0]w_mmwave_cfg_udp_dst_port;

mmwave_cfg_wrapper u_mmwave_cfg_wrapper
(
	.clk(clk),
	.rst_n(rst_n),
	
	.rs232_rx_data_i(rs232_rx_data_i),

	.mmwave_cfg_sys_en_o(w_mmwave_cfg_sys_en),
	.mmwave_cfg_sys_use_eth_o(w_mmwave_cfg_sys_use_eth),
	.mmwave_cfg_sys_uart_tx_baud_sel_o(w_mmwave_cfg_sys_uart_tx_baud_sel),
	.mmwave_cfg_sys_eth_packsize_o(w_mmwave_cfg_sys_eth_packsize),

	.mmwave_cfg_vco_enable_o(w_mmwave_cfg_vco_enable),
	.mmwave_cfg_chirp_freq_psc_o(w_mmwave_cfg_chirp_freq_psc),
	.mmwave_cfg_chirp_num_o(w_mmwave_cfg_chirp_num),
	.mmwave_cfg_period_psc_o(w_mmwave_cfg_period_psc),

	.mmwave_cfg_ad_samplerate_psc_o(w_mmwave_cfg_ad_samplerate_psc),
	.mmwave_cfg_down_samplerate_psc_o(w_mmwave_cfg_down_samplerate_psc),

	.mmwave_cfg_udp_src_ip_o(w_mmwave_cfg_udp_src_ip),
	.mmwave_cfg_udp_dst_ip_o(w_mmwave_cfg_udp_dst_ip),
	.mmwave_cfg_udp_src_port_o(w_mmwave_cfg_udp_src_port),
	.mmwave_cfg_udp_dst_port_o(w_mmwave_cfg_udp_dst_port)
);


wire s_ad_frontend_en;
wire [12:0]w_ad_frontend_out_data;
wire w_ad_data_valid;

vco_comp_wrapper
#(
	.SYS_CLK_FREQ_MHZ(50)
)
u_vco_comp_wrapper
(
	.clk(clk),
	.rst_n(rst_n),
	.mode_sel_i(w_mmwave_cfg_vco_enable),
	.trigger_freq_psc_i(w_mmwave_cfg_period_psc),
	.chirp_num_i(w_mmwave_cfg_chirp_num),
	.chirp_freq_psc_i(w_mmwave_cfg_chirp_freq_psc),
	.vco_da_clk_o(vco_da_clk_o),
	.vco_out_o(vco_out_o)
);

wire w_mmwave_comm_ready;
assign s_ad_frontend_en = (w_mmwave_comm_ready) ? 1 : 0;

ad9226 u_ad_frontend
(
	.clk(clk),
	.rst_n(rst_n),
	.en(1),
	.clk_psc_period_i(w_mmwave_cfg_ad_samplerate_psc),	//20KHz @ 50MHz sys clk freq
	.ad_data_i(ad_data_i),
	.ad_clk_o(ad_clk_o),
	.ad_data_o(w_ad_frontend_out_data),
	.ad_data_valid_o(w_ad_data_valid)
);

wire w_sampled_data_valid;
wire [12:0]w_sample_data_out;

dowm_sample
#(

	.SYS_CLK_FREQ_MHZ(SYS_CLK_FREQ_MHZ)
)
u_dowm_sample
(
	.clk(clk),
	.rst_n(rst_n),

	.sample_psc_i(w_mmwave_cfg_down_samplerate_psc),
	.raw_data_valid_i(w_ad_data_valid),
	.raw_data_i(w_ad_frontend_out_data),
	.sampled_data_valid_o(w_sampled_data_valid),
	.sampled_data_o(w_sample_data_out)
);
wire w_rs232_rx_int;
wire w_rs232_tx_int;

mmwave_comm_wrapper
#(
	.SYS_CLK_FREQ_MHZ(SYS_CLK_FREQ_MHZ)
)
u_mmwave_comm_wrapper
(
	.clk(clk),
	.rst_n(rst_n),
	
	.mmwave_comm_mode_sel_i(w_mmwave_cfg_vco_enable),
	.mmwave_comm_ready_o(w_mmwave_comm_ready),

	.mmwave_sample_data_i(w_sample_data_out),
	.mmwave_sample_data_valid_i(w_sampled_data_valid),

	.rs232_rx_data_i(rs232_rx_data_i),
	.rs232_rx_int(w_rs232_rx_int),
	.rs232_tx_baud_sel(w_mmwave_cfg_sys_uart_tx_baud_sel),
	.rs232_tx_data_o(rs232_tx_data_o),
	.rs232_tx_int(w_rs232_tx_int),
	
	.e_tx_packet_len_i(w_mmwave_cfg_sys_eth_packsize),
	.src_ip_addr_i(w_mmwave_cfg_udp_src_ip),
	.dst_ip_addr_i(w_mmwave_cfg_udp_dst_ip),
	.src_port_i(w_mmwave_cfg_udp_src_port),
	.dst_port_i(w_mmwave_cfg_udp_dst_port),
	
	.e_rst(e_rst),
	.e_mdc(e_mdc),
	.e_mdio(e_mdio),
	
	.e_rxc(e_rxc),                       //125Mhz ethernet gmii rx clock
	.e_rxdv(e_rxdv),	
	.e_rxer(e_rxer),						
	.e_rxd(e_rxd),        

	.e_txc(e_txc),                     //25Mhz ethernet mii tx clock         
	.e_gtxc(e_gtxc),                    //25Mhz ethernet gmii tx clock  
	.e_txen(e_txen), 
	.e_txer(e_txer), 					
	.e_txd(e_txd)
);

endmodule