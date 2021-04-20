`timescale 1ns/1ns

module GMII_UDP_Loopback_Test(
	input  clk,
	input  rst_n,
	
	output e_gtxc,
	output [7:0]e_txd,
	output e_txen,
	
	input  e_rxc,
	output e_rst
);

assign e_rst = 1;
wire [7:0]fifo_wrdata;
wire fifo_wrreq;

wire tx_start;
wire clk125M_o;
wire [15:0]rx_data_length;
wire one_pkt_done;

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
	
	//上电后先清零fifo
reg [31:0]delay_cnt;
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		delay_cnt <= 32'd0;
	else if(delay_cnt == 32'd25_000_000 - 1)
		delay_cnt <= 32'd0;
	else
		delay_cnt <= delay_cnt + 1'd1;
end

assign tx_start = (delay_cnt == 32'd25_000_000 - 1) ? 1'b1 : 1'b0;	

UDP_Send UDP_Send(
	.Clk(),
	.GMII_GTXC(e_gtxc),
	.GMII_TXD(e_txd),
	.GMII_TXEN(e_txen),
	.Rst_n(rst_n),
	.Go(tx_start),
	.Tx_Done(),
	.data_length(16'd1),
	.des_ip(32'hc0_a8_00_03),
	.des_mac(48'hFF_FF_FF_FF_FF_FF),
	//.des_mac(48'h84_7B_EB_48_94_13),
	.des_port(16'd8080),
	.src_ip(32'hc0_a8_00_02),
	.src_mac(48'h00_0a_35_01_fe_c0),
	.src_port(16'd8080),
	.wrclk(clk125M_o),
	.wrdata(8'd28),
	.wrreq(fifo_wrreq),
	.aclr(),
	.wrusedw()
);
  
endmodule
