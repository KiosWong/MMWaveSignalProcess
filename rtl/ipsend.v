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
	
	output reg [3:0]   	tx_state, 
	input      [15:0]  	tx_data_length,
	input      [15:0]  	tx_total_length
				  
);


reg [31:0]  datain_reg;

reg [31:0] ip_header [6:0];                  //数据段为1K

reg [7:0] preamble [7:0];                    //preamble
reg [7:0] mac_addr [13:0];                   //mac address
reg [4:0] i,j;

reg [31:0] check_buffer;
reg [31:0] time_counter;
reg [15:0] tx_data_counter;

parameter idle=4'b0000,start=4'b0001,make=4'b0010,send55=4'b0011,sendmac=4'b0100,sendheader=4'b0101,
          senddata=4'b0110,sendcrc=4'b0111;



initial
  begin
	 tx_state<=idle;
	 preamble[0]<=8'h55;
	 preamble[1]<=8'h55;
	 preamble[2]<=8'h55;
	 preamble[3]<=8'h55;
	 preamble[4]<=8'h55;
	 preamble[5]<=8'h55;
	 preamble[6]<=8'h55;
	 preamble[7]<=8'hD5;
	 mac_addr[0]<=8'hFF;                 //目的MAC地址 ff-ff-ff-ff-ff-ff, 全ff为广播包
	 mac_addr[1]<=8'hFF;
	 mac_addr[2]<=8'hFF;
	 mac_addr[3]<=8'hFF;
	 mac_addr[4]<=8'hFF;
	 mac_addr[5]<=8'hFF;
	 mac_addr[6]<=8'h00;                 //源MAC地址 00-0A-35-01-FE-C0
	 mac_addr[7]<=8'h0A;
	 mac_addr[8]<=8'h35;
	 mac_addr[9]<=8'h01;
	 mac_addr[10]<=8'hFE;
	 mac_addr[11]<=8'hC0;
	 mac_addr[12]<=8'h08;                //0800: IP包类�?
	 mac_addr[13]<=8'h00;
	 i<=0;
 end


//UDP数据发�?�程�?	 
always@(negedge clk) begin		
		case(tx_state)
		  idle:begin
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
             if (tx_start) begin
				     tx_state<=start;
				     data_req <= 1'b1;  
             end
             else begin
             	data_req <= 0;
             end
		end
		   start:begin        //IP header
				data_req <= 1'b0; 
				ip_header[0]<={16'h4500,tx_total_length};        //版本号：4�? 包头长度�?20；IP包�?�长
				ip_header[1][31:16]<=ip_header[1][31:16]+1'b1;   //包序列号
				ip_header[1][15:0]<=16'h4000;                    //Fragment offset
				ip_header[2]<=32'h80110000;                      //mema[2][15:0] 协议�?17(UDP)
				ip_header[3]<=32'hc0a80002;                      //192.168.0.2源地�?
				ip_header[4]<=32'hc0a80003;                      //192.168.0.3目的地址广播地址
				ip_header[5]<=32'h1f901f90;                      //2个字节的源端口号�?2个字节的目的端口�?
				ip_header[6]<={tx_data_length,16'h0000};         //2个字节的数据长度�?2个字节的校验和（无）
				tx_state<=make;
         end	
         make:begin            //生成包头的校验和
			    if(i==0) begin
					  check_buffer<=ip_header[0][15:0]+ip_header[0][31:16]+ip_header[1][15:0]+ip_header[1][31:16]+ip_header[2][15:0]+
					               ip_header[2][31:16]+ip_header[3][15:0]+ip_header[3][31:16]+ip_header[4][15:0]+ip_header[4][31:16];
                 i<=i+1'b1;
				   end
             else if(i==1) begin
					   check_buffer[15:0]<=check_buffer[31:16]+check_buffer[15:0];
					   i<=i+1'b1;
				 end
			    else	begin
				      ip_header[2][15:0]<=~check_buffer[15:0];                 //header checksum
					   i<=0;
					   tx_state<=send55;
					end
		   end
			send55: begin                    //发�??8个IP前导�?:7�?55, 1个d5                    
 				 txen<=1'b1;                             //GMII数据发�?�有�?
				 crcre<=1'b1;                            //reset crc  
				 if(i==7) begin
               dataout[7:0]<=preamble[i][7:0];
					i<=0;
				   tx_state<=sendmac;
				 end
				 else begin                        
				    dataout[7:0]<=preamble[i][7:0];
				    i<=i+1;
				 end
			end	
			sendmac: begin                           //发�?�目标MAC address和源MAC address和IP包类�?  
			 	 crcen<=1'b1;                            //crc校验使能，crc32数据校验从目标MAC�?�?		
				 crcre<=1'b0;                            			
             if(i==13) begin
               dataout[7:0]<=mac_addr[i][7:0];
					i<=0;
				   tx_state<=sendheader;
				 end
				 else begin                        
				    dataout[7:0]<=mac_addr[i][7:0];
				    i<=i+1'b1;
				 end
			end
			sendheader: begin                        //发�??7�?32bit的IP 包头
				datain_reg<=datain;                   //准备�?要发送的数据	
			   if(j==6) begin                            
					  if(i==0) begin
						 dataout[7:0]<=ip_header[j][31:24];
						 i<=i+1'b1;
					  end
					  else if(i==1) begin
						 dataout[7:0]<=ip_header[j][23:16];
						 i<=i+1'b1;
					  end
					  else if(i==2) begin
						 dataout[7:0]<=ip_header[j][15:8];
						 i<=i+1'b1;
					  end
					  else if(i==3) begin
						 dataout[7:0]<=ip_header[j][7:0];
						 i<=0;
						 j<=0;
						 tx_state<=senddata;			 
					  end
					  else
						 txer<=1'b1;
				end		 
				else begin
					  if(i==0) begin
						 dataout[7:0]<=ip_header[j][31:24];
						 i<=i+1'b1;
					  end
					  else if(i==1) begin
						 dataout[7:0]<=ip_header[j][23:16];
						 i<=i+1'b1;
					  end
					  else if(i==2) begin
						 dataout[7:0]<=ip_header[j][15:8];
						 i<=i+1'b1;
					  end
					  else if(i==3) begin
						 dataout[7:0]<=ip_header[j][7:0];
						 i<=0;
						 j<=j+1'b1;
					  end					
					  else
						 txer<=1'b1;
				end
			 end
			 senddata:begin                                      //send udp payload
			   if(tx_data_counter==tx_data_length-9) begin       //send last payload byte
				   tx_state<=sendcrc;	
					if(i==0) begin    
					  dataout[7:0]<=datain_reg[31:24];
					  i<=0;
					end
					else if(i==1) begin
					  dataout[7:0]<=datain_reg[23:16];
					  i<=0;
					end
					else if(i==2) begin
					  dataout[7:0]<=datain_reg[15:8];
					  i<=0;
					end
					else if(i==3) begin
			        	dataout[7:0]<=datain_reg[7:0];
					  	datain_reg<=datain;                       //准备数据
					  	i<=0;
					end
            	end
				else begin                                     //发�?�其它的数据�?
					tx_data_counter<=tx_data_counter+1'b1;			
					if(i == 0) begin  
					  dataout[7:0]<=datain_reg[31:24];
					  i<=i+1'b1;
					end
					else if(i == 1) begin
						dataout[7:0]<=datain_reg[23:16];
						i<=i+1'b1;
					end
					else if(i == 2) begin
						dataout[7:0]<=datain_reg[15:8];
						i<=i+1'b1;
						if(tx_data_counter < tx_data_length - 10) begin
							data_req <= 1'b1; 
						end
					end
					else if(i == 3) begin
						data_req <= 1'b0; 
						dataout[7:0]<=datain_reg[7:0];
					  	datain_reg<=datain;                       //准备数据					  
					  	i<=0; 				  
					end
				end
			end	
			sendcrc: begin                              //发�??32位的crc校验
				crcen<=1'b0;
				if(i==0)	begin
					  dataout[7:0] <= {~crc[24], ~crc[25], ~crc[26], ~crc[27], ~crc[28], ~crc[29], ~crc[30], ~crc[31]};
					  i<=i+1'b1;
					end
				else begin
				  if(i==1) begin
					   dataout[7:0]<={~crc[16], ~crc[17], ~crc[18], ~crc[19], ~crc[20], ~crc[21], ~crc[22], ~crc[23]};
						i<=i+1'b1;
				  end
				  else if(i==2) begin
					   dataout[7:0]<={~crc[8], ~crc[9], ~crc[10], ~crc[11], ~crc[12], ~crc[13], ~crc[14], ~crc[15]};
						i<=i+1'b1;
				  end
				  else if(i==3) begin
					   dataout[7:0]<={~crc[0], ~crc[1], ~crc[2], ~crc[3], ~crc[4], ~crc[5], ~crc[6], ~crc[7]};
						i<=0;
						tx_state<=idle;
				  end
				  else begin
                  txer<=1'b1;
				  end
				end
			end					
			default:tx_state<=idle;		
       endcase	  
 end
endmodule


