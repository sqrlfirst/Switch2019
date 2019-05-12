`include "header.v"

module copy_packet_to_mem //Переделать
    #(
        parameter pDATA_WIDTH        = 8,                     
                  pMIN_PACKET_LENGHT = 64,
                  pMAX_PACKET_LENGHT = 1536,
                  pFIFO_WIDTH        = $clog2(pMAX_PACKET_LENGHT),
                  pDEPTH_RAM         = 2*pMAX_PACKET_LENGHT,
                  pFIFO_DEPTH        = pDEPTH_RAM/pMIN_PACKET_LENGHT 
    )
    (
    input wire                                              iclk,
    input wire                                              irst,
    input wire                                              idv,
    input wire [pDATA_WIDTH-1:0]                            irx_d,
    input wire                                              irx_er,
    input wire [pFSM_BUS_WIDHT-1:0]                         iframe_state,
    input wire                                              ird_en,             // for pre_arb
    input wire                                              iready,             // Avalon-ST                                                                // Ended there
    output wire                                             oempty_sram,
    output wire                                             ofull_sram,
    output reg                                              oempty_fifo,
    output reg                                              ofull_fifo,
    output wire [pFIFO_WIDTH+$clog2(pDEPTH_RAM)-1:0]        olen_plus_ptr,
    output wire [$clog2(pMAC_MEM_DEPTH)-1:0]                oda,                
    output wire                                             ovalid,             // Avalon-ST
    output wire [pDATA_WIDTH=1:0]                           odata,              // Avalon-ST
    output wire                                             oerror              // Avalon-ST
    output wire [3:0]                                       ochannel            // Avalon-ST
    output wire                                             ostartofpacket,     // Avalon-ST
    output wire                                             oendofpacket        // Avalon-ST
    );

    // Write_FSM reg
    reg [pFSM_WRITE_BUS-1:0]           rWR_state      = 2'b00;              
    reg [pFSM_WRITE_BUS-1:0]           rWR_state_next = 2'b01;      

    // Read pointers and counter
    reg [$clog2(pDEPTH_RAM)-1:0]       rRd_ptr_succ = '0;           // Last successfull pointer            
    reg [$clog2(pDEPTH_RAM)-1:0]       rRd_ptr_now  = '0;


    reg [$clog2(pDEPTH_RAM)-1:0]       rRd_count    = '0;     

    // Write pointers and counter
    reg [$clog2(pDEPTH_RAM)-1:0]       rWr_ptr_succ = '0;           // Last successfull pointer
    reg [$clog2(pDEPTH_RAM)-1:0]       rWr_ptr_now  = '0;
    reg [$clog2(pDEPTH_RAM)-1:0]       rWr_count    = '0;
    reg                                rWr_en       = '0;

    // Memory contol registers
    reg                                             rfifo_rd_en_out = 'b0;
    reg                                             rfifo_rd_en_read = 'b0;
    reg                                             rfifo_wr_en = 'b0;
    reg [pFIFO_DEPTH+$clog2(pDEPTH_RAM)+
         $clog2(pMAC_MEM_DEPTH)-1:0]                rgeneralfifo_d     = 'b0;
    

    reg [2:0]                                       rpacda_count;

    fifo                                                                                // FIFO Module
    #(                                                                                  // ===========
        .pBITS                  (pFIFO_WIDTH),                                          // Contains lenght of received packet, 
        .pWIDHT                 (pFIFO_DEPTH+$clog2(pDEPTH_RAM)+
                                 $clog2(pMAC_MEM_DEPTH))                                // that lenght summed with last successful 
    ) memory_to_out                                                                     // read pointer gives us information about
    (                                                                                   // end of packet.
        .iclk                   (iclk),
        .ireset                 (i_rst),
        .ird                    (rfifo_rd_en_out),                 
        .iwr                    (rfifo_wr_en),              
        .iw_data                (rgeneralfifo_d),                  
        .oempty                 (oempty_fifo),
        .ofull                  (ofull_fifo),
        .or_data                ({olen_plus_ptr,oda})
    );

    fifo                                                                                // FIFO Module
    #(                                                                                  // ===========
        .pBITS                  (pFIFO_WIDTH),                                          // Contains lenght of received packet, 
        .pWIDHT                 (pFIFO_DEPTH+$clog2(pDEPTH_RAM))                        // that lenght summed with last successful 
    ) memory_for_reading                                                                // read pointer gives us information about
    (                                                                                   // end of packet.
        .iclk                   (iclk),
        .ireset                 (i_rst),
        .ird                    (rfifo_rd_en_read),                 
        .iwr                    (rfifo_wr_en),              
        .iw_data                (rgeneralfifo_d[pFIFO_DEPTH+$clog2(pDEPTH_RAM)+
                                                $clog2(pMAC_MEM_DEPTH)-1:$clog2(pMAC_MEM_DEPTH)]),                  
        .oempty                 (),                             /// ????? 
        .ofull                  (),                             /// ????? 
        .or_data                ()                              /// ????? 
    );

    sram                                                            // SRAM Module
    #(                                                              // ===========
        .DATA_WIDTH             (pDATA_WIDTH),                      // Memory module. Input packets are saved in
        .DEPTH                  (pDEPTH_RAM)                        // it.
    ) ram_for_packets
    (
        .i_clk                  (iclk),
        .i_addr_wr              (rWr_ptr_now),
        .i_addr_r               (rRd_ptr_now), 
        .i_write                (rWr_en),
        .i_data                 (irx_d),
        .o_data                 (or_data)
    );

    // Write_data 
    always @(posedge iclk) begin 
        case(rWR_state)
            lpWAIT: begin                 
                if (idv & (iframe_state == lpSFD) & !irx_er) begin
                    rWR_state <= rWR_state_next;
                    rWr_en    <= 1'b1;
                end   
                rWr_ptr_now <= rWr_ptr_succ;    
            end
            lpWRITE: begin                 
                if (irx_er) begin
                    rWR_state <= lpWAIT;
                end
                else if (idv == 'b0) begin 
                    rWR_state <= rWR_state_next;
                    rWr_en    <=1'b0;
                end
                else begin
                    if ((rWr_ptr_now + 'b1) > pDEPTH_RAM) begin
                        rWr_count    <= rWr_count + 'd1;
                        rWr_ptr_now  <= 'd0;
                        rWr_ptr_succ <= 'd0;
                    end
                    else begin
                        rWr_count   <= rWr_count + 'd1;
                        rWr_ptr_now <= rWr_ptr_now + 'd1;   
                    end
                end
            end
            lpCHECK_CRC: begin                
                if (irx_er == 1'b1) begin
                    rWR_state <= rWR_state_next;
                end
                else begin
                    if(rfifo_wr_en) begin
                        rfifo_wr_en  <= 1'b0;
                        rWr_count    <= 'd0;
                        rWR_state    <= rWR_state_next;
                        rWr_ptr_succ <= rWr_ptr_now;
                    end
                    else begin
                        rfifo_wr_en <= 1'b1;
                        rgeneralfifo_d[pFIFO_DEPTH+$clog2(pDEPTH_RAM)+$clog2(pMAC_MEM_DEPTH)-1:
                                       $clog2(pMAC_MEM_DEPTH)]                                  <= {rWr_count,rWr_ptr_now};
                    end
                end
            end
        endcase
    end

    always @* begin
        case(rWR_state)
            lpWAIT     :  rWR_state_next = lpWRITE;
            lpWRITE    :  rWR_state_next = lpCHECK_CRC;
            lpCHECK_CRC:  rWR_state_next = lpWAIT;
        endcase
    end

    // Read data to Avalon-ST
    always @(posedge iclk) begin
        if(iready) begin
            
        end
        else begin
            
        end
    end

    // read DA function
    always @(posedge iclk) begin
        if (iframe_state = lpDA) begin
            if (rpacda_count == 3'd1)      rgeneralfifo_d[$clog2(pMAC_MEM_DEPTH)-1:8]] <= irx_d[5:0];
            else if (rpacda_count == 3'd0) rgeneralfifo_d[7:0]  <= ird;
            else                           rpacda_count <= rpacda_count - 1;
        end
        else rpacda_count <= 3'd5;
    end

    // Show data to out for pre_arb
    

    // Read and write pointers check
    assign ofull_sram = (((rWr_ptr_succ > rRd_ptr_succ) ? 
                          (rWr_ptr_succ - rRd_ptr_succ) : 
                          (rRd_ptr_succ - rWr_ptr_succ)) > pMAX_PACKET_LENGHT) ? 1'b1 : 1'b0;
    assign oempty_sram = (rWr_ptr_succ == rRd_ptr_succ) ?  1'b1 : 1'b0;
    

endmodule
 