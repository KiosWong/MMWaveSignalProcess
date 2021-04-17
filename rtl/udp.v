//////////////////////////////////////////////////////////////////////////////////
// Module Name:    udp数据通信模块
//////////////////////////////////////////////////////////////////////////////////

module udp
(
	input  wire			reset_n,
	input  wire         e_rxc,
	input  wire [7:0]   e_rxd, 
	input  wire         e_rxdv,
	output wire	        e_txen,
	output wire	[7:0]   e_txd,                              
	output wire         e_txer,		
	
	output wire 	    data_o_valid,                        //接收数据有效信号// 
	output wire [31:0]  ram_wr_data,                         //接收到的32bit IP包数�?//  
	output wire [15:0]  rx_total_length,                     //接收IP包的总长�?
	
	output wire [3:0]   rx_state,                            //UDP数据接收状�?�机
	output wire [15:0]  rx_data_length,		                 //接收IP包的数据长度/
	
	input 				tx_start,
	output wire			tx_data_req,
	input  wire [31:0]  tx_data,                         //ram读出的数�?
	output [3:0]        tx_state,                            //UDP数据发�?�状态机
	input  wire [15:0]  tx_data_length,                      //发�?�IP包的数据长度/
	input  wire [15:0]  tx_total_length,                     //发�?�IP包的总长�?/
	output wire         data_received
);

wire	[31:0] crcnext;
wire	[31:0] crc32;
wire	crcreset;
wire	crcen;

ipsend ipsend_inst
(
	.clk(e_rxc),
	.txen(e_txen),
	.txer(e_txer),
	.dataout(e_txd),
	.crc(crc32),
	.datain(tx_data),
	.data_req(tx_data_req),
	.crcen(crcen),
	.crcre(crcreset),
	.tx_start(tx_start),
	.tx_state(tx_state),
	.tx_data_length(tx_data_length),
	.tx_total_length(tx_total_length)
);
	

crc	crc_inst
(
	.Clk(e_rxc),
	.Reset(crcreset),
	.Enable(crcen),
	.Data_in(e_txd),
	.Crc(crc32),
	.CrcNext(crcnext)
);

iprecieve iprecieve_inst
(
	.clk(e_rxc),
	.datain(e_rxd),
	.e_rxdv(e_rxdv),	
	.clr(reset_n),
	.board_mac(),	
	.pc_mac(),
	.IP_Prtcl(),
	.IP_layer(),
	.pc_IP(),	
	.board_IP(),
	.UDP_layer(),
	.data_o(ram_wr_data),	
	.valid_ip_P(),
	.rx_total_length(rx_total_length),
	.data_o_valid(data_o_valid),                                       
	.rx_state(rx_state),
	.rx_data_length(rx_data_length),
	.data_received(data_received)	
);
	
endmodule
