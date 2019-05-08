module frame_receiver (o_state, o_data, o_dv, o_change, o_error,  iclk, irx_data, irx_dv, irx_er);
	input 				iclk;
	input [7:0]			irx_data; 
	input 				irx_dv;
	input 				irx_er;

	output wire [2:0]	o_state;
	output wire [7:0]	o_data;
	output wire			o_dv;
	output wire			o_change;
	output wire			o_error;
    
`include "crc.v"

localparam lpNO_FRAME = 3'b000; //s0 - no frame
localparam lpPREAMBLE = 3'b001; // start of preamble
localparam lpDELIMETER = 3'b010; // s2 - SD (delimeter)
localparam lpDA = 3'b011; // s3 - Destination adress
localparam lpSA = 3'b100;// s4 - Source adress
localparam lpLENGTH = 3'b101; //s5 - length
localparam lpDATA = 3'b110; // Data
localparam lpFCS = 3'b111; // FCS - control summ

reg [2:0] rCstate = lpNO_FRAME; 
reg [2:0] rNstate = lpPREAMBLE;
reg [3:0] rFCS_counter=3'd0;
reg [10:0] rcounter=11'd0; // counter inside of Next State Logic
reg rerror=1'b0; //Signalises an error

reg [7:0] rbyteSR [3:0] = '{default: 'b0};
reg r_dv [3:0] ;
reg r_change = 1'b0;
integer i = 0;
bit [31:0] rcrc_new;
// Table of states:
always @* 
begin
    if (rerror==1'b1) rNstate = lpNO_FRAME;
    else
    begin
    case (rCstate)
    lpNO_FRAME:		rNstate = lpPREAMBLE   ;
    lpPREAMBLE:		rNstate = lpDELIMETER  ;
    lpDELIMETER: 	rNstate = lpDA         ;
    lpDA: 			rNstate = lpSA         ;
	lpSA:			rNstate = lpLENGTH	   ;
    lpLENGTH: 		rNstate = lpDATA       ;
	lpDATA:			rNstate = lpFCS		   ;
	lpFCS:			rNstate = lpNO_FRAME   ;
    endcase
    end
end

//	Next state logic
always @(posedge iclk or negedge irx_dv) 
	begin
		case (rCstate)
		lpNO_FRAME: begin 
					rerror <= 1'b0;
					r_change<=1'b0;
					if (rbyteSR[2]==8'h55) begin
						rCstate<=rNstate;
						r_change<=1'b1;
					end
					end
		lpPREAMBLE: begin
					r_change <= 1'b0;
					if (rbyteSR[2]==8'hD5) begin
					rCstate<=rNstate;
					r_change<=1'b1;
					rcounter<=11'b0;
					end
					rcounter<=rcounter+11'b1;
					rerror <= irx_er | (rcounter > 8);
					end	
		lpDELIMETER:begin rerror <= irx_er;
					rCstate<=rNstate;
					r_change<=1'b1;
					rcounter<=11'b0;
					end
		lpDA: 		begin  
					rerror <= irx_er;
					r_change<=0;
					rcounter<=rcounter+1'b1;
					if (rcounter==11'd5) begin
						rCstate<=rNstate;
						r_change<=1'b1;
						rcounter<=11'b0;
					end
					end
		lpSA:		begin 
					rerror <= irx_er;
					r_change<=1'b0;
					rcounter<=rcounter+11'b1;
					if (rcounter==11'd5) begin
						rCstate<=rNstate;
						r_change<=1'b1;
						rcounter<=11'b0;
					end
					end
		lpLENGTH:	begin 
					rerror <= irx_er;
					rcounter<=rcounter+1'b1;
					if (rcounter==11'd1) begin
						rCstate<=rNstate;
						r_change<=1'b1;
						rcounter<=11'b0;
						
					end
					else r_change<=1'b0;
					end
		lpDATA:		begin r_change<=1'b0;
					rcounter<=rcounter+1'b1;
					if (rcounter==11'd1500)
						rerror <= 1'b1;
					if (irx_dv==0) begin
						rCstate<=rNstate;
						r_change<=1'b1;
						rFCS_counter<=3'b0;
					end
					end
		lpFCS:		begin r_change<=1'b0; 
					rerror <= irx_er;
					rFCS_counter<=rFCS_counter+1'b1;
						if (rFCS_counter==3'd3) begin
						rCstate<=rNstate;
						r_change<=1'b1;
						rcounter<=11'b0;
						rFCS_counter<=3'b000;
					end
					end 
		default: 	rNstate<=lpNO_FRAME;
	endcase
	end

	assign o_state = rCstate;
	assign o_change = r_change;
	assign o_data  = rbyteSR[3];
	assign o_dv = r_dv[3];
	assign o_error= rerror || irx_er;
    
// 4 registers consequentially - buffer 
always @(posedge iclk)
	begin
	for (i=3; i > 0; i=i-1)
	begin
		rbyteSR[i]<=rbyteSR[i-1];
		r_dv[i] <=r_dv[i-1];
	end
	rbyteSR[0]<=irx_data;
	r_dv[0] <=irx_dv;
end

always @(posedge iclk)
begin
	if (o_dv)
	begin
		case (o_state)
		lpDELIMETER : rcrc_new <= '1;
		lpDA, lpSA, lpLENGTH, lpDATA, lpFCS: rcrc_new <= eth_crc32_8d(rcrc_new, o_data);
		endcase
	end
		if ((rcrc_new!==32'hC704DD7B) && (rCstate==lpNO_FRAME))
		begin if (rcrc_new==32'h0)
			rerror<=1'b0;
			else  
			rerror<=1'b1;
		end
end
endmodule
