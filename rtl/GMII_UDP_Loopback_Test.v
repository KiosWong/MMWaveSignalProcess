`timescale 1ns/1ns
module GMII_UDP_Loopback_Test(
	Clk,
	Rst_n,
	
	GMII_GTXC,
	GMII_TXD,
	GMII_TXEN,
	
	GMII_RXC,
	GMII_RXD,
	GMII_RXDV,

	ETH_Rst_n
);
	input Clk;
	input Rst_n;
	
	output GMII_GTXC;
	output [7:0]GMII_TXD;
	output GMII_TXEN;
	
	input GMII_RXC;
	input [7:0]GMII_RXD;
	input GMII_RXDV;
	

	output ETH_Rst_n;

	assign ETH_Rst_n = 1;
	wire [7:0]fifo_wrdata;
	wire fifo_wrreq;
	
  	reg TX_Go;
	wire clk125M_o;
	wire [15:0]rx_data_length;
	wire one_pkt_done;

	pll pll(
		.inclk0(Clk),
		.c0(GMII_GTXC)
	);
	
	//上电后先清零fifo
	reg [23:0]delay_cnt;
	always@(posedge Clk or negedge Rst_n)
	begin
		if(!Rst_n)
			delay_cnt <= 24'd0;
		else if(delay_cnt >= 24'hfffffd)
			delay_cnt <= delay_cnt;
		else
			delay_cnt <= delay_cnt + 1'd1;
	end
	
	wire fifo_aclr;
	assign fifo_aclr = (delay_cnt >= 24'd100)?1'b0:1'b1;	
	
	UDP_Send UDP_Send(
		.Clk(),
		.GMII_GTXC(GMII_GTXC),
		.GMII_TXD(GMII_TXD),
		.GMII_TXEN(GMII_TXEN),
		.Rst_n(Rst_n),
		.Go(TX_Go),
		.Tx_Done(),
		.data_length(rx_data_length),
		.des_ip(32'hc0_a8_00_03),
		.des_mac(48'hFF_FF_FF_FF_FF_FF),
		//.des_mac(48'h84_7B_EB_48_94_13),
		.des_port(16'd6000),
		.src_ip(32'hc0_a8_00_02),
		.src_mac(48'h00_0a_35_01_fe_c0),
		.src_port(16'd5000),
		.wrclk(clk125M_o),
		.wrdata(fifo_wrdata),
		.wrreq(fifo_wrreq),
		.aclr(fifo_aclr),
		.wrusedw()
	);
	
  udp_gmii_rx udp_gmii_rx(
    .reset_n       (Rst_n               ),

    .gmii_rx_en    (1'b1                  ),

    .local_mac     (48'h00_0a_35_01_fe_c0 ),
    .local_ip      (32'hc0_a8_00_02       ),
    .local_port    (16'd5000              ),

    .fifo_full     (0             ),
    .fifo_wr       (fifo_wrreq               ),
    .fifo_din      (fifo_wrdata              ),
    .clk125M_o     (clk125M_o             ),

    .exter_mac     (                      ),
    .exter_ip      (                      ),
    .exter_port    (                      ),
    .rx_data_length(rx_data_length        ),

    .one_pkt_done  (one_pkt_done          ),
    .pkt_error     (             ),
    .debug_cal_crc (                      ),

    .gmii_rx_clk   (GMII_RXC           ),
    .gmii_rxdv     (GMII_RXDV             ),
    .gmii_rxd      (GMII_RXD              )
  );
  
  /*
  由于发送和接收虽然都是125MHz时钟，但是接收时钟是PHY芯
  片提供给FPGA的，发送时钟是FPGA自己通过PLL产生的，属于
  非同源时钟，为了确保这两个同源时钟域中间的单脉冲信号能
  够确实生效，所以这里将one_pkt_done扩宽三倍后再以太网
  发送模块.
  */
	reg [2:0]Go;
	
	always@(posedge clk125M_o)
		Go <= {Go[1:0],one_pkt_done};
		
	always@(posedge clk125M_o)	
		TX_Go <= (|Go);	
	
endmodule
