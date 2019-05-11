 `include "header.v"

module pre_arbiter

    ( 
        input wire                                  iclk,       // Signal declaration
        input wire                                  i_w_permition,
        input wire [7:0]                            irx_d,                    
        input wire                                  i_rst,      
        input wire                                  idv,
        input wire                                  i_error,
        input wire [2:0]                            iFSM_state,
        input wire [1:0]                            i_port_num,            
        output reg [pFIFO_WIDTH-1:0]                o_length,
        output wire [1:0]                           o_port_num,
        output wire [$clog2(pDEPTH_RAM)-1:0]        o_start_adress,
        output wire                                 o_request
    );  

        localparam lpWAIT=2'b00;
        localparam lpWORK=2'b01; 
        localparam lpREQUEST=2'b10;
        
        wire                                                w_packet_read;
        wire [pFIFO_WIDTH-1:0]                              w_FIFO;

        reg                                                 r_read_enable=1'b0;
        reg [7:0]                                           r_o_reg;
        reg                                                 r_req_en=1'b0;
        reg [1:0]                                           r_port_number;

        reg [1:0]                                           r_state = lpWAIT;              
        reg [1:0]                                           r_state_next = lpWORK;

 ravil_memory
        SUPER_MODULE
    (
        .iclk                   (iclk),
        .i_rst                  (i_rst),
        .idv                    (idv),
        .i_error                (i_error),
        .irx_d                  (irx_d),
        .iFSM_state             (iFSM_state),
        .i_r_enable             (r_read_enable),
        .o_FIFO                 (w_FIFO),
        .o_reg                  (r_o_reg),
        .o_read_pointer         (o_start_adress),
        .o_packet_read          (w_packet_read)
    );

     always @* begin
        case(r_state)
            lpWAIT:     r_state_next = lpWORK; //waiting for packets
            lpWORK:     r_state_next = lpREQUEST; //writing to reg_memory
            lpREQUEST:  r_state_next = lpWAIT; //checking CRC + writing to FIFO
        endcase
    end

    always @(posedge iclk) begin
        case (r_state)
        lpWAIT: begin
                r_req_en<=1'b0;
                if (i_w_permition)
                r_state<=r_state_next;
                end
        lpWORK: begin   
                r_read_enable<=1'b1; 
                r_port_number<=i_port_num;
                if (w_packet_read == 1'b1)
                r_state<=r_state_next;
                end
        lpREQUEST: begin
                r_req_en<=1'b1;
                r_read_enable<=1'b0; 
                r_state<=r_state_next;
                end
        endcase
        end

    always @(posedge iclk) begin
        if (w_packet_read == 1'b1)
        o_length<=w_FIFO;
        end
         
    assign o_port_num=r_port_number;
    assign o_request = r_req_en;

endmodule
  // Возможно будут ошибки с wire и reg


