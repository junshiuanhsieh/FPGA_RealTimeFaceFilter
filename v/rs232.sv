module RS232 (
    input         avm_rst,
    input         avm_clk,
    output [4:0]  avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest,
    input  [7:0] sram_rs232_data,
	 input			send_start,
    output        send_finished,
	 output [16:0] sram_rs232_addr,
	 output [3:0]  rs232_state
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

localparam TOTAL_ADDR = 320 * 240;

// Feel free to design your own FSM!
localparam S_IDLE = 0;
localparam S_WAIT_SEND = 1;
localparam S_SEND_DATA = 2;

logic [3:0] state_r, state_w;
logic [4:0] avm_address_r, avm_address_w;
logic	[7:0]	sram_rs232_data_r;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;
//logic [1:0] counter_r, counter_w;
logic [18:0] sram_rs232_addr_r, sram_rs232_addr_w;

logic send_finished_r, send_finished_w;

assign avm_address      = avm_address_r;
assign avm_read         = avm_read_r;
assign avm_write        = avm_write_r;
//assign avm_writedata    = (sram_rs232_data << (counter_r * 8)) & 23'hFF;
assign avm_data = 8'd87;
assign send_finished    = send_finished_r;
assign sram_rs232_addr	= sram_rs232_addr_r;
assign rs232_state		= state_r;

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w      = 1;
        avm_write_w     = 0;
        avm_address_w   = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w      = 0;
        avm_write_w     = 1;
        avm_address_w   = addr;
    end
endtask

always_comb begin
	avm_read_w        = avm_read_r;
	avm_write_w       = avm_write_r;
	avm_address_w     = avm_address_r;
	state_w           = state_r;
   send_finished_w   = send_finished_r;
	//counter_w 	      = counter_r;
	sram_rs232_addr_w = sram_rs232_addr_r;

	case(state_r)
		  S_IDLE: begin
				if(send_start) begin
					state_w = S_WAIT_SEND;
					StartRead(STATUS_BASE);
				end
		  end
        S_WAIT_SEND: begin
            StartRead(STATUS_BASE);
            if(!avm_waitrequest && avm_readdata[TX_OK_BIT]) begin
                state_w = S_SEND_DATA;
                StartWrite(TX_BASE);
                send_finished_w = 1'b0;
            end
        end
        
        S_SEND_DATA: begin
            if(!avm_waitrequest) begin
                avm_write_w = 0;
                if(sram_rs232_addr_r == TOTAL_ADDR-1) begin
                    state_w = S_IDLE;
						  sram_rs232_addr_w = 0;
                    send_finished_w = 1'b1;
                end
                else begin
                    state_w = S_WAIT_SEND;
                    StartRead(STATUS_BASE);
						  sram_rs232_addr_w = sram_rs232_addr_r + 1'd1;
                    send_finished_w = 1'b0;
					 end
           end
        end
			
	endcase
end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        avm_address_r   	<= STATUS_BASE;
        avm_read_r      	<= 1;
        avm_write_r     	<= 0;
        state_r         	<= S_IDLE;
		  send_finished_r		<= 0;
		  //counter_r				<= 0;
		  sram_rs232_addr_r	<= 17'd0;
		  sram_rs232_data_r	<= 8'd0;
    end else begin
        avm_address_r   	<= avm_address_w;
        avm_read_r      	<= avm_read_w;
        avm_write_r     	<= avm_write_w;
        state_r         	<= state_w;
        send_finished_r 	<= send_finished_w;
		  //counter_r				<= counter_w;
		  sram_rs232_addr_r	<= sram_rs232_addr_w;
		  sram_rs232_data_r	<= sram_rs232_data;
    end
end
 
endmodule
