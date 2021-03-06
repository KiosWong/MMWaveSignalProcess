`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    ethernet_test
//////////////////////////////////////////////////////////////////////////////////
module udp_top(
	input  rst_n,                        
	
	input  tx_start,
	output tx_data_req,
	input  [31:0]tx_data,
	input  [15:0]tx_total_length,
	input  [15:0]tx_data_length,
	input  [31:0]src_ip_addr,
	input  [31:0]dst_ip_addr,
	input  [15:0]src_port,
	input  [15:0]dst_port,
	
	output e_rst,
	output e_mdc,
	inout  e_mdio,
	
	input  e_rxc,                       //125Mhz ethernet gmii rx clock
	input  [7:0] e_rxd,        
	
	input  e_txc,                     //25Mhz ethernet mii tx clock         
	output e_gtxc,                    //25Mhz ethernet gmii tx clock  
	output e_txen, 
	output e_txer, 					
	output [7:0] e_txd	
);

assign e_rst = 1'b1; 
//assign e_gtxc=e_rxc;	

clk_wiz_1 gtxc_pll
(
	// Clock out ports
	.clk_out1(e_gtxc),     // output clk_out1
	// Status and control signals
	.reset(~rst_n), // input reset
	.locked(1'b1),       // output locked
	// Clock in ports
	.clk_in1(e_rxc)
);   

udp u_udp
(
	.reset_n(rst_n),
	.e_rxc(e_rxc),

	.e_txen(e_txen),
	.e_txd(e_txd),
	.e_txer(e_txer),		
	
	.tx_start(tx_start),
	.tx_data_req(tx_data_req),
	.tx_data(tx_data),
	.tx_data_length(tx_data_length),	
	.tx_total_length(tx_total_length),
	.src_ip_addr(src_ip_addr),
	.dst_ip_addr(dst_ip_addr),
	.src_port(src_port),
	.dst_port(dst_port)
);

endmodule
