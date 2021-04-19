`timescale 1ns / 1ps

module ipsend
(
	input              	clk,
	output reg         	txen,
	output reg         	txer,
	output reg [7:0]   	dataout,
	input  [31:0]  		crc,
	output reg			data_req,
	input  [31:0]  		datain,
	output reg         	crcen,
	output reg         	crcre,
	input 				tx_start,
	
	input      [15:0]  	tx_data_length,
	input      [15:0]  	tx_total_length
				  
);

reg [31:0] datain_reg;

reg [31:0] ip_header [6:0];                  

reg [7:0] preamble [7:0];
reg [7:0] mac_addr [13:0];
reg [4:0] i,j;

reg [31:0] check_buffer;
reg [15:0] tx_data_counter;

parameter 	UDP_TX_IDLE = 		7'b000_0000,
			UDP_TX_START = 		7'b000_0001,
			UDP_TX_MAKE = 		7'b000_0010,
			UDP_TX_SEND55 = 	7'b000_0100,
			UDP_TX_SENDMAC = 	7'b000_1000,
			UDP_TX_SENDHEADER = 7'b001_0000,
			UDP_TX_SENDDATA = 	7'b010_0000,
			UDP_TX_SENDCRC = 	7'b100_0000;

reg [7:0]udp_tx_n_state;
reg [7:0]udp_tx_c_state;

initial begin
	udp_tx_c_state <= UDP_TX_IDLE;
	udp_tx_n_state <= UDP_TX_IDLE;
	preamble[0] <= 8'h55;
	preamble[1] <= 8'h55;
	preamble[2] <= 8'h55;
	preamble[3] <= 8'h55;
	preamble[4] <= 8'h55;
	preamble[5] <= 8'h55;
	preamble[6] <= 8'h55;
	preamble[7] <= 8'hD5;
	mac_addr[0] <= 8'hFF;                 //目的MAC地址 ff-ff-ff-ff-ff-ff, 全ff为广播包
	mac_addr[1] <= 8'hFF;
	mac_addr[2] <= 8'hFF;
	mac_addr[3] <= 8'hFF;
	mac_addr[4] <= 8'hFF;
	mac_addr[5] <= 8'hFF;
	mac_addr[6] <= 8'h00;                 //源MAC地址 00-0A-35-01-FE-C0
	mac_addr[7] <= 8'h0A;
	mac_addr[8] <= 8'h35;
	mac_addr[9] <= 8'h01;
	mac_addr[10] <= 8'hFE;
	mac_addr[11] <= 8'hC0;
	mac_addr[12] <= 8'h08;                //0800: IP包类�?
	mac_addr[13] <= 8'h00;
	datain_reg <= 32'd0;
	i <= 5'd0;
	j <= 5'd0;
end
 
always@(negedge clk) begin
	case(udp_tx_c_state)
		UDP_TX_IDLE: begin 
			if(tx_start) begin
				udp_tx_n_state <= UDP_TX_START;
			end
		end
		UDP_TX_START: begin
			udp_tx_n_state <= UDP_TX_MAKE;
		end
		UDP_TX_MAKE: begin
			if(i == 5'd2-1) begin
				udp_tx_n_state <= UDP_TX_SEND55;
			end
		end
		UDP_TX_SEND55: begin
			if(i == 5'd7-1) begin
				udp_tx_n_state <= UDP_TX_SENDMAC;
			end
		end
		UDP_TX_SENDMAC: begin
			if(i == 5'd13-1) begin
				udp_tx_n_state <= UDP_TX_SENDHEADER;
			end
		end
		UDP_TX_SENDHEADER: begin
			if(j == 5'd6 && i == 5'd3-1) begin
				udp_tx_n_state <= UDP_TX_SENDDATA;	
			end
		end
		UDP_TX_SENDDATA: begin
			if(tx_data_counter == tx_data_length - 9) begin       //send last payload byte
				udp_tx_n_state <= UDP_TX_SENDCRC;
			end
		end
		UDP_TX_SENDCRC: begin
			if(i == 5'd3-1) begin
				udp_tx_n_state <= UDP_TX_IDLE;
			end
		end
		default: udp_tx_n_state <= UDP_TX_IDLE;
	endcase
end

always @(negedge clk) begin
	udp_tx_c_state <= udp_tx_n_state;
end

always@(negedge clk) begin
	case(udp_tx_c_state)
		UDP_TX_IDLE: begin 
			txer<=1'b0;
			txen<=1'b0;
			crcen<=1'b0;
			crcre<=1;
			j<=0;
			dataout<=0;
			tx_data_counter<=0;
			ip_header[0] <= 32'b0;
			ip_header[1] <= 32'b0;
			ip_header[2] <= 32'b0;
			ip_header[3] <= 32'b0;
			ip_header[4] <= 32'b0;
			ip_header[5] <= 32'b0;
			ip_header[6] <= 32'b0;
			data_req <= 0;
		end
		UDP_TX_START: begin
			data_req <= 1;
			ip_header[0]<={16'h4500, tx_total_length};        
			ip_header[1][31:16]<=ip_header[1][31:16] + 1'b1;
			ip_header[1][15:0] <= 16'h4000;
			ip_header[2] <= 32'h80110000;
			ip_header[3] <= 32'hc0a80002;
			ip_header[4] <= 32'hc0a80003;
			ip_header[5] <= 32'h1f901f90;
			ip_header[6] <= {tx_data_length, 16'h0000};
		end
		UDP_TX_MAKE: begin
			data_req <= 0;
			case(i)
				5'd0: begin
					check_buffer <= ip_header[0][15:0]+ip_header[0][31:16]+ip_header[1][15:0]+ip_header[1][31:16]+ip_header[2][15:0]+
					               	  ip_header[2][31:16]+ip_header[3][15:0]+ip_header[3][31:16]+ip_header[4][15:0]+ip_header[4][31:16];
					i<= i + 1;
				end
				5'd1: begin
					check_buffer[15:0] <= check_buffer[31:16]+check_buffer[15:0]; 
					i<= i + 1;
				end
				5'd2: begin
					ip_header[2][15:0] <= ~check_buffer[15:0]; 
					i <= 0;
				end
				default: i <= 0;
			endcase
		end
		UDP_TX_SEND55: begin
			txen <= 1'b1;                             //GMII数据发�?�有�?
			crcre <= 1'b1;                            //reset crc  
			if(i == 5'd7) begin
				dataout[7:0] <= preamble[i][7:0];
				i <= 0;
			end
			else begin                        
				dataout[7:0] <= preamble[i][7:0];
				i <= i+1;
			end
		end
		UDP_TX_SENDMAC: begin
			crcen <= 1'b1;                            //crc校验使能，crc32数据校验从目标MAC�?�?		
			crcre <= 1'b0;                            			
			if(i == 5'd13) begin
				dataout[7:0] <= mac_addr[i][7:0];
				i <= 0;
			end
			else begin                        
				dataout[7:0] <= mac_addr[i][7:0];
				i <= i + 1'b1;
			end
		end
		UDP_TX_SENDHEADER: begin
			datain_reg <= datain;                   //准备�?要发送的数据	
			if(j == 6) begin
				case(i)
					5'd0: begin
						dataout[7:0] <= ip_header[j][31:24];
						i <= i+1'b1;
					end
					5'd1: begin
						dataout[7:0] <= ip_header[j][23:16];
						i <= i+1'b1;
					end
					5'd2: begin
						dataout[7:0] <= ip_header[j][15:8];
						i <= i+1'b1;
					end
					5'd3: begin
						dataout[7:0] <= ip_header[j][7:0];
						i <= 0;
						j <= 0;	
					end
					default: begin
						txer <= 1'b1;
						dataout[7:0] <= 8'd0;
						i <= 0;
						j <= 0;
					end
				endcase                          
			end
			else begin
				case(i)
					5'd0: begin
						dataout[7:0] <= ip_header[j][31:24];
						i <= i+1'b1;
					end
					5'd1: begin
						dataout[7:0] <= ip_header[j][23:16];
						i <= i+1'b1;
					end
					5'd2: begin
						dataout[7:0] <= ip_header[j][15:8];
						i <= i+1'b1;
					end
					5'd3: begin
						dataout[7:0] <= ip_header[j][7:0];
						i <= 0;
						j <= j+1'b1;	
					end
					default: begin
						txer <= 1'b1;
					end
				endcase 
			end
		end
		UDP_TX_SENDDATA: begin
			if(tx_data_counter == tx_data_length-9) begin       //send last payload byte
				case(i)
					5'd0: begin
						dataout[7:0]<=datain_reg[31:24];
						i <= i + 1'd1;
					end
					5'd1: begin
						dataout[7:0]<=datain_reg[23:16];
						i <= i + 1'd1;
					end
					5'd2: begin
						dataout[7:0] <= datain_reg[15:8];
						i <= i + 1'd1;
					end
					5'd3: begin
						dataout[7:0] <= datain_reg[7:0];
						i <= 0;
					end
					default: begin
						txer <= 1'b1;
					end
				endcase
			end
			else begin
				tx_data_counter <= tx_data_counter + 1'b1;
				case(i)
					5'd0: begin
						dataout[7:0]<=datain_reg[31:24];
						i <= i + 1'd1;
					end
					5'd1: begin
						dataout[7:0]<=datain_reg[23:16];
						i <= i + 1'd1;
					end
					5'd2: begin
						data_req <= 1;
						dataout[7:0] <= datain_reg[15:8];
						i <= i + 1'd1;
					end
					5'd3: begin
						data_req <= 0;
						dataout[7:0] <= datain_reg[7:0];
						datain_reg <= datain;  
						i <= 0;
					end
					default: begin
						txer <= 1'b1;
					end
				endcase
			end
		end
		UDP_TX_SENDCRC: begin
			crcen <= 1'b0;
			case(i)
				5'd0: begin
					dataout[7:0] <= {~crc[24], ~crc[25], ~crc[26], ~crc[27], ~crc[28], ~crc[29], ~crc[30], ~crc[31]};
					i <= i+1'b1;
				end
				5'd1: begin
					dataout[7:0]<={~crc[16], ~crc[17], ~crc[18], ~crc[19], ~crc[20], ~crc[21], ~crc[22], ~crc[23]};
					i <= i+1'b1;
				end
				5'd2: begin
					dataout[7:0]<={~crc[8], ~crc[9], ~crc[10], ~crc[11], ~crc[12], ~crc[13], ~crc[14], ~crc[15]};
					i <= i+1'b1;
				end
				5'd3: begin
					dataout[7:0]<={~crc[0], ~crc[1], ~crc[2], ~crc[3], ~crc[4], ~crc[5], ~crc[6], ~crc[7]};
					i <= 0;
				end
				default: txer<=1'b1;
			endcase
		end
		default: txer<=1'b1;
	endcase

end

//always @(*) begin
//	if((udp_tx_c_state == UDP_TX_SENDDATA && (tx_data_counter < tx_data_length - 10) && i == 5'd2) || udp_tx_c_state == UDP_TX_START) begin
//		data_req = 1;
//	end
//	else begin
//		data_req = 0;
//	end
//end

//ila_0 eth_tx_ila (
//	.clk(clk), // input wire clk
//	.probe0(udp_tx_n_state), // input wire [7:0] probe0
//	.probe1(0),
//	.probe2(0)
//);


endmodule


