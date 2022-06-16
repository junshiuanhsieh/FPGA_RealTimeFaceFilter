module viola_jones#(
	parameter width= 80,
	parameter height = 60,
	parameter window_size = 30	
)(
	input					clk,
	input					rst,
	input					start,
	output	[6:0]		col1,
	output	[6:0]		row1,
   output   [6:0]    eyerow11,
   output   [6:0]    eyerow12,
   output   [6:0]    eyecol11,
   output   [6:0]    eyecol12,
	output	[6:0]		col2,
	output	[6:0]		row2,
   output   [6:0]    eyerow21,
   output   [6:0]    eyerow22,
   output   [6:0]    eyecol21,
   output   [6:0]    eyecol22,
	output	[6:0]		col3,
	output	[6:0]		row3,
   output   [6:0]    eyerow31,
   output   [6:0]    eyerow32,
   output   [6:0]    eyecol31,
   output   [6:0]    eyecol32,
	output	[1:0]		num,
	output	[19:0]	addr,
	input		[15:0]	data,
	output				we_n,
	output				finish,
	output	[3:0]		o_state,
	output	[6:0]		o_col,
	output	[6:0]		o_row,
	output	[15:0]	o_skin_counter,
	output	[15:0]	o_hair_counter,
	output	[15:0]	o_frame
	);

    /************ MODEL ******************
    feature  = LiMj[39:37]
    polarity = LiMj[36]
    x        = LiMj[35:31]
    y        = LiMj[30:26]
    width    = LiMj[25:21]
    height   = LiMj[20:16]
    threshold= LiMj[15:0]
    **************************************/
    parameter L2NUM = 5'd5;
    parameter L3NUM = 5'd19;
	 
    parameter SKIN_THRESHOLD = 450;
    parameter HAIR_THRESHOLD = 60;
    parameter EYE_THRESHOLD  = 24;
	 parameter L2_THRESHOLD   = 5'd3; // L2NUM/2 + 1
    parameter L3_THRESHOLD   = 5'd8; // (L3NUM-L2NUM)/2 + 1
	 
    // feature
    parameter F2V   = 3'd0;
    parameter F2H   = 3'd1;
    parameter F3V   = 3'd2;
    parameter F3H   = 3'd3;
    parameter F4    = 3'd4;
    // state
    parameter IDLE  = 4'd0;
    parameter INIT  = 4'd1;
    parameter SKIN  = 4'd2;
    parameter HAIR  = 4'd3;
    parameter CAL   = 4'd4;
    parameter COMP  = 4'd5;
    parameter EYE_I = 4'd6;
    parameter EYE   = 4'd7;
    parameter EYE_C = 4'd8;
    // memory
    parameter GRAY_I = 20'd5000;
    parameter SKIN_I = 20'd10000;
    parameter HAIR_I = 20'd15000;


    reg         [3:0]  state_r, state_w;
    reg         [19:0] addr_r, addr_w;
    wire signed [15:0] data_r;
    reg         [6:0]  col_counter_r, col_counter_w;
    reg         [6:0]  row_counter_r, row_counter_w;
    reg         [4:0]  box_counter_r, box_counter_w;
    reg         [4:0]  f_counter_r, f_counter_w;
    reg         [1:0]  l_counter_r, l_counter_w;
    reg  signed [15:0] sum_r, sum_w;
    reg         [39:0] classifier [0:L3NUM-1];
    reg         [4:0]  csum_r, csum_w;
    reg                finish_r, finish_w;
    reg         [4:0]  prob_w[0:3], prob_r[0:3];
    reg         [6:0]  col_w[0:3], col_r[0:3], row_w[0:3], row_r[0:3];
    reg         [6:0]  eyerow_w[0:2][0:1], eyerow_r[0:2][0:1];
    reg         [6:0]  eyecol_w[0:2][0:1], eyecol_r[0:2][0:1];
    reg         [6:0]  oeyerow_w[0:2][0:1], oeyerow_r[0:2][0:1];
    reg         [6:0]  oeyecol_w[0:2][0:1], oeyecol_r[0:2][0:1];
    reg         [4:0]  eye_prob_w[0:1], eye_prob_r[0:1];
    reg         [4:0]  save_prob_r, save_prob_w;
    reg         [1:0]  num_r, num_w;
	 reg			 [15:0] frame_counter_r, frame_counter_w;
	 reg			 [15:0] skin_counter_r, skin_counter_w;
	 reg			 [15:0] hair_counter_r, hair_counter_w;
	 reg			 [1:0]  o_num_r, o_num_w;
    reg         [6:0]  o_col_w[0:3], o_col_r[0:3], o_row_w[0:3], o_row_r[0:3];
	 //reg			 [15:0] now, next;

    wire        [2:0]  feature;
    wire               polarity;
    wire        [4:0]  f_x, f_y, f_width, f_height;
    wire signed [15:0] threshold;
    wire        [4:0]  lnum [0:1];
    wire        [4:0]  lthreshold [0:1];
    
	 //assign addr 			= now;
	 assign data_r			= data;
    assign we_n         = 1'b0;
    assign addr         = addr_w;
    assign lnum[0]      = L2NUM;
    assign lnum[1]      = L3NUM;
    assign lthreshold[0]= L2_THRESHOLD;
    assign lthreshold[1]= L3_THRESHOLD;
    assign finish       = finish_r;
    assign num          = o_num_r;
    assign feature      = classifier[f_counter_r][39:37];
    assign polarity     = classifier[f_counter_r][36];
    assign f_x          = classifier[f_counter_r][35:31];
    assign f_y          = classifier[f_counter_r][30:26];
    assign f_width      = classifier[f_counter_r][25:21];
    assign f_height     = classifier[f_counter_r][20:16];
    assign threshold    = classifier[f_counter_r][15:0];
    assign col1         = o_col_r[0];
    assign row1         = o_row_r[0];
    assign eyerow11     = oeyerow_r[0][0] + 7'd2;
    assign eyerow12     = oeyerow_r[0][1] + 7'd2;
    assign eyecol11     = oeyecol_r[0][0] + 7'd3;
    assign eyecol12     = oeyecol_r[0][1] + 7'd3;
    assign col2         = o_col_r[1];
    assign row2         = o_row_r[1];
    assign eyerow21     = oeyerow_r[1][0] + 7'd2;
    assign eyerow22     = oeyerow_r[1][1] + 7'd2;
    assign eyecol21     = oeyecol_r[1][0] + 7'd3;
    assign eyecol22     = oeyecol_r[1][1] + 7'd3;
    assign col3         = o_col_r[2];
    assign row3         = o_row_r[2];
    assign eyerow31     = oeyerow_r[2][0] + 7'd2;
    assign eyerow32     = oeyerow_r[2][1] + 7'd2;
    assign eyecol31     = oeyecol_r[2][0] + 7'd3;
    assign eyecol32     = oeyecol_r[2][1] + 7'd3;
	 
	 assign o_state		= state_r;
	 assign o_col			= col_counter_r;
	 assign o_row			= row_counter_r;
	 assign o_frame		= frame_counter_r;
	 assign o_skin_counter= skin_counter_r;
	 assign o_hair_counter= hair_counter_r;
    
    initial begin
        $readmemh("../model/model.txt", classifier);
    end

    integer i, neighbor;


	 
    always @(*) begin
        addr_w          = addr_r;
        col_counter_w   = col_counter_r;
        row_counter_w   = row_counter_r;
        box_counter_w   = box_counter_r;
        f_counter_w     = f_counter_r;
        l_counter_w     = l_counter_r;
        state_w         = state_r;
        sum_w           = sum_r;
        csum_w          = csum_r;
        num_w           = num_r;
        o_num_w         = o_num_r;
        finish_w        = finish_r;
        save_prob_w     = save_prob_r;
		  frame_counter_w = frame_counter_r;
		  skin_counter_w  = skin_counter_r;
		  hair_counter_w  = hair_counter_r;
        eye_prob_w[0]   = eye_prob_r[0];
        eye_prob_w[1]   = eye_prob_r[1];
        for(i = 0; i < 3; i = i + 1) begin
            col_w[i]        = col_r[i];
            row_w[i]        = row_r[i];
            o_col_w[i]      = o_col_r[i];
            o_row_w[i]      = o_row_r[i];
            prob_w[i]       = prob_r[i];
            eyecol_w[i][0]  = eyecol_r[i][0];
            eyecol_w[i][1]  = eyecol_r[i][1];
            eyerow_w[i][0]  = eyerow_r[i][0];
            eyerow_w[i][1]  = eyerow_r[i][1];
            oeyecol_w[i][0]  = oeyecol_r[i][0];
            oeyecol_w[i][1]  = oeyecol_r[i][1];
            oeyerow_w[i][0]  = oeyerow_r[i][0];
            oeyerow_w[i][1]  = oeyerow_r[i][1];
        end

        case(state_r)
            IDLE: begin
                finish_w = 1'b0;
                if(start) begin
                    state_w = SKIN;
                    addr_w  = SKIN_I;
						  num_w = 2'b0;
						  frame_counter_w = frame_counter_r + 16'b1;
						  skin_counter_w = 16'b0;
						  hair_counter_w = 16'b0;
						  row_counter_w = 7'd0;
                end
                else addr_w = 20'b0;
            end
            INIT: begin
                col_counter_w = col_counter_r + 7'b1;
                state_w = SKIN;
                sum_w = 16'b0;
                addr_w = SKIN_I + row_counter_w * (width+1) + col_counter_w;
					 
                if(col_counter_r == width-window_size) begin
                    row_counter_w = row_counter_r + 7'b1;
                    col_counter_w = 7'b0;
                    addr_w = SKIN_I + row_counter_w * (width+1) + col_counter_w;
						  
                    if(row_counter_r == height-window_size) begin
                        o_num_w = num_r;
								for(i = 0; i < 3; i = i + 1) begin
									o_col_w[i] = col_r[i];
									o_row_w[i] = row_r[i];
								end
								/*
                        finish_w = 1'b1;
								state_w = IDLE;
								row_counter_w = 7'd0;
								*/
								
								for(i = 0; i < 3; i = i + 1) begin
									eyecol_w[i][0]  = 0;
									eyecol_w[i][1]  = 0;
									eyerow_w[i][0]  = 0;
									eyerow_w[i][1]  = 0;
								end
								
								if(num_r > 0) begin
									state_w = EYE;
									num_w = 2'b0;
									row_counter_w = row_r[0] + 3;
									col_counter_w = col_r[0];
									addr_w = HAIR_I + (row_counter_w) * (width+1) + col_r[0];
									
								end
								else begin
									finish_w = 1'b1;
									state_w = IDLE;
									row_counter_w = 0;
								end
								
                    end
                end
            end
            SKIN: begin
                box_counter_w = box_counter_r + 5'b1;
                if(box_counter_r == 5'b0) begin
                    addr_w = addr_r + window_size;
                end
                else if(box_counter_r == 5'b1) begin
                    addr_w = addr_r + width * window_size;
                    sum_w = sum_r + data_r;
                end
                else if(box_counter_r == 5'd2) begin
                    addr_w = addr_r + window_size;
                    sum_w = sum_r - data_r;
                end
                else if(box_counter_r == 5'd3) begin
                    sum_w = sum_r - data_r;
						  //frame_counter_w = addr_r;
                end
                else if(box_counter_r == 5'd4) begin
                    sum_w = sum_r + data_r;
						  //skin_counter_w = data_r;
						  //state_w = PAUSE;
                    if(sum_w < SKIN_THRESHOLD) begin
                        box_counter_w = 5'b0;
                        state_w = INIT;
                        //state_w = PAUSE;
                    end
                    else begin
                        state_w = HAIR;
                        box_counter_w = 5'b0;
                        sum_w = 16'b0;
                        addr_w = HAIR_I + row_counter_w * (width+1) + col_counter_w;
								skin_counter_w = skin_counter_r + 10'b1;
                    end
                end
            end
            HAIR: begin
                box_counter_w = box_counter_r + 1;
                if(box_counter_r == 5'b0) begin
                    addr_w = addr_r + window_size;
                end
                else if(box_counter_r == 5'b1) begin
                    addr_w = addr_r - window_size + (width+1) * (window_size / 3);
                    sum_w = sum_r + data_r;
                end
                else if(box_counter_r == 5'd2) begin
                    addr_w = addr_r + window_size;
                    sum_w = sum_r - data_r;
                end
                else if(box_counter_r == 5'd3) begin
                    sum_w = sum_r - data_r;
                end
                else if(box_counter_r == 5'd4) begin
                    sum_w = sum_r + data_r;
                    if(sum_w < HAIR_THRESHOLD) begin
                        box_counter_w = 5'b0;
                        state_w = INIT;
                    end
                    else begin
                        state_w = CAL;
                        box_counter_w = 5'b0;
                        addr_w = GRAY_I + (row_counter_r + f_y) * (width+1) + col_counter_r + f_x;
								hair_counter_w = hair_counter_r + 10'b1;
                    end
                end
            end
            CAL: begin
                box_counter_w = box_counter_r + 1;
                if(feature == F2V || feature == F2H) begin
                    if(feature == F2V) begin
                        addr_w = box_counter_r[0] ?
                                 (addr_r - f_width + (width+1) * f_height / 2) : 
                                 (addr_r + f_width);
                    end
                    else begin
                        addr_w = box_counter_r[0] ?
                                 (addr_r - f_height * (width+1) + f_width / 2) :
                                 (addr_r + f_height * (width+1));
                    end
                    if(box_counter_r == 5'b0) sum_w = 16'b0;
                    else if(box_counter_r == 5'd1) sum_w = sum_r - data_r;
                    else if(box_counter_r == 5'd2) sum_w = sum_r + data_r;
                    else if(box_counter_r == 5'd3) sum_w = sum_r + data_r * 2;
                    else if(box_counter_r == 5'd4) sum_w = sum_r - data_r * 2;
                    else if(box_counter_r == 5'd5) sum_w = sum_r - data_r;
                    else if(box_counter_r == 5'd6) begin
                        sum_w = sum_r + data_r;
                        if(feature == F2H) sum_w = sum_w * (-1);
                        if(polarity) csum_w = csum_r + ((sum_w > threshold) ? 5'b1 : 5'b0);
                        else         csum_w = csum_r + ((sum_w < threshold) ? 5'b1 : 5'b0);
                    end
                    else if(box_counter_r == 5'd7) begin
                        f_counter_w = f_counter_r + 1;
                        box_counter_w = 5'b0;
                        if(f_counter_r == lnum[l_counter_r] - 1) begin
                            csum_w = 5'b0;
                            if(csum_r < lthreshold[l_counter_r]) begin
                                state_w = INIT;
                                f_counter_w = 5'b0;
                                l_counter_w = 2'b0;
                                save_prob_w = 5'b0;
                            end
                            else begin
                                l_counter_w = l_counter_r + 1;
                                save_prob_w = save_prob_r + csum_r;
                                if(l_counter_r == 2'b1) begin
                                    l_counter_w = 2'b0;
                                    state_w = COMP;
                                    f_counter_w = 5'b0;
                                end
                            end
                        end
								
                        addr_w = GRAY_I + (row_counter_r + classifier[f_counter_w][30:26]) * (width+1) 
                                        + col_counter_r + classifier[f_counter_w][35:31];
                    end
                end
                else if(feature == F4) begin
                    if(box_counter_r == 5'b0) begin
                        sum_w = 16'b0;
                        addr_w = addr_r + f_width / 2;
                    end
                    else if(box_counter_r == 5'd1) begin
                        sum_w = sum_r + data_r;
                        addr_w = addr_r + f_width / 2;
                    end
                    else if(box_counter_r == 5'd2) begin
                        sum_w = sum_r - data_r * 2;
                        addr_w =  addr_r - f_width + f_height * (width+1) / 2;
                    end
                    else if(box_counter_r == 5'd3) begin
                        sum_w = sum_r + data_r;
                        addr_w = addr_r + f_width / 2;
                    end
                    else if(box_counter_r == 5'd4) begin
                        sum_w = sum_r - data_r * 2;
                        addr_w = addr_r + f_width / 2;
                    end
                    else if(box_counter_r == 5'd5) begin
                        sum_w = sum_r + data_r * 4;
                        addr_w =  addr_r - f_width + f_height * (width+1) / 2;
                    end
                    else if(box_counter_r == 5'd6) begin
                        addr_w = addr_r + f_width / 2;
                        sum_w = sum_r - data_r * 2;
                    end
                    else if(box_counter_r == 5'd7) begin
                        addr_w = addr_r + f_width / 2;
                        sum_w = sum_r + data_r;
                    end
                    else if(box_counter_r == 5'd8) begin
                        addr_w = addr_r + f_width / 2;
                        sum_w = sum_r - data_r * 2;
                    end
                    else if(box_counter_r == 5'd9) begin
                        sum_w = sum_r + data_r;
                        if(polarity) csum_w = csum_r + ((sum_w > threshold) ? 5'b1 : 5'b0);
                        else         csum_w = csum_r + ((sum_w < threshold) ? 5'b1 : 5'b0);
                    end
                    else if(box_counter_r == 5'd10) begin
                        f_counter_w = f_counter_r + 1;
                        box_counter_w = 5'b0;
                        if(f_counter_r == lnum[l_counter_r] - 1) begin
                            csum_w = 5'b0;
                            if(csum_r < lthreshold[l_counter_r]) begin
                                state_w = INIT;
                                f_counter_w = 5'b0;
                                l_counter_w = 2'b0;
                                save_prob_w = 5'b0;
                            end
                            else begin
                                l_counter_w = l_counter_r + 1;
                                save_prob_w = save_prob_r + csum_r;
                                if(l_counter_r == 2'b1) begin
                                    l_counter_w = 2'b0;
                                    state_w = COMP;
                                    f_counter_w = 5'b0;
                                end
                            end
                        end
						
                        addr_w = GRAY_I + (row_counter_r + classifier[f_counter_w][30:26]) * (width+1) 
                                        + col_counter_r + classifier[f_counter_w][35:31];
                    end
                end
            end
            COMP: begin
                neighbor = 0;
                for(i = 0; i < num_r; i = i + 1) begin
                    //if (row-face_positions[i][0]) + (col-face_positions[i][1]) < WINDOW_SIZE:
                    if(abs(row_counter_r - row_r[i]) + abs(col_counter_r - col_r[i]) < window_size) begin
                        neighbor = 1;
                        if(save_prob_r > prob_r[i]) begin
                            col_w[i] = col_counter_r;
                            row_w[i] = row_counter_r;
                            prob_w[i] = save_prob_r;
                        end
                    end
                end
                if(neighbor == 0) begin
                    col_w[num_r] = col_counter_r;
                    row_w[num_r] = row_counter_r;
                    prob_w[num_r] = save_prob_r;
                    num_w = num_r + 1;
                end
                state_w = INIT;
                save_prob_w = 5'b0;
            end
            EYE_I: begin
                col_counter_w = col_counter_r + 1;
                state_w = EYE;
                sum_w = 16'b0;

                if(col_counter_r == col_r[num_r] + 23) begin
                    row_counter_w = row_counter_r + 1;
                    col_counter_w = col_r[num_r];
                    if(row_counter_r == row_r[num_r] + 11) begin
                        num_w = num_r + 1;
                        row_counter_w = row_r[num_w] + 3;
                        col_counter_w = col_r[num_w];
                        l_counter_w = 2'd0;
                        eye_prob_w[0] = 0;
                        eye_prob_w[1] = 0;
                        if(num_r == o_num_r - 1) begin
									state_w = IDLE;
									finish_w = 1'b1;
									num_w = 2'b0;
									for(i = 0; i < 3; i = i + 1) begin
										oeyecol_w[i][0] = eyecol_r[i][0];
										oeyecol_w[i][1] = eyecol_r[i][1];
										oeyerow_w[i][0] = eyerow_r[i][0];
										oeyerow_w[i][1] = eyerow_r[i][1];
									end
                        end
                    end
                end
                addr_w = HAIR_I + row_counter_w * (width+1) + col_counter_w;
            end
            EYE: begin
                box_counter_w = box_counter_r + 1;
                if(box_counter_r == 5'b0) begin
                    sum_w = 16'd22;
                    addr_w = addr_r + 7;
                end
                else if(box_counter_r == 5'd1) begin
                    sum_w = sum_r - data_r;
                    addr_w = addr_r + 4 * (width+1) - 7;
                end
                else if(box_counter_r == 5'd2) begin
                    sum_w = sum_r + data_r;
                    addr_w =  addr_r + 7;
                end
                else if(box_counter_r == 5'd3) begin
                    sum_w = sum_r + data_r;
                    addr_w = HAIR_I + (row_counter_r+1) * (width+1) + col_counter_r + 2;
                end
                else if(box_counter_r == 5'd4) begin
                    sum_w = sum_r - data_r;
                    addr_w = addr_r + 3;
                end
                else if(box_counter_r == 5'd5) begin
                    sum_w = sum_r + data_r * 2;
                    addr_w =  addr_r + 2 * (width+1) - 3;
                end
                else if(box_counter_r == 5'd6) begin
                    addr_w = addr_r + 3;
                    sum_w = sum_r - data_r * 2;
                end
                else if(box_counter_r == 5'd7) begin
                    sum_w = sum_r - data_r * 2;
                end
                else if(box_counter_r == 5'd8) begin
                    sum_w = sum_r + data_r * 2;
                    box_counter_w = 5'b0;
                    if(sum_w < EYE_THRESHOLD) begin
                        state_w = EYE_I;
                    end
                    else begin
                        state_w = EYE_C;
                    end
                end
            end
            EYE_C: begin
                neighbor = 0;
                for(i = 0; i < 2; i = i + 1) begin

                    if(abs(row_counter_r-eyerow_r[num_r][i]) + abs(col_counter_r-eyecol_r[num_r][i]) < 7) begin
                        neighbor = 1;
                        if(sum_r > eye_prob_r[i]) begin
                            eyecol_w[num_r][i] = col_counter_r;
                            eyerow_w[num_r][i] = row_counter_r;
                            eye_prob_w[i]  = sum_r;
                        end
                    end
                end
                if(neighbor == 0) begin
                    eyecol_w[num_r][l_counter_r] = col_counter_r;
                    eyerow_w[num_r][l_counter_r] = row_counter_r;
                    eye_prob_w[l_counter_r] = sum_r;
                    l_counter_w = l_counter_r + 1; 
                end
                state_w = EYE_I;
                sum_w = 5'b0;
            end
        endcase
    end

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
				//data_r			 <= 16'b0;
            addr_r          <= 20'b0;
            col_counter_r   <= 7'b0;
            row_counter_r   <= 7'b0;
            box_counter_r   <= 5'b0;
            f_counter_r     <= 5'b0;
            l_counter_r     <= 5'b0;
            state_r         <= IDLE;
            sum_r           <= 16'b0;
            csum_r          <= 5'd0;
            num_r           <= 2'd0;
            o_num_r         <= 2'd0;
            finish_r        <= 1'b0;
            save_prob_r     <= 5'b0;
				frame_counter_r <= 16'b0;
				skin_counter_r  <= 16'b0;
				hair_counter_r  <= 16'b0;
            eye_prob_r[0]   <= 5'b0;
            eye_prob_r[1]   <= 5'b0;
            for(i = 0; i < 3; i = i + 1) begin
                row_r[i]    <= 7'b0;
                col_r[i]    <= 7'b0;
                o_row_r[i]  <= 7'b0;
                o_col_r[i]  <= 7'b0;
                prob_r[i]   <= 5'b0;
                eyerow_r[i][0]  <= 5'b0;
                eyerow_r[i][1]  <= 5'b0;
                eyecol_r[i][0]  <= 5'b0;
                eyecol_r[i][1]  <= 5'b0;
                oeyerow_r[i][0]  <= 5'b0;
                oeyerow_r[i][1]  <= 5'b0;
                oeyecol_r[i][0]  <= 5'b0;
                oeyecol_r[i][1]  <= 5'b0;
            end
        end
        else begin
            addr_r          <= addr_w;
            //data_r          <= data;
            col_counter_r   <= col_counter_w;
            row_counter_r   <= row_counter_w;
            box_counter_r   <= box_counter_w;
            f_counter_r     <= f_counter_w;
            l_counter_r     <= l_counter_w;
            state_r         <= state_w;
            sum_r           <= sum_w;
            csum_r          <= csum_w;
            num_r           <= num_w;
				o_num_r			 <= o_num_w;
            finish_r        <= finish_w;
            save_prob_r     <= save_prob_w;
				frame_counter_r <= frame_counter_w;
				skin_counter_r  <= skin_counter_w;
				hair_counter_r  <= hair_counter_w;
            eye_prob_r[0]   <= eye_prob_w[0];
            eye_prob_r[1]   <= eye_prob_w[1];
            for(i = 0; i < 3; i = i + 1) begin
                row_r[i]    <= row_w[i];
                col_r[i]    <= col_w[i];
                o_row_r[i]  <= o_row_w[i];
                o_col_r[i]  <= o_col_w[i];
                prob_r[i]   <= prob_w[i];
                eyerow_r[i][0]  <= eyerow_w[i][0];
                eyerow_r[i][1]  <= eyerow_w[i][1];
                eyecol_r[i][0]  <= eyecol_w[i][0];
                eyecol_r[i][1]  <= eyecol_w[i][1];
                oeyerow_r[i][0]  <= oeyerow_w[i][0];
                oeyerow_r[i][1]  <= oeyerow_w[i][1];
                oeyecol_r[i][0]  <= oeyecol_w[i][0];
                oeyecol_r[i][1]  <= oeyecol_w[i][1];
            end
        end

    end

    function signed [6:0] abs;
        input signed [6:0] value;
        begin
            abs = (value >= 0) ? value : value * (-1);
        end
    endfunction

endmodule


