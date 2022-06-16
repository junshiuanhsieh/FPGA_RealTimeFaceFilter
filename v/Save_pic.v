module Save_pic(
	input					clk,
	input					rst_n,
	input    [9:0]		data_r,
	input    [9:0]		data_g,
	input    [9:0]		data_b,
	input					model_finish,
   input    [15:0]	i_data,
	output				sram_wren,
	output	[15:0]	sram_addr,
	output	[15:0]	sram_data,
	output				model_start,
	output	[3:0]		state,
   input    [9:0]		now_x,
   input    [9:0]		now_y
);
parameter	H_SYNC_CYC	=	96;
parameter	H_SYNC_BACK	=	48;
parameter	H_SYNC_ACT	=	640;	
parameter	H_SYNC_FRONT=	16;
parameter	H_SYNC_TOTAL=	800;
parameter	V_SYNC_CYC	=	2;
parameter	V_SYNC_BACK	=	33;
parameter	V_SYNC_ACT	=	480;	
parameter	V_SYNC_FRONT=	10;
parameter	V_SYNC_TOTAL=	525; 
parameter	X_START		=	H_SYNC_CYC+H_SYNC_BACK;
parameter	Y_START		=	V_SYNC_CYC+V_SYNC_BACK;

//wire	[9:0]	 now_x, now_y;
reg	[3:0]	 state_r, state_w;
reg	[29:0] last_rgb_r, last_rgb_w, now_rgb_r, now_rgb_w;
reg	[15:0] last_gs_r, last_gs_w, now_gs_r, now_gs_w;
reg	[15:0] last_sk_r, last_sk_w, now_sk_r, now_sk_w;
reg	[15:0] last_hr_r, last_hr_w, now_hr_r, now_hr_w;
reg			 wren_r, wren_w;
reg	[15:0] addr_r, addr_w;
reg	[15:0] wdata_r, wdata_w;
reg			 model_start_w, model_start_r;

reg	[15:0] save_gs, save_hr, save_sk;
reg	[15:0] save_gs_r, save_gs_w;
reg	[15:0] save_hr_r, save_hr_w;
reg	[15:0] save_sk_r, save_sk_w;

//reg		[12:0]		H_Cont;
//reg		[12:0]		V_Cont;

wire	[9:0]	 block_x, block_y;
wire  [15:0] input_data;
wire  [9:0]	 counter;
wire	[15:0] cal;
wire	[29:0] combine;
wire	[15:0] avgrgb;

assign	cal = block_y * 15'd81 + block_x - 15'd1;
assign	block_x = now_x / 10'd8;
assign	block_y = now_y / 10'd8;
assign	sram_wren = (now_x >= 0 && now_x < 650 && now_y >= 0 && now_y < 481) ? wren_r: 1'b0;
assign	sram_addr = addr_r % 16'd20000;
assign	sram_data = wdata_r;
assign	counter = now_x - block_x * 10'd8;
assign   model_start = model_start_r;
assign 	state	= state_r;
assign	input_data = i_data;
assign	combine = {3'b0, data_r[9:3], 3'b0, data_g[9:3], 3'b0, data_b[9:3]};
assign	avgrgb = (data_r[9:3] + data_g[9:3] + data_b[9:3]) / 16'd3;



always@(*) begin 
	last_rgb_w = last_rgb_r;
	if(counter == 7) last_rgb_w = now_rgb_r + combine;
	
	now_rgb_w = now_rgb_r;
	if(counter == 0) now_rgb_w = combine;
	else now_rgb_w = now_rgb_r + combine;
end	
always@(*) begin 
	last_gs_w = last_gs_r;
	if(counter == 7) last_gs_w = now_gs_r + avgrgb;
	
	now_gs_w = now_gs_r;
	if(counter == 0 && block_x == 0) now_gs_w = avgrgb;
	else now_gs_w = now_gs_r + avgrgb;
end	
always@(*) begin 
	last_sk_w = last_sk_r;
	if(counter == 1) begin
		if(now_y % 8 == 0 && block_x == 0) last_sk_w = 0;
		else begin
			
			if  ((now_x >= 8) &&(now_x < 648) && (last_rgb_r[29:20] >	10'd384)
				&&(last_rgb_r[19:10] >	10'd160)
				&&(last_rgb_r[9:0]   >	10'd80)
				&&(last_rgb_r[29:20] >	last_rgb_r[19:10] + 10'd60)
				&&(last_rgb_r[19:10] <= 10'h3FF - 10'd60)
				&&(last_rgb_r[29:20] >	last_rgb_r[9:0])) begin 
				last_sk_w = last_sk_r + 16'd1;
			end
			
		end
	end
end

always@(*) begin 
	last_hr_w = last_hr_r;
	if(counter == 1) begin
		if(now_y % 8 == 0 && block_x == 0) last_hr_w = 16'd0;
		else begin
			if((now_x >= 8) &&(now_x < 648) && (last_rgb_r[9:0] + last_rgb_r[19:10] + last_rgb_r[29:20]) < 16'd720) begin
				last_hr_w = last_hr_r + 16'd1;
			end
		end
	end
end


always@(*) begin
	state_w = state_r;
	model_start_w = 1'b0;
	wren_w = 1'b0; 
	addr_w = addr_r;
	wdata_w = wdata_r;
	save_gs_w = save_gs_r;
	save_sk_w = save_sk_r;
	save_hr_w = save_hr_r;
	case(state_r)
			4'd0: begin
				wren_w = 1;
				addr_w = now_y * 640 + now_x;
				wdata_w = 0;
				if(now_y == 474) state_w = 1'd1;
			end

			4'd1: begin
				//addr_w = 15'd5082 + (block_y-15'd1) * 15'd81 + block_x - 15'd1;
				
				if(now_y == 473) begin
					state_w = 4'd2;
					model_start_w = 1'b1;
				end
				if((now_x >= 8) && (now_x < 648) && (now_y < 480) && now_y % 8 == 0 && block_x != 0) begin
					  case(counter)
							10'd0: begin
								addr_w = 15'd5001 + cal;
							end
							10'd1: begin
								addr_w = 15'd10001 + cal;
							end
							10'd2: begin
								addr_w = 15'd15001 + cal;
							end
							10'd3: begin
								save_gs_w = input_data;
							end
							10'd4: begin
								save_sk_w = input_data;
							end
							10'd5: begin
								save_hr_w = input_data;
								
								wren_w = 1'b1;
								addr_w = 15'd5082 + cal;
								wdata_w = (block_y == 10'd0) ? (last_gs_r / 32 - 16 * block_x) : (last_gs_r / 32 - 16 * block_x + save_gs_r);
							end
							10'd6: begin
								wren_w = 1'b1;
								addr_w = 15'd10082 + cal;
								wdata_w = (block_y == 10'b0) ? last_sk_r : last_sk_r + save_sk_r;
							end
							10'd7: begin
								wren_w = 1'b1;
								addr_w = 15'd15082 + block_y * 15'd81 + block_x - 15'd1;
								wdata_w = (block_y == 10'b0) ? last_hr_r : last_hr_r + save_hr_r;
							end
								
					  endcase
				end
			end
			4'd2: begin
				if(model_finish) state_w = 4'd3;
			end
			4'd3: begin
				if(now_y == 474) state_w = 4'd1;
			end
			4'd4: begin
			end
    endcase
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		state_r			<= 0;
		last_rgb_r		<= 0;
		last_gs_r		<= 0;
		last_sk_r		<= 0;
		last_hr_r		<= 0;
		now_rgb_r		<= 0;
		now_gs_r			<= 0;
		now_sk_r			<= 0;
		now_hr_r			<= 0;
		model_start_r	<= 0;
		wren_r			<= 0;
		addr_r			<= 0;
		wdata_r			<= 0;
		save_gs_r		<= 0;
		save_hr_r		<= 0;
		save_sk_r		<= 0;
	end
	else begin
		state_r			<= state_w;
		last_rgb_r		<= last_rgb_w;
		last_gs_r		<= last_gs_w;
		last_sk_r		<= last_sk_w;
		last_hr_r		<= last_hr_w;
		now_rgb_r		<= now_rgb_w;
		now_gs_r			<= now_gs_w;
		now_sk_r			<= now_sk_w;
		now_hr_r			<= now_hr_w;
		model_start_r	<= model_start_w;
		wren_r			<= wren_w;
		addr_r			<= addr_w;
		wdata_r			<= wdata_w;
		save_gs_r		<= save_gs_w;
		save_hr_r		<= save_hr_w;
		save_sk_r		<= save_sk_w;
		
	end
end

endmodule

