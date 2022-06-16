module Signal_comb(
	input iclk,
	input irst_n,
	input [9:0]iRed_1,
	input [9:0]iGreen_1,
	input [9:0]iBlue_1,
	input [9:0]iRed_2,
	input [9:0]iGreen_2,
	input [9:0]iBlue_2,
	input	[2:0]iTrans,
	input slt,
	output [9:0]now_x,
	output [9:0]now_y,
	output [9:0]oRed,
	output [9:0]oGreen,
	output [9:0]oBlue
);

`include "VGA_Param.h"
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

reg		[12:0]		H_Cont;
reg		[12:0]		V_Cont;
wire		[12:0]		v_mask;
wire		[9:0] 		red, green, blue;
assign v_mask = 13'd0 ;//iZOOM_MODE_SW ? 13'd0 : 13'd26;

assign	now_x =  H_Cont - X_START;
assign	now_y =  V_Cont - Y_START;
assign	oRed	=	(H_Cont>=X_START && H_Cont<X_START+H_SYNC_ACT && V_Cont>=Y_START+v_mask && V_Cont<Y_START+V_SYNC_ACT) ?	red : 0;
assign	oGreen=	(H_Cont>=X_START && H_Cont<X_START+H_SYNC_ACT && V_Cont>=Y_START+v_mask && V_Cont<Y_START+V_SYNC_ACT) ?	green :	0;
assign	oBlue	=	(H_Cont>=X_START && H_Cont<X_START+H_SYNC_ACT && V_Cont>=Y_START+v_mask && V_Cont<Y_START+V_SYNC_ACT ) ?	blue	: 0;
assign	red = 	slt ? iRed_1	: (iRed_2  /7	* iTrans + iRed_1	 /7	* (7-iTrans));
assign 	green =	slt ? iGreen_1 : (iGreen_2/7	* iTrans + iGreen_1/7	* (7-iTrans));
assign 	blue =	slt ? iBlue_1	: (iBlue_2 /7	* iTrans + iBlue_1 /7	* (7-iTrans));

always@(posedge iclk or negedge irst_n) begin
	if(!irst_n) H_Cont <= 0;
	else begin
		if(H_Cont < H_SYNC_TOTAL) H_Cont <= H_Cont+1;
		else H_Cont	<=	0;
	end
end

always@(posedge iclk or negedge irst_n) begin
	if(!irst_n) V_Cont <= 0;
	else begin
		if(H_Cont==0) begin
			if(V_Cont < V_SYNC_TOTAL) V_Cont	<=	V_Cont+1;
			else V_Cont	<=	0;
		end
	end
end

endmodule