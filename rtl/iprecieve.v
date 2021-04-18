`timescale 1ns / 1ps
/****************************************/
//      GMII UDP数据包发送模块�??�?�?�?�?�?�?//
/****************************************/
module iprecieve(
	 input clk,                                  //GMII接收时钟
	 input [7:0] datain,                         //GMII接收数据
	 input e_rxdv,                               //GMII接收数据有效信号
	 input clr,                                  //清除/复位信号
	 output reg [47:0]  board_mac,               //�?发板端的MAC
	 output reg [47:0]  pc_mac,	               //PC端的MAC 
	 output reg [15:0]  IP_Prtcl,                //IP 类型
	 output reg         valid_ip_P,					 
	 output reg [159:0] IP_layer,                //IP包头数据 
	 output reg [31:0]  pc_IP,                   //PC端的IP地址
	 output reg [31:0]  board_IP,                //�?发板端的IP地址	 
	 output reg [63:0]  UDP_layer,               //UDP包头	 

	 output reg [31:0]  data_o,                  //UDP接收的数�?            

	 output reg [15:0]  rx_total_length,         //UDP frame的�?�长�?
	 output reg         data_o_valid,            //UDP数据有效信号// 
	 output reg [15:0]  rx_data_length,          //接收的UDP数据包的长度
	 output reg         data_received             //接收到UDP包标�?
					
 );

reg [3:0]  rx_state;
reg [15:0] myIP_Prtcl;
reg [159:0] myIP_layer;
reg [63:0] myUDP_layer;
reg [31:0] mydata; 
reg [2:0] byte_counter;
reg [4:0] state_counter;
reg [95:0] mymac;
reg [15:0] data_counter;
	 
parameter idle=4'd0,six_55=4'd1,spd_d5=4'd2,rx_mac=4'd3,rx_IP_Protocol=4'd4,
	       rx_IP_layer=4'd5,rx_UDP_layer=4'd6,rx_data=4'd7,rx_finish=4'd8;
	 
initial
begin
	 rx_state<=idle;
end

//UDP数据接收程序	 	
always@(posedge clk)
	begin
	if(!clr) begin
        rx_state<=idle;
        data_received<=1'b0;
    end
    else
		case(rx_state)
        idle: begin
            valid_ip_P<=1'b0;
            byte_counter<=3'd0;
            data_counter<=10'd0;
            mydata<=32'd0;
            state_counter<=5'd0;	
            data_o_valid<=1'b0; 
            if(e_rxdv==1'b1) begin                           //接收数据有效为高，开始接收数�?
                if(datain[7:0]==8'h55) begin                  //接收到第�?�?55//
                rx_state<=six_55;
                mydata<={mydata[23:0],datain[7:0]};
                end
            else
                rx_state<=idle;
            end
        end		
        six_55: begin                                              //接收6�?0x55//
            if ((datain[7:0]==8'h55)&&(e_rxdv==1'b1)) begin
                if (state_counter==5) begin
                    state_counter<=0;
                    rx_state<=spd_d5;
                end
                else
                    state_counter<=state_counter+1'b1;
                end
            else
                rx_state<=idle;
        end
        spd_d5: begin                                              //接收1�?0xd5//
            if((datain[7:0]==8'hd5)&&(e_rxdv==1'b1)) 
                rx_state<=rx_mac;			
            else 
                rx_state<=idle;
        end	
        rx_mac: begin                    //接收目标mac address和源mac address
            if(e_rxdv==1'b1) begin
                if(state_counter<5'd11)	begin
                    mymac<={mymac[87:0],datain};
                    state_counter<=state_counter+1'b1;
                end
            else begin
                board_mac<=mymac[87:40];
                pc_mac<={mymac[39:0],datain};
                state_counter<=5'd0;
                if((mymac[87:72]==16'h000a)&&(mymac[71:56]==16'h3501)&&(mymac[55:40]==16'hfec0))   //判断目标MAC Address是否为本FPGA
                    rx_state<=rx_IP_Protocol;
                else
                    rx_state<=idle;
                end
            end
            else
            rx_state<=idle;
        end
        rx_IP_Protocol: begin                                              //接收2个字节的IP TYPE//
            if(e_rxdv==1'b1) begin
                if(state_counter<5'd1) begin
                    myIP_Prtcl<={myIP_Prtcl[7:0],datain[7:0]};
                    state_counter<=state_counter+1'b1;
                end
                else begin
                    IP_Prtcl<={myIP_Prtcl[7:0],datain[7:0]};
                    valid_ip_P<=1'b1;
                    state_counter<=5'd0;
                    rx_state<=rx_IP_layer;
                end
            end
            else 
                rx_state<=idle;
        end
        rx_IP_layer: begin               //接收20字节的udp虚拟包头,ip address
            valid_ip_P<=1'b0;
            if(e_rxdv==1'b1) begin
                if(state_counter<5'd19)	begin
                    myIP_layer<={myIP_layer[151:0],datain[7:0]};
                    state_counter<=state_counter+1'b1;
                end
                else begin
                    IP_layer<={myIP_layer[151:0],datain[7:0]};
                    state_counter<=5'd0;
                    rx_state<=rx_UDP_layer;
                end
            end
            else 
                rx_state<=idle;
        end
        rx_UDP_layer: begin                //接受8字节UDP的端口号及UDP数据包长	  
            rx_total_length<=IP_layer[143:128];
            pc_IP<=IP_layer[63:32];
            board_IP<=IP_layer[31:0];
            if(e_rxdv==1'b1) begin
                if(state_counter<5'd7)	begin
                    myUDP_layer<={myUDP_layer[55:0],datain[7:0]};
                    state_counter<=state_counter+1'b1;
                end
                else begin
                    UDP_layer<={myUDP_layer[55:0],datain[7:0]};
                    rx_data_length<= myUDP_layer[23:8];                //UDP数据包的长度						
                    state_counter<=5'd0;
                    rx_state<=rx_data;
                end
            end
            else 
                rx_state<=idle;
        end
        rx_data: begin                                             //接收UDP的数�?       
        if(e_rxdv==1'b1) begin
            if (data_counter==rx_data_length-9) begin         //存最后的数据,真正的UDP数据�?要减�?8字节的UDP包头
                data_counter<=0;
                rx_state<=rx_finish;
                data_o_valid<=1'b1;               //写RAM 							 
                if(byte_counter==3'd3) begin
                    data_o<={mydata[23:0],datain[7:0]};
                    byte_counter<=0;
                end
                else if(byte_counter==3'd2) begin
                    data_o<={mydata[15:0],datain[7:0],8'h00};       //不满32bit,�?0
                    byte_counter<=0;
                end
                else if(byte_counter==3'd1) begin
                    data_o<={mydata[7:0],datain[7:0],16'h0000};     //不满32bit,�?0
                    byte_counter<=0;
                end
                else if(byte_counter==3'd0) begin
                    data_o<={datain[7:0],24'h000000};              //不满32bit,�?0
                    byte_counter<=0;
                end
        end
        else begin
            data_counter<=data_counter+1'b1;
            if(byte_counter<3'd3)	begin
                mydata<={mydata[23:0],datain[7:0]};
                byte_counter<=byte_counter+1'b1;
                data_o_valid<=1'b0;  
            end
            else begin
            data_o<={mydata[23:0],datain[7:0]};
            byte_counter<=3'd0;
            data_o_valid<=1'b1;                        //接受4byes数据,写ram请求					  
            end	
        end
        end
        else
            rx_state<=idle;
        end
        rx_finish: begin
            data_o_valid<=1'b0;           
            data_received<=1'b1;
            rx_state<=idle;
        end		
        default:rx_state<=idle;    
		endcase
		end
endmodule
