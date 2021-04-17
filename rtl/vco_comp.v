`timescale 1ns / 1ps

module da_wave_send
#(
	parameter SYS_CLK_FREQ_MHZ	= 50
)
(
	input  clk,
	input  rst_n,
	input  en,
	
	input  [15:0]da_freq_psc_cmp_i,
	input  [9:0]rom_rd_data_i,
	output reg [8:0]rom_rd_addr_o,
	
	output da_clk_o,
	output [9:0]da_data_o,
	output da_out_done_o
);

reg [15:0] freq_cnt;  

assign da_clk_o = ~clk; 
assign da_data_o = (en) ? rom_rd_data_i : 10'd512;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        freq_cnt <= 16'd0;
	end
    else if(freq_cnt == da_freq_psc_cmp_i) begin
        freq_cnt <= 16'd0;
	end
    else if(en) begin     
        freq_cnt <= freq_cnt + 16'd1;
	end
	else begin
		freq_cnt <= 16'd0;
	end
end

always @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        rom_rd_addr_o <= 10'd0;
	end
    else if(en) begin
    	if(rom_rd_addr_o == 10'd500 - 1) begin
    		rom_rd_addr_o <= 10'd0;
    	end
        else if(freq_cnt == da_freq_psc_cmp_i) begin
            rom_rd_addr_o <= rom_rd_addr_o + 10'd1;
        end    
    end            
end

assign da_out_done_o = (rom_rd_addr_o == 10'd500 - 1) ? 1 : 0;

endmodule

module vco_comp
#(
	parameter SYS_CLK_FREQ_MHZ	= 50
)
(
	input clk,
	input rst_n,
	
	output vco_da_clk_o,
	input  [15:0]vco_freq_psc_cmp_i,
	input  trigger_i,
	output [9:0]vco_out_o,
	output vco_out_done_o
);

reg s_da_wave_en;
wire s_da_out_done;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		s_da_wave_en <= 1'b0;
	end
	else if(s_da_out_done)begin
		s_da_wave_en <= 0;
	end
	else if(trigger_i) begin
		s_da_wave_en <= 1'b1;
	end
end

assign vco_out_done_o = s_da_out_done;

wire [9:0]w_rom_rd_data;
wire [8:0]w_rom_rd_addr;

da_wave_send
#(
	.SYS_CLK_FREQ_MHZ(SYS_CLK_FREQ_MHZ)
)
u_da_wave_send
(
	.clk(clk),
	.rst_n(rst_n),
	.en(s_da_wave_en),
	
	.da_freq_psc_cmp_i(vco_freq_psc_cmp_i),
	.rom_rd_data_i(w_rom_rd_data),
	.rom_rd_addr_o(w_rom_rd_addr),

	.da_clk_o(vco_da_clk_o),
	.da_data_o(vco_out_o),
	.da_out_done_o(s_da_out_done)
);

dist_mem_gen_0 vco_comp_ad_rom (
	.a(w_rom_rd_addr),      // input wire [9 : 0] a
	.spo(w_rom_rd_data)  // output wire [9 : 0] spo
);

endmodule
