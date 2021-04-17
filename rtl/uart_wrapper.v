`timescale 1ns / 1ps

module uart_wrapper
(
	input  clk,
	input  rst_n,
	input  rs232_rx_data_i,
	output rs232_tx_data_o
);

wire uart_clk;
wire uart_tx_start;

assign uart_clk = clk;

reg [31:0]cnt;
always @(posedge clk or negedge rst_n) begin
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

//assign uart_tx_start = (cnt == 32'd50_000_000 - 1) ? 1 : 0;
wire [7:0]rs232_rx_data;
wire uart_tx_int;

uart_top
#(
	.UART_CLK_MHZ(50)
)
u_uart_top
(
	.clk(clk),
	.rst_n(rst_n),
	.baud_sel_i(3'd7),

	.rs232_tx_start(uart_tx_start),
	.rs232_tx_data_i(rs232_rx_data),
	.rs232_tx_data_o(rs232_tx_data_o),
	.rs232_tx_int(uart_tx_int),

	.rs232_rx_data_i(rs232_rx_data_i),
	.rs232_rx_data_o(rs232_rx_data),
	.rs232_rx_int(uart_tx_start)
);

ila_1 uart_rx_probe (
	.clk(clk), // input wire clk
	.probe0({12'b0,rs232_rx_data}), // input wire [7:0] probe0
	.probe1({12'b0,uart_tx_start}),
	.probe2({12'b0,uart_tx_int})
);


endmodule
