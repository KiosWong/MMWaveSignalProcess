`timescale 1ns/1ps

module uart_top
#(
	parameter UART_CLK_MHZ = 50
)
(
	input  clk,
	input  rst_n,
	input  [2:0]baud_sel_i,
	
	input  rs232_tx_start,
	input  [7:0]rs232_tx_data_i,
	output rs232_tx_data_o,
	output rs232_tx_int,
	
	input  rs232_rx_data_i,
	output [7:0]rs232_rx_data_o,
	output rs232_rx_int
	
);

uart_rx
#(
	.UART_CLK_MHZ(UART_CLK_MHZ)
)
u_uart_rx
(
	.clk(clk),
	.rst_n(rst_n),
	.baud_sel_i(baud_sel_i),
	.rs232_rx_data_i(rs232_rx_data_i),
	.rs232_rx_data_o(rs232_rx_data_o),
	.rs232_rx_int(rs232_rx_int)
);

uart_tx
#(
	.UART_CLK_MHZ(UART_CLK_MHZ)
)
u_uart_tx
(
	.clk(clk),
	.rst_n(rst_n),
	.baud_sel_i(baud_sel_i),
	.rs232_tx_start(rs232_tx_start),
	.rs232_tx_data_i(rs232_tx_data_i),
	.rs232_tx_int(rs232_tx_int),
	.rs232_tx_o(rs232_tx_data_o)
);

endmodule
