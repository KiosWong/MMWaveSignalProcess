`timescale 1ns / 1ps

module udp_wrapper
(
	input  clk,
	input  rst_n,
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

wire w_tx_start;
reg [31:0]cnt;

//always @(posedge clk or negedge rst_n) begin
//	if(!rst_n) begin
//		cnt <= 32'd0;
//	end
//	else if(cnt == 32'd50_000_000 - 1) begin
//		cnt <= 32'd0;
//	end
//	else begin
//		cnt <= cnt + 1'b1;
//	end
//end

always @(posedge e_rxc or negedge rst_n) begin
	if(!rst_n) begin
		cnt <= 32'd0;
	end
	else if(cnt == 32'd50_000_000 - 1) begin
		cnt <= 32'd0;
	end
	else begin
		cnt <= cnt + 1'b1;
	end
end

assign w_tx_start = (cnt == 32'd50_000_000 - 1) ? 1 : 0;

udp_top u_udp_top(
	.rst_n(rst_n),                        

	.tx_start(w_tx_start),
	.tx_data_req(),
	.tx_data(32'h28292a2b),
	.tx_total_length(16'd32),
	.tx_data_length(16'd12),
	
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

ila_0 your_instance_name (
	.clk(e_rxc), // input wire clk
	.probe0(e_txd), // input wire [7:0] probe0
	.probe1(e_rxc), // input wire [0:0]  probe1
	.probe2(cnt) // input wire [31:0]  probe2
);

endmodule
