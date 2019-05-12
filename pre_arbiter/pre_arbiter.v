 `include "header.v"

module pre_arbiter_0

    ( 
        input wire                                                                    iclk,       // Signal declaration
        input wire                                                                    i_w_permition,                         
        input wire [$clog2(pPORT_NUM)-1:0]                                            i_port_num,            
        input wire [pFIFO_WIDTH-1:0]                                                  i_length_ptr,
        output reg [pFIFO_WIDTH+$clog2(pDEPTH_RAM)-1:0]                               o_FIFO_1,
        output reg [pFIFO_WIDTH+$clog2(pDEPTH_RAM)-1:0]                               o_FIFO_2,
        output reg [pFIFO_WIDTH+$clog2(pDEPTH_RAM)-1:0]                               o_FIFO_3,
        output wire                                                                   o_request
    );  

        localparam lpWAIT_PRE=1'b0;
        localparam lpWORK_PRE=1'b1; 
     
        reg                                               r_state = lpWAIT_PRE;
        reg                                               r_state_next = lpWORK_PRE;
    
        reg                                               r_request='0;
        reg [1:0]                                         r_counter='0;
        reg [pFIFO_WIDTH+$clog2(pDEPTH_RAM)-1:0]          r_buffer;

        always @* begin
            case(r_state)
                lpWAIT_PRE:       r_state_next <= lpWORK_PRE;
                lpWORK_PRE:       r_state_next <= lpWAIT_PRE;
            endcase  
        end

        always @(posedge iclk) begin
        case (r_state)
            lpWAIT_PRE: begin
                            if (i_w_permition)
                            r_state<=r_state_next;
                        end 
            lpWORK_PRE: begin
                        case (r_counter)
                            2'b00: begin   
                                   r_request<=1;
                                   r_counter<=r_counter+1;
                            end
                            2'b01: begin
                                   r_buffer<=i_length_ptr;
                                   r_counter<=r_counter+1;
                            end
                            2'b10: begin
                                   case (i_port_num)
                            2'b01: o_FIFO_1<={i_length_ptr};
                            2'b10: o_FIFO_2<={i_length_ptr};
                            2'b11: o_FIFO_3<={i_length_ptr};
                                   endcase
                            r_state<=r_state_next;
                             r_counter<=0;
                            end
                        end
            endcase
            end



        assign o_request=r_request;
endmodule
        

