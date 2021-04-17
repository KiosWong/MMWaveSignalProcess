`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    ethernet_test
//////////////////////////////////////////////////////////////////////////////////
module udp_top(
	input  rst_n,                        
	
	input  tx_start,
	output tx_data_req,
	input  [31:0]tx_data,
	input  [15:0] tx_total_length,
	input  [15:0] tx_data_length,
	
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

assign e_rst = 1'b1; 
assign e_gtxc=e_rxc;	                //gtxc输出125Mhz的时�?

wire [31:0] datain_reg;
         
wire [3:0] tx_state;
wire [3:0] rx_state;

wire data_o_valid;

////////udp发�?�和接收程序/////////////////// 
udp u_udp
(
	.reset_n(rst_n),
	.e_rxc(e_rxc),
	.e_rxd(e_rxd),
    .e_rxdv(e_rxdv),
	.e_txen(e_txen),
	.e_txd(e_txd),
	.e_txer(e_txer),		
	
	.data_o_valid(),
	.rx_total_length(),
	.rx_state(),
	.rx_data_length(),
	
	.tx_start(tx_start),
	.tx_state(tx_state),
	.tx_data_req(tx_data_req),
	.tx_data(tx_data),
	.tx_data_length(tx_data_length),	
	.tx_total_length(tx_total_length),
	.data_received()
);

endmodule
