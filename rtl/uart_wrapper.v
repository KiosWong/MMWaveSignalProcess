`timescale 1ns / 1ps

module uart_wrapper
(
	input  clk,
	input  rst_n,
	input  [2:0]rs232_baud_sel_i,
	input  rs232_rx_data_i,
	output rs232_rx_int,
	input  rs232_tx_start,
	output rs232_tx_data_o,
	output rs232_tx_int
);


wire [7:0]rs232_rx_data;

uart_top
#(
	.UART_CLK_MHZ(50)
)
u_uart_top
(
	.clk(clk),
	.rst_n(rst_n),
	.baud_sel_i(rs232_baud_sel_i),

	.rs232_tx_start(rs232_tx_start),
	.rs232_tx_data_i(rs232_rx_data),
	.rs232_tx_data_o(rs232_tx_data_o),
	.rs232_tx_int(rs232_tx_int),

	.rs232_rx_data_i(rs232_rx_data_i),
	.rs232_rx_data_o(rs232_rx_data),
	.rs232_rx_int(rs232_rx_int)
);

endmodule
