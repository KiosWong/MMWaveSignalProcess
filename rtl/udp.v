//////////////////////////////////////////////////////////////////////////////////
// Module Name:    udp数据通信模块
//////////////////////////////////////////////////////////////////////////////////

module udp
(
	input  wire			reset_n,
	input  wire         e_rxc,
	output wire	        e_txen,
	output wire	[7:0]   e_txd,                              
	output wire         e_txer,		
	
	input 				tx_start,
	output wire			tx_data_req,
	input  wire [31:0]  tx_data,                         //ram读出的数�?
	input  wire [15:0]  tx_data_length,                      //发�?�IP包的数据长度/
	input  wire [15:0]  tx_total_length,                     //发�?�IP包的总长�?/
	
	input  [31:0]src_ip_addr,
	input  [31:0]dst_ip_addr,
	input  [15:0]src_port,
	input  [15:0]dst_port
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
	.tx_data_length(tx_data_length),
	.tx_total_length(tx_total_length),
	.src_ip_addr(src_ip_addr),
	.dst_ip_addr(dst_ip_addr),
	.src_port(src_port),
	.dst_port(dst_port)
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

endmodule
