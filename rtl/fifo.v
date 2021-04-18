`timescale 1ns / 1ps

module sync_fifo_docker
#(
	parameter DATA_WIDTH = 16,
	parameter BUF_SIZE = 784
)
(
	input clk,
	input rst_n,
	input clear,
	
	input [DATA_WIDTH-1:0]fifo_din,
	input fifo_wr_en,
	input fifo_rd_en,
	input fifo_rd_rewind,
	output fifo_empty,
	output fifo_full,
	output [DATA_WIDTH-1:0]fifo_out,
	
	output mem_rd_en_o,
	output [clogb2(BUF_SIZE)-1:0]mem_rd_addr_o,
	input  [DATA_WIDTH-1:0]mem_rd_data_i,
	output mem_wr_en_o,
	output [clogb2(BUF_SIZE)-1:0]mem_wr_addr_o,
	output [DATA_WIDTH-1:0]mem_wr_data_o
);
	function integer clogb2 (input integer bit_depth);
	begin
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			bit_depth = bit_depth >> 1;
	end
	endfunction
	
	localparam CNT_BIT_NUM = clogb2(BUF_SIZE);
	
	reg [CNT_BIT_NUM-1:0] fifo_rd_addr, fifo_wr_addr;
	reg [CNT_BIT_NUM-1:0] fifo_cnt;
	reg [CNT_BIT_NUM-1:0] buf_cnt;
	
	reg r_fifo_rd_en;
   	reg r_fifo_empty;
	
	assign fifo_empty = (fifo_cnt == 0); 
	assign fifo_full  = (fifo_cnt == BUF_SIZE);
	assign mem_wr_en_o = (fifo_wr_en && !fifo_full) ? 1 : 0;
	assign mem_wr_addr_o = fifo_wr_addr;
	assign mem_wr_data_o = fifo_din;
	assign mem_rd_en_o = (!fifo_empty && fifo_rd_en);
	assign mem_rd_addr_o = fifo_rd_addr;
	assign fifo_out = mem_rd_data_i;
	
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			r_fifo_empty <= 0;
		end
		else begin
			r_fifo_empty <= fifo_empty;
		end
	end
	
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			r_fifo_rd_en <= 0;
		end
		else begin
			r_fifo_rd_en <= fifo_rd_en;
		end
	end
	
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			fifo_cnt <= 0;
		end
		else if(clear) begin
			fifo_cnt <= 0;
		end
		else begin
			if(fifo_rd_rewind) begin
				fifo_cnt <= buf_cnt;
			end
			else if((!fifo_full && fifo_wr_en) && (!fifo_empty && fifo_rd_en)) begin
				fifo_cnt <= fifo_cnt;
			end
			else if(!fifo_empty && fifo_rd_en) begin
				fifo_cnt <= fifo_cnt - 1;
			end
			else if(!fifo_full && fifo_wr_en) begin
				fifo_cnt <= fifo_cnt + 1;
			end
		end
	end
		
	always @(posedge clk or negedge rst_n) begin 
		if(!rst_n) begin
			fifo_wr_addr <= 0;
		end
		else if(clear) begin
			fifo_wr_addr <= 0;
		end
		else if(!fifo_full && fifo_wr_en) begin
			if(fifo_wr_addr == BUF_SIZE - 1) begin
				fifo_wr_addr <= 0;
			end
			else begin
				fifo_wr_addr <= fifo_wr_addr + 1;
			end
		end
	end
		
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			fifo_rd_addr <= 0;
		end
		else if(clear) begin
			fifo_rd_addr <= 0;
		end
		else if(fifo_rd_rewind) begin
			fifo_rd_addr <= 0; 
		end
		else if(!fifo_empty && fifo_rd_en) begin
			if(fifo_rd_addr == BUF_SIZE - 1) begin
				fifo_rd_addr <= 0;
			end
			else begin
				fifo_rd_addr <= fifo_rd_addr + 1;
			end
		end
	end
				
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			buf_cnt <= 0;
		end
		else if(clear) begin
			buf_cnt <= 0;
		end
		else if(buf_cnt < BUF_SIZE - 1 && fifo_wr_en) begin   
			buf_cnt <= buf_cnt + 1;
		end
	end
	
endmodule

module sync_bram_fifo
#(
	parameter DATA_WIDTH = 16,
	parameter BUF_SIZE = 784
)
(
	input clk,
	input rst_n,
	input clear,
	
	input [DATA_WIDTH-1:0]fifo_din,
	input fifo_wr_en,
	input fifo_rd_en,
	input fifo_rd_rewind,
	output fifo_empty,
	output fifo_full,
	output [DATA_WIDTH-1:0]fifo_out
);
	function integer clogb2 (input integer bit_depth);
	begin
		for(clogb2=0; bit_depth>0; clogb2=clogb2+1)
			bit_depth = bit_depth >> 1;
	end
	endfunction
	
	wire w_bram_rd_en;
	wire [clogb2(BUF_SIZE)-1:0]w_bram_rd_addr;
	wire [DATA_WIDTH-1:0]w_bram_rd_data;
	wire w_bram_wr_en;
	wire [clogb2(BUF_SIZE)-1:0]w_bram_wr_addr;
	wire [DATA_WIDTH-1:0]w_bram_wr_data;
	
	sync_fifo_docker
	#(
		.DATA_WIDTH(DATA_WIDTH),
		.BUF_SIZE(BUF_SIZE)
	)
	u_sync_fifo_docker
	(
		.clk(clk),
		.rst_n(rst_n),
		.clear(clear),

		.fifo_din(fifo_din),
		.fifo_wr_en(fifo_wr_en),
		.fifo_rd_en(fifo_rd_en),
		.fifo_rd_rewind(fifo_rd_rewind),
		.fifo_empty(fifo_empty),
		.fifo_full(fifo_full),
		.fifo_out(fifo_out),

		.mem_rd_en_o(w_bram_rd_en),
		.mem_rd_addr_o(w_bram_rd_addr),
		.mem_rd_data_i(w_bram_rd_data),
		.mem_wr_en_o(w_bram_wr_en),
		.mem_wr_addr_o(w_bram_wr_addr),
		.mem_wr_data_o(w_bram_wr_data)
	);
	
	block_ram_simple_dual_port
   	#(
   		.DATA_WIDTH(DATA_WIDTH),
   		.DATA_DEPTH(BUF_SIZE)
   	)
   	u_block_ram
   	(
   		/*write port*/
   		.clka(clk),                          
		.ena(w_bram_wr_en),                           
		.addra(w_bram_wr_addr), 
		.dina(w_bram_wr_data),          

		/*read port*/						   
		.clkb(clk),                          
		.enb(w_bram_rd_en),                           
		.addrb(w_bram_rd_addr), 
		.doutb(w_bram_rd_data)          
   	);
	
endmodule

module bin2gray
#(
	parameter DATA_WIDTH = 16
)
(
	input  [DATA_WIDTH-1:0]bin,
	output [DATA_WIDTH-1:0]gray
);

assign gray = bin ^ (bin >> 1);

endmodule

module async_fifo_docker
#(
	parameter DATA_WIDTH = 16,
	parameter ADDR_WIDTH = 8
)
(
	input rst_n,
	input wr_clk,
	input rd_clk,
	
	input [DATA_WIDTH-1:0]fifo_din,
	input fifo_wr_en,
	input fifo_rd_en,
	output fifo_empty,
	output fifo_full,
	output [DATA_WIDTH-1:0]fifo_out,
	
	output mem_rd_en_o,
	output [ADDR_WIDTH-1:0]mem_rd_addr_o,
	input  [DATA_WIDTH-1:0]mem_rd_data_i,
	output mem_wr_en_o,
	output [ADDR_WIDTH-1:0]mem_wr_addr_o,
	output [DATA_WIDTH-1:0]mem_wr_data_o
);
function integer clogb2 (input integer bit_depth);

for(clogb2=0; bit_depth>0; clogb2=clogb2+1) begin
	bit_depth = bit_depth >> 1;
end

endfunction
	
/* 1 extra bit for wrap detect*/
reg [ADDR_WIDTH:0]rd_ptr_bin;
reg [ADDR_WIDTH:0]wr_ptr_bin;

wire [ADDR_WIDTH:0]rd_ptr_gray;
wire [ADDR_WIDTH:0]wr_ptr_gray;
reg  [ADDR_WIDTH:0]r_rd_ptr_gray[1:0];
reg  [ADDR_WIDTH:0]r_wr_ptr_gray[1:0];
wire [ADDR_WIDTH:0]rd_ptr_gray_2dff;
wire [ADDR_WIDTH:0]wr_ptr_gray_2dff;

/********************************read side******************************************/
always @(posedge rd_clk or negedge rst_n) begin
	if(!rst_n) begin
		rd_ptr_bin <= {ADDR_WIDTH{1'b0}};
	end
	else if(fifo_rd_en && !fifo_empty) begin
		rd_ptr_bin <= rd_ptr_bin + 1'b1;
	end
end

/* use gray code to avoid multi-bits metastable status*/
bin2gray #((ADDR_WIDTH + 1)) u_rd_ptr_bin2gray(rd_ptr_bin, rd_ptr_gray);

always @(posedge rd_clk or negedge rst_n) begin
	if(!rst_n) begin
		r_rd_ptr_gray[0] <= {ADDR_WIDTH{1'b0}};
		r_rd_ptr_gray[1] <= {ADDR_WIDTH{1'b0}};
	end
	else begin
		r_rd_ptr_gray[0] <= rd_ptr_gray;
		r_rd_ptr_gray[1] <= r_rd_ptr_gray[0];
	end
end

/* synchronize rd_ptr to write side with 2 regs*/
assign rd_ptr_gray_2dff = r_rd_ptr_gray[1];

/********************************write side******************************************/
always @(posedge wr_clk or negedge rst_n) begin
	if(!rst_n) begin
		wr_ptr_bin <= {ADDR_WIDTH{1'b0}};
	end
	else if(fifo_wr_en && !fifo_full) begin
		wr_ptr_bin <= wr_ptr_bin + 1'b1;
	end
end

bin2gray #((ADDR_WIDTH + 1)) u_wr_ptr_bin2gray(wr_ptr_bin, wr_ptr_gray);

always @(posedge wr_clk or negedge rst_n) begin
	if(!rst_n) begin
		r_wr_ptr_gray[0] <= {ADDR_WIDTH{1'b0}};
		r_wr_ptr_gray[1] <= {ADDR_WIDTH{1'b0}};
	end
	else begin
		r_wr_ptr_gray[0] <= wr_ptr_gray;
		r_wr_ptr_gray[1] <= r_wr_ptr_gray[0];
	end
end

/* synchronize wr_ptr to read side with 2 regs*/
assign wr_ptr_gray_2dff = r_wr_ptr_gray[1];

/********************************fifo status and bram control interface******************************************/
assign fifo_empty = (rd_ptr_gray == wr_ptr_gray_2dff) ? 1 : 0;
assign fifo_full =  (wr_ptr_gray == {~rd_ptr_gray_2dff[ADDR_WIDTH:ADDR_WIDTH-1], rd_ptr_gray_2dff[ADDR_WIDTH-2:0]}) ? 1 : 0;

reg r_fifo_empty;
reg r_fifo_full;

assign mem_wr_en_o = (!fifo_full) ? fifo_wr_en : 1'b0;
assign mem_rd_en_o = (!fifo_empty) ? fifo_rd_en : 1'b0;

assign mem_rd_addr_o = rd_ptr_bin[ADDR_WIDTH-1:0];
assign mem_wr_addr_o = wr_ptr_bin[ADDR_WIDTH-1:0];

assign fifo_out = (!fifo_empty) ? mem_rd_data_i : {DATA_WIDTH{1'b0}};
assign mem_wr_data_o = (!fifo_full) ? fifo_din : {DATA_WIDTH{1'b0}};

endmodule

module async_fifo
#(
	parameter DATA_WIDTH = 16,
	parameter ADDR_WIDTH = 8
)
(
	input rst_n,
	input wr_clk,
	input rd_clk,
	
	input [DATA_WIDTH-1:0]fifo_din,
	input fifo_wr_en,
	input fifo_rd_en,
	output fifo_empty,
	output fifo_full,
	output [DATA_WIDTH-1:0]fifo_out
);

wire bram_wr_en;
wire [ADDR_WIDTH-1:0]bram_wr_addr;
wire [DATA_WIDTH-1:0]bram_wr_data;
wire bram_rd_en;
wire [ADDR_WIDTH-1:0]bram_rd_addr;
wire [DATA_WIDTH-1:0]bram_rd_data;

async_fifo_docker
#(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH)
)
u_async_fifo_docker
(
	
	.rst_n(rst_n),
	.wr_clk(wr_clk),
	.rd_clk(rd_clk),
	
	.fifo_din(fifo_din),
	.fifo_wr_en(fifo_wr_en),
	.fifo_rd_en(fifo_rd_en),
	.fifo_empty(fifo_empty),
	.fifo_full(fifo_full),
	.fifo_out(fifo_out),
	
	.mem_rd_en_o(bram_rd_en),
	.mem_rd_addr_o(bram_rd_addr),
	.mem_rd_data_i(bram_rd_data),
	.mem_wr_en_o(bram_wr_en),
	.mem_wr_addr_o(bram_wr_addr),
	.mem_wr_data_o(bram_wr_data)
);

localparam DATA_DEPTH = (32'b1 << ADDR_WIDTH) - 1;

block_ram_simple_dual_port
#(
	.DATA_WIDTH(DATA_WIDTH),
	.DATA_DEPTH(DATA_DEPTH)
)
u_block_ram
(
	/*write port*/
	.clka(wr_clk),                          
	.ena(bram_wr_en),                           
	.addra(bram_wr_addr), 
	.dina(bram_wr_data),          

	/*read port*/						   
	.clkb(rd_clk),                          
	.enb(bram_rd_en),                           
	.addrb(bram_rd_addr), 
	.doutb(bram_rd_data)          
);

endmodule



