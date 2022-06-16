module Filter_tran(
	input		[1:0]		num,
	input		[1:0]		style,
	input 	[6:0]		pos_x1,
	input		[6:0]		pos_y1,
	input		[6:0]		eyerow11,
	input		[6:0]		eyecol11,
	input		[6:0]		eyerow12,
	input		[6:0]		eyecol12,
	input 	[6:0]		pos_x2,
	input		[6:0]		pos_y2,
	input		[6:0]		eyerow21,
	input		[6:0]		eyecol21,
	input		[6:0]		eyerow22,
	input		[6:0]		eyecol22,
	input		[9:0]		width,
	input		[9:0]		height,
	input		[9:0]		now_x,
	input		[9:0]		now_y,
	output	[19:0]	rom_addr0,
	output	[19:0]	rom_addr1,
	input		[11:0]	rom_data0,
	input		[11:0]	rom_data1,
	input		[9:0]	   rom_data2,
	output	[9:0]		pro_data_r,
	output	[9:0]		pro_data_g,
	output	[9:0]		pro_data_b,
	output	[2:0]		pro_data_trans,
	output				slt
);

wire  ft1, ft0, eyeft0, eyeft1, eyeft2, eyeft3, sunft0, sunft1;
wire	bg1, bg0, bg2;
wire	display1, display0;
wire	display_eye0, display_eye1, display_eye2, display_eye3, display_eye;
wire [10:0] real_x1, real_y1, real_x2, real_y2, real_x3, real_y3, real_x4, real_y4;
wire signed [10:0] bias_pos_x1, bias_pos_y1, bias_pos_x2, bias_pos_y2, bias_pos_x3, bias_pos_y3, bias_pos_x4, bias_pos_y4;
wire [10:0] eye_pos_x1, eye_pos_y1, eye_pos_x2, eye_pos_y2, eye_pos_x3, eye_pos_y3, eye_pos_x4, eye_pos_y4;

assign bias_pos_x1 = (style == 2'd3) ? pos_x1 * 8		 : (style == 2'd0) ? pos_x1 * 8 - 50	: pos_x1 * 8 - 30;
assign bias_pos_y1 = (style == 2'd3) ? pos_y1 * 8 + 30 : (style == 2'd0) ? pos_y1 * 8 - 130	: pos_y1 * 8 + 40;
assign bias_pos_x2 = (style == 2'd3) ? pos_x2 * 8		 : (style == 2'd0) ? pos_x2 * 8 - 50	: pos_x2 * 8 - 30;
assign bias_pos_y2 = (style == 2'd3) ? pos_y2 * 8 + 30 : (style == 2'd0) ? pos_y2 * 8 - 130	: pos_y2 * 8 + 40;

assign eye_pos_x1 = eyecol11 * 8 - 40;
assign eye_pos_y1 = eyerow11 * 8 - 40;
assign eye_pos_x2 = eyecol12 * 8 - 40;
assign eye_pos_y2 = eyerow12 * 8 - 40;
assign eye_pos_x3 = eyecol21 * 8 - 40;
assign eye_pos_y3 = eyerow21 * 8 - 40;
assign eye_pos_x4 = eyecol22 * 8 - 40;
assign eye_pos_y4 = eyerow22 * 8 - 40;

assign bg0 = (style == 2'd3) ? 1'b0 : rom_data0[9];
assign bg1 = (style == 2'd3) ? 1'b0 : rom_data1[9];
assign bg2 = rom_data2[9];
 
assign ft0 = (now_x >= bias_pos_x1) && (now_x < bias_pos_x1 + width) && (now_y >= bias_pos_y1) && (now_y < bias_pos_y1 + height);
assign ft1 = (now_x >= bias_pos_x2) && (now_x < bias_pos_x2 + width) && (now_y >= bias_pos_y2) && (now_y < bias_pos_y2 + height);

assign eyeft0 = (now_x >= eye_pos_x1) && (now_x < eye_pos_x1 + width) && (now_y >= eye_pos_y1) && (now_y < eye_pos_y1 + height);
assign eyeft1 = (now_x >= eye_pos_x2) && (now_x < eye_pos_x2 + width) && (now_y >= eye_pos_y2) && (now_y < eye_pos_y2 + height);
assign eyeft2 = (now_x >= eye_pos_x3) && (now_x < eye_pos_x3 + width) && (now_y >= eye_pos_y3) && (now_y < eye_pos_y3 + height);
assign eyeft3 = (now_x >= eye_pos_x4) && (now_x < eye_pos_x4 + width) && (now_y >= eye_pos_y4) && (now_y < eye_pos_y4 + height);

assign display0 = (style < 2'd2 || style == 2'd3) && (num > 0) && (!bg0) && ft0;
assign display1 = (style < 2'd2 || style == 2'd3) && (num > 1) && (!bg1) && ft1;

assign display_eye0 = (style == 2'd2) && !(eyecol11==0 && eyerow11==0) && (!bg2) && (num > 0) && eyeft0;
assign display_eye1 = (style == 2'd2) && !(eyecol12==0 && eyerow12==0) && (!bg2) && (num > 0) && eyeft1;
assign display_eye2 = (style == 2'd2) && !(eyecol21==0 && eyerow21==0) && (!bg2) && (num > 1) && eyeft2;
assign display_eye3 = (style == 2'd2) && !(eyecol22==0 && eyerow22==0) && (!bg2) && (num > 1) && eyeft3;
assign display_eye  = display_eye0 || display_eye1 || display_eye2 || display_eye3;

assign slt = !display0 && !display1 && !display_eye ;


assign real_x1 = (now_x+6 - bias_pos_x1) % width;
assign real_y1 = (now_y - bias_pos_y1) % height;
assign real_x2 = (now_x+6 - bias_pos_x2) % width;
assign real_y2 = (now_y - bias_pos_y2) % height;

assign real_x3 = (eyeft0) ? (now_x+6 - eye_pos_x1) % width : 
					  (eyeft1) ? (now_x+6 - eye_pos_x2) % width : 
					  (eyeft2) ? (now_x+6 - eye_pos_x3) % width : 
					  (eyeft3) ? (now_x+6 - eye_pos_x4) % width : 0;
assign real_y3 = (eyeft0) ? (now_y - eye_pos_y1) % height : 
					  (eyeft1) ? (now_y - eye_pos_y2) % height : 
					  (eyeft2) ? (now_y - eye_pos_y3) % height : 
					  (eyeft3) ? (now_y - eye_pos_y4) % height : 0;


assign rom_addr0 = (style == 2'd2) ? (real_x3 + width*real_y3) % (width*height) : (real_x1 + width*real_y1) % (width*height);
assign rom_addr1 = (real_x2 + width*real_y2) % (width*height);

assign pro_data_r = display0 ? {rom_data0[2:0], 7'b0} : display1 ? {rom_data1[2:0], 7'b0} : display_eye ? {rom_data2[8:6], 7'b0} : 10'd0;
assign pro_data_g = display0 ? {rom_data0[5:3], 7'b0} : display1 ? {rom_data1[5:3], 7'b0} : display_eye ? {rom_data2[5:3], 7'b0} : 10'd0;
assign pro_data_b = display0 ? {rom_data0[8:6], 7'b0} : display1 ? {rom_data1[8:6], 7'b0} : display_eye ? {rom_data2[2:0], 7'b0} : 10'd0;
assign pro_data_trans = (style == 2'd3) ? (display0 ? rom_data0[11:9] : display1 ? rom_data1[11:9] : 3'd0) : 3'd7;

endmodule