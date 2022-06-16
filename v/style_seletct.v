module style_select (
    input           clk,
    input           irst_n,
    input           buttom,
    output [1:0]    style_mode
);

reg style_mode_r, style_mode_nxt;

assign style_mode = style_mode_r;

always@(*) begin
    if(buttom) style_mode_nxt = style_mode_r + 1;
end

always@(posedge clk or negedge irst_n) begin
	if(!irst_n) style_mode_r <= 0;
	else begin
		style_mode_r <= style_mode_nxt;
	end
end

endmodule
