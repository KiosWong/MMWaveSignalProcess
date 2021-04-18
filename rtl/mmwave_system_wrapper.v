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
	
	input [12:0]ad_data_i,
	output ad_clk_o,
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

wire s_ad_frontend_en;
wire [12:0]w_ad_frontend_out_data;
wire w_ad_data_valid;

wire w_vco_mode;
wire [31:0]w_vco_trigger_freq_psc;
wire [4:0]w_vco_chirp_num;
wire [15:0]w_vco_chirp_freq_psc;

assign w_vco_mode = 1'b1;
assign w_vco_trigger_freq_psc = 32'd2_500_000;
assign w_vco_chirp_num = 5'd2;
assign w_vco_chirp_freq_psc = 16'd5;

vco_comp_wrapper
#(
	.SYS_CLK_FREQ_MHZ(50)
)
u_vco_comp_wrapper
(
	.clk(clk),
	.rst_n(rst_n),
	.mode_sel_i(w_vco_mode),
	.trigger_freq_psc_i(w_vco_trigger_freq_psc),
	.chirp_num_i(w_vco_chirp_num),
	.chirp_freq_psc_i(w_vco_chirp_freq_psc),
	.vco_da_clk_o(vco_da_clk_o),
	.vco_out_o(vco_out_o)
);

ad9226 u_ad_frontend
(
	.clk(clk),
	.rst_n(rst_n),
	.en(s_ad_frontend_en),
	.clk_psc_period_i(32'd50),	//20KHz @ 50MHz sys clk freq
	.ad_data_i(ad_data_i),
	.ad_clk_o(ad_clk_o),
	.ad_data_o(w_ad_frontend_out_data),
	.ad_data_valid_o(w_ad_data_valid)
);

wire sampled_data_valid_o;
wire [12:0]w_sample_data_out;

dowm_sample
#(

	.SYS_CLK_FREQ_MHZ(SYS_CLK_FREQ_MHZ)
)
u_dowm_sample
(
	.clk(clk),
	.rst_n(rst_n),

	.sample_psc_i(16'd2),
	.raw_data_valid_i(w_ad_data_valid),
	.raw_data_i(w_ad_frontend_out_data),
	.sampled_data_valid_o(sampled_data_valid_o),
	.sampled_data_o(w_sample_data_out)
);

reg  s_fifo_rd_en;
wire s_fifo_empty;
wire s_fifo_full;
wire [12:0]w_fifo_out;

assign s_ad_frontend_en = (!s_fifo_full) ? 1 : 0;

sync_bram_fifo
#(
	.DATA_WIDTH(13),
	.BUF_SIZE(1024)
)
u_sync_bram_fifo
(
	.clk(clk),
	.rst_n(rst_n),
	.clear(0),
	.fifo_din(w_sample_data_out),
	.fifo_wr_en(sampled_data_valid_o),
	.fifo_rd_en(s_fifo_rd_en),
	.fifo_rd_rewind(0),
	.fifo_empty(s_fifo_empty),
	.fifo_full(s_fifo_full),
	.fifo_out(w_fifo_out)
);

wire eth_tx_data_req;
wire [31:0]w_eth_tx_data;
wire [31:0]eth_fifo_data_in;

assign eth_fifo_data_in = {20'b0, w_sample_data_out[11:0]};

async_fifo
#(
	.DATA_WIDTH(32),
	.ADDR_WIDTH(8)
)
u_async_fifo
(
	
	.rst_n(rst_n),
	.wr_clk(clk),
	.rd_clk(e_rxc),
	
	.fifo_din(eth_fifo_data_in),
	.fifo_wr_en(sampled_data_valid_o),
	.fifo_rd_en(eth_tx_data_req),
	.fifo_empty(),
	.fifo_full(),
	.fifo_out(w_eth_tx_data)

);

wire s_rs232_tx_int;

/* uart tx fsm */
localparam 	UART_TX_IDLE		= 6'b0000_00,
			UART_TX_RD			= 6'b0000_01,
			UART_TX_BYTE_1		= 6'b0000_10,
			UART_TX_BYTE_2		= 6'b0001_00,
			UART_TX_BYTE_3		= 6'b0010_00,
			UART_TX_BYTE_4		= 6'b0100_00,
			UART_TX_DONE		= 6'b1000_00;

reg [5:0]uart_tx_c_state;
reg [5:0]uart_tx_n_state;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		uart_tx_n_state <= 6'b0;
	end
	else begin
		case(uart_tx_c_state)
			UART_TX_IDLE: begin
				if(!s_fifo_empty) begin
					uart_tx_n_state <= UART_TX_RD;
				end
				else begin
					uart_tx_n_state <= uart_tx_n_state;
				end
			end
			/* handle 1 clk fifo read latency */
			UART_TX_RD: uart_tx_n_state <= UART_TX_BYTE_1;
			UART_TX_BYTE_1: begin
				if(s_rs232_tx_int) begin
					uart_tx_n_state <= UART_TX_BYTE_2;
				end
				else begin
					uart_tx_n_state <= uart_tx_n_state;
				end
			end
			UART_TX_BYTE_2: begin
				if(s_rs232_tx_int) begin
					uart_tx_n_state <= UART_TX_BYTE_3;
				end
				else begin
					uart_tx_n_state <= uart_tx_n_state;
				end
			end
			UART_TX_BYTE_3: begin
				if(s_rs232_tx_int) begin
					uart_tx_n_state <= UART_TX_BYTE_4;
				end
				else begin
					uart_tx_n_state <= uart_tx_n_state;
				end
			end
			UART_TX_BYTE_4: begin
				if(s_rs232_tx_int) begin
					uart_tx_n_state <= UART_TX_DONE;
				end
				else begin
					uart_tx_n_state <= uart_tx_n_state;
				end
			end
			UART_TX_DONE: uart_tx_n_state <= UART_TX_IDLE;
			default: uart_tx_n_state <= UART_TX_IDLE;
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		uart_tx_c_state <= 6'b0;
	end
	else begin
		uart_tx_c_state <= uart_tx_n_state;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		s_fifo_rd_en <= 1'b0;
	end
	else if(uart_tx_c_state == UART_TX_IDLE && !s_fifo_empty) begin
		s_fifo_rd_en <= 1'b1;
	end
	else begin
		s_fifo_rd_en <= 1'b0;
	end
end

reg [12:0]r_fifo_out;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		r_fifo_out <= 13'b0;
	end
	else if(uart_tx_c_state == UART_TX_RD) begin
		r_fifo_out <= w_fifo_out;
	end
end

reg s_uart_tx_start;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		s_uart_tx_start <= 1'b0;
	end
	else if((uart_tx_n_state == UART_TX_BYTE_1 && uart_tx_c_state == UART_TX_RD) || (uart_tx_n_state == UART_TX_BYTE_2 && uart_tx_c_state == UART_TX_BYTE_1) || (uart_tx_n_state == UART_TX_BYTE_3 && uart_tx_c_state == UART_TX_BYTE_2) || (uart_tx_n_state == UART_TX_BYTE_4 && uart_tx_c_state == UART_TX_BYTE_3)) begin
		s_uart_tx_start <= 1'b1;
	end
	else begin
		s_uart_tx_start <= 1'b0;
	end
end

reg r_s_uart_tx_start;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		r_s_uart_tx_start <= 1'b0;
	end
	else begin
		r_s_uart_tx_start <= s_uart_tx_start;
	end
end

reg [7:0]uart_tx_data;
always @(*) begin
	if(uart_tx_c_state == UART_TX_BYTE_1) begin
		uart_tx_data = 8'b0;
	end
	else if(uart_tx_c_state == UART_TX_BYTE_2) begin
		uart_tx_data = 8'b0;
	end
	else if(uart_tx_c_state == UART_TX_BYTE_3) begin
		uart_tx_data = {3'b0, r_fifo_out[12:8]};
	end
	else if(uart_tx_c_state == UART_TX_BYTE_4) begin
		uart_tx_data = r_fifo_out[7:0];
	end
	else begin
		uart_tx_data = 8'b0;
	end
end

uart_tx
#(
	.UART_CLK_MHZ(SYS_CLK_FREQ_MHZ)
)
u_uart_tx
(
	.clk(clk),
	.rst_n(rst_n),
	.baud_sel_i(3'd7),	//921600bps
	.rs232_tx_start(r_s_uart_tx_start),
	.rs232_tx_data_i(uart_tx_data),
	.rs232_tx_int(s_rs232_tx_int),
	.rs232_tx_o(rs232_tx_data_o)
);


reg [4:0]eth_data_cnt;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		eth_data_cnt <= 5'b0;
	end
	else if(eth_data_cnt == 5'd31) begin
		eth_data_cnt <= 5'b0;
	end
	else if(sampled_data_valid_o) begin
		eth_data_cnt <= eth_data_cnt + 1'b1;
	end
end

reg [31:0]r_eth_tx_data;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		r_eth_tx_data <= 32'b0;
	end
	else if(sampled_data_valid_o) begin
		r_eth_tx_data <= eth_fifo_data_in;
	end
end

reg r_eth_tx_start[1:0];
always @(posedge e_rxc or negedge rst_n) begin
	if(!rst_n) begin
		r_eth_tx_start[0] <= 1'b0;
		r_eth_tx_start[1] <= 1'b0;
	end
	else begin
		r_eth_tx_start[0] <= (eth_data_cnt == 5'd15) ? 1 : 0;
		r_eth_tx_start[1] <= r_eth_tx_start[0];
	end
end

wire s_eth_tx_start;
assign s_eth_tx_start = r_eth_tx_start[0] & ~r_eth_tx_start[1];
wire [7:0]w_e_txd;

udp_top u_udp_top(
	.rst_n(rst_n),                        

	.tx_start(s_eth_tx_start),
	.tx_data_req(eth_tx_data_req),
	.tx_data(w_eth_tx_data),
	.tx_total_length(16'd156),
	.tx_data_length(16'd136),
	
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

/* we meet some timing violations here, udp packets collapse if the ila is removed*/
/* strangely, the following ila improves total timing performace, by changing routing structure */
ila_0 eth_ila (
	.clk(e_rxc), // input wire clk
	.probe0(e_txd), // input wire [7:0] probe0
	.probe1(0),
	.probe2(0)
);

endmodule