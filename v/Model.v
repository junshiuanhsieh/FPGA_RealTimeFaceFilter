module Model(	
        input           iclk,
        input   [11:0]  iGreyscale,
        input   iX_Cont,
        input   iY_Cont,
        output  [11:0]  oRed,
        output  [11:0]  oGreen,
        output  [11:0]  oBlue,
        output  oFilterVal
);

assign oRed = i_data;

always@(posedge iclk) begin

end
endmodule