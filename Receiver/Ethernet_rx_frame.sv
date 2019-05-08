module Ethernet_rx_frame
    (
        input wire          i_rx_clk,
        input wire          i_rx_dv,
        input wire          i_rx_er,
        input wire  [7:0]   i_rx_d,
    
        output wire [2:0]   o_fsm_state,
        output reg         o_fsm_state_changed = 0,
    
        output wire         o_rx_dv_4cd,
        output wire         o_rx_er_4cd,
        output wire [7:0]   o_rx_d4cd
    );
    
    localparam [2:0] lpND  =  3'b000,     // No data
                     lpPRE =  3'b001,     // Preambula
                     lpSFD =  3'b010,     // Delimiter
                     lpDA  =  3'b011,     // Destination Adress
                     lpSA  =  3'b100,     // Source Adress
                     lpDATA = 3'b101,     // Data
                     lpCRC  = 3'b110;     // CRC     

    // local variables
    reg [2:0]       r_state_reg = lpND;
    reg [2:0]       r_state_next = lpPRE;               
    reg [4:0][7:0]  r_data_buffer = 32'b0;
    reg [4:0]       r_rx_er_buffer = 5'b0;
    reg [4:0]       r_rx_dv_buffer = 5'b0;
    reg [10:0]      counter = 11'd0;
    int             i = 0;
	reg toggle = 1'b0;
	
    // Sequential logic
    always @(posedge i_rx_clk) begin 
        if (i_rx_dv && !i_rx_er) 
        begin
            case(r_state_reg)
                (lpND): begin
                    if (r_data_buffer[3] == 8'h55) begin
                        r_state_reg <= r_state_next;
                        o_fsm_state_changed <= 1;
                    end    
                end
                (lpPRE): begin          
                    if (o_fsm_state_changed == 1) begin
                        o_fsm_state_changed <= 0;
                        counter <= 11'd7;
                    end    
                    else if (r_data_buffer[3] == 8'hd5) begin
                        r_state_reg <= r_state_next;
                        o_fsm_state_changed <= 1;
                    end
                    else if (counter == 11'd0) begin  // reset
                        r_state_reg    <= lpND;
                        r_data_buffer  <= 32'b0;
                        r_rx_dv_buffer <= 5'b0;
                        r_rx_er_buffer <= 5'b0;

                    end
                    counter <= counter - 11'b1;
                end
                (lpSFD): begin           
                    r_state_reg <= r_state_next;
                    counter <= 11'd5;
                end
                (lpDA): begin           
                    if (o_fsm_state_changed == 1) begin
                        o_fsm_state_changed <=0;
                        counter <= counter - 11'b1;
                    end    
                    else if (counter == 11'd0) begin
                        r_state_reg <= r_state_next;
                        o_fsm_state_changed <= 1;
                        counter <= 11'd5;
                    end    
                    else counter <= counter - 11'b1;
                end
                (lpSA): begin           
                    if (o_fsm_state_changed == 1) begin
                        o_fsm_state_changed <=0;
                        counter <= counter - 11'b1;
                    end    
                    else if (counter == 11'd0) begin
                        r_state_reg <= r_state_next;
                        o_fsm_state_changed <= 1;
                        counter <= 11'd1500;
                    end    
                    else counter <= counter - 11'b1;
                end
                (lpDATA): begin          
                    if (o_fsm_state_changed == 1) begin
                        o_fsm_state_changed <=0;
                    end 
                    else if (counter == 11'd0) begin  // reset
                        r_state_reg    <= lpND;
                        r_data_buffer  <= 32'b0;
                        r_rx_dv_buffer <= 5'b0;
                        r_rx_er_buffer <= 5'b0;
                    end  
                    else counter <= counter - 11'b1;
                end
            endcase   
        end
        if (i_rx_dv && i_rx_er) begin   // reset
            r_state_reg    <= lpND;
            r_data_buffer  <= 32'b0;
            r_rx_dv_buffer <= 'b0;
            r_rx_er_buffer <= 'b0; 
        end
        if (!i_rx_dv && !i_rx_er) begin // CRC out and reset
            if (r_state_reg == lpDATA) begin 
                r_state_reg <= r_state_next;
                o_fsm_state_changed <= 1'b1;
            end
            else if(r_state_reg == lpCRC) begin
                if (o_fsm_state_changed == 1) begin
                    o_fsm_state_changed <=0;
                    counter <= 11'b000_0000_0010;
                end
                else if (counter == 11'd0) begin
                    r_state_reg    <= lpND;
                    r_data_buffer  <= 32'b0;
                    r_rx_dv_buffer <= 5'b0;
                    r_rx_er_buffer <= 5'b0;                    
                end
                else counter <= counter - 11'b1;
            end
            else begin
                r_state_reg    <= lpND;
                r_data_buffer  <= 32'b0;
                r_rx_dv_buffer <= 5'b0;
                r_rx_er_buffer <= 5'b0;
            end
        end

        // Shift inputs and data  
        for (i = 0; i < 4; i = i +1 ) begin
            r_data_buffer[i+1]  <= r_data_buffer[i];
            r_rx_dv_buffer[i+1] <= r_rx_dv_buffer[i];
            if(toggle) r_rx_er_buffer[4] <= 1'b1;
            else r_rx_er_buffer[i+1] <= r_rx_er_buffer[i];    
        end
        r_data_buffer[0]  <=    i_rx_d;
        r_rx_dv_buffer[0] <=    i_rx_dv;
        r_rx_er_buffer[0] <=    i_rx_er;
    end
    
        // Combinational logic
        always @* begin
            case(r_state_reg)
                lpND:       r_state_next <= lpPRE;
                lpPRE:      r_state_next <= lpSFD;
                lpSFD:      r_state_next <= lpDA;
                lpDA:       r_state_next <= lpSA;
                lpSA:       r_state_next <= lpDATA;
                lpDATA:     r_state_next <= lpCRC;
                lpCRC:      r_state_next <= lpND;
            endcase  
        end
        
        assign  o_rx_d4cd = r_data_buffer[4];
        assign  o_rx_er_4cd = r_rx_er_buffer[4];
        assign  o_rx_dv_4cd = r_rx_dv_buffer[4];
        assign  o_fsm_state = r_state_reg;
        
        
function integer eth_crc32_8d(input integer crc32, input logic [7:0] data);
	bit [ 7:0] d;
    bit [31:0] c;
    bit [31:0] newcrc;
    begin
	    for (int i=0;i<8;i++) d[i] = data[7-i];
        
        c = crc32;
        newcrc[0] = d[6] ^ d[0] ^ c[24] ^ c[30];
        newcrc[1] = d[7] ^ d[6] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[30] ^ c[31];
        newcrc[2] = d[7] ^ d[6] ^ d[2] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[26] ^ c[30] ^ c[31];
        newcrc[3] = d[7] ^ d[3] ^ d[2] ^ d[1] ^ c[25] ^ c[26] ^ c[27] ^ c[31];
        newcrc[4] = d[6] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[24] ^ c[26] ^ c[27] ^ c[28] ^ c[30];
        newcrc[5] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[27] ^ c[28] ^ c[29] ^ c[30] ^ c[31];
        newcrc[6] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30] ^ c[31];
        newcrc[7] = d[7] ^ d[5] ^ d[3] ^ d[2] ^ d[0] ^ c[24] ^ c[26] ^ c[27] ^ c[29] ^ c[31];
        newcrc[8] = d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[0] ^ c[24] ^ c[25] ^ c[27] ^ c[28];
        newcrc[9] = d[5] ^ d[4] ^ d[2] ^ d[1] ^ c[1] ^ c[25] ^ c[26] ^ c[28] ^ c[29];
        newcrc[10] = d[5] ^ d[3] ^ d[2] ^ d[0] ^ c[2] ^ c[24] ^ c[26] ^ c[27] ^ c[29];
        newcrc[11] = d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[3] ^ c[24] ^ c[25] ^ c[27] ^ c[28];
        newcrc[12] = d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ d[0] ^ c[4] ^ c[24] ^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30];
        newcrc[13] = d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[2] ^ d[1] ^ c[5] ^ c[25] ^ c[26] ^ c[27] ^ c[29] ^ c[30] ^ c[31];
        newcrc[14] = d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[2] ^ c[6] ^ c[26] ^ c[27] ^ c[28] ^ c[30] ^ c[31];
        newcrc[15] = d[7] ^ d[5] ^ d[4] ^ d[3] ^ c[7] ^ c[27] ^ c[28] ^ c[29] ^ c[31];
        newcrc[16] = d[5] ^ d[4] ^ d[0] ^ c[8] ^ c[24] ^ c[28] ^ c[29];
        newcrc[17] = d[6] ^ d[5] ^ d[1] ^ c[9] ^ c[25] ^ c[29] ^ c[30];
        newcrc[18] = d[7] ^ d[6] ^ d[2] ^ c[10] ^ c[26] ^ c[30] ^ c[31];
        newcrc[19] = d[7] ^ d[3] ^ c[11] ^ c[27] ^ c[31];
        newcrc[20] = d[4] ^ c[12] ^ c[28];
        newcrc[21] = d[5] ^ c[13] ^ c[29];
        newcrc[22] = d[0] ^ c[14] ^ c[24];
        newcrc[23] = d[6] ^ d[1] ^ d[0] ^ c[15] ^ c[24] ^ c[25] ^ c[30];
        newcrc[24] = d[7] ^ d[2] ^ d[1] ^ c[16] ^ c[25] ^ c[26] ^ c[31];
        newcrc[25] = d[3] ^ d[2] ^ c[17] ^ c[26] ^ c[27];
        newcrc[26] = d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[18] ^ c[24] ^ c[27] ^ c[28] ^ c[30];
        newcrc[27] = d[7] ^ d[5] ^ d[4] ^ d[1] ^ c[19] ^ c[25] ^ c[28] ^ c[29] ^ c[31];
        newcrc[28] = d[6] ^ d[5] ^ d[2] ^ c[20] ^ c[26] ^ c[29] ^ c[30];
        newcrc[29] = d[7] ^ d[6] ^ d[3] ^ c[21] ^ c[27] ^ c[30] ^ c[31];
        newcrc[30] = d[7] ^ d[4] ^ c[22] ^ c[28] ^ c[31];
        newcrc[31] = d[5] ^ c[23] ^ c[29];
        eth_crc32_8d = newcrc;
    end
endfunction

reg [31:0] rcrc_new = 'b0;

always @(posedge i_rx_clk) begin 
    case(r_state_reg) 
        lpPRE: toggle <= 1'b0;
        lpSFD: rcrc_new <= '1;
        lpDA, lpSA, lpDATA, lpCRC: rcrc_new <= eth_crc32_8d(rcrc_new, o_rx_d4cd);
        lpND: begin 
            if ((rcrc_new != 32'hC704DD7B )&(rcrc_new != 32'h0000_0000)) begin 
                toggle <= 1'b1;
            end
        end    
    endcase    
end

endmodule
