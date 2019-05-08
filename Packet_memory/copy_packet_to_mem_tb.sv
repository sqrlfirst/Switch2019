`include "project_header.v"

module copy_packet_to_mem 
    #(
        parameter pDATA_WIDTH        = 8,                     
                  pMIN_PACKET_LENGHT = 64,
                  pMAX_PACKET_LENGHT = 1536,
                  pFIFO_WIDTH        = $clog2(pMAX_PACKET_LENGHT),
                  pDEPTH_RAM         = 2*pMAX_PACKET_LENGHT,
                  pFIFO_DEPTH        = pDEPTH_RAM/pMIN_PACKET_LENGHT 
    )
    (
    input wire                              iclk,
    input wire                              i_rst,
    input wire                              idv,
    input wire [pDATA_WIDTH-1:0]            irx_d,
    input wire                              irx_er,
    input wire [pFSM_BUS_WIDHT-1:0]         iframe_state,

    input wire                              ird_en,
    input wire                              imem_ptr,               // add pointer to mem RB

    output wire                             oempty,
    output wire                             ofull,
    output wire [pDATA_WIDTH-1:0]           or_data,

    output wire [pFIFO_WIDTH-1:0]           olen_pac, 
    output reg                              onext_last,
    output wire [$clog2(pDEPTH_RAM)-1:0]    obytes_to_read,

    output wire                             ofifo_em,
    output wire                             ofifo_full
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
    reg                                rfifo_rd_en = 'b0;
    reg                                rfifo_wr_en = 'b0;
    reg [pFIFO_WIDTH-1:0]              rfifo_d     = 'b0;
    reg                                rfifo_empty;
    reg                                rfifo_full;

    fifo                                                            // FIFO Module
    #(                                                              // ===========
        .pBITS                  (pFIFO_WIDTH),                      // Contains lenght of received packet, 
        .pWIDHT                 (pFIFO_DEPTH)                       // that lenght summed with last successful 
    ) lenght_of_packet                                              // read pointer gives us information about
    (                                                               // end of packet.
        .iclk                   (iclk),
        .ireset                 (i_rst),
        .ird                    (rfifo_rd_en),                 
        .iwr                    (rfifo_wr_en),              
        .iw_data                (rfifo_d),                  
        .oempty                 (rfifo_empty),
        .ofull                  (rfifo_full),
        .or_data                (olen_pac)
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
                    rWr_en <= 1'b1;
                end   
                rWr_ptr_now <= rWr_ptr_succ;    
            end
            lpWRITE: begin                 
                if (irx_er) begin
                    rWR_state <= lpWAIT;
                end
                else if (idv == 'b0) begin 
                    rWR_state <= rWR_state_next;
                    rWr_en <=1'b0;
                end
                else begin
                    if ((rWr_ptr_now + 'b1) > pDEPTH_RAM) begin
                        rWr_count <= rWr_count + 'd1;
                        rWr_ptr_now <= 'd0;
                        rWr_ptr_succ <= 'd0;
                    end
                    else begin
                        rWr_count <= rWr_count + 'd1;
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
                        rfifo_wr_en <= 1'b0;
                        rWr_count <= 'd0;
                        rWR_state <= rWR_state_next;
                        rWr_ptr_succ <= rWr_ptr_now;
                    end
                    else begin
                        rfifo_wr_en <= 1'b1;
                        rfifo_d <= rWr_count;
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

    // Read data
    always @(posedge iclk) begin
        if (ird_en) begin 
            if (rRd_count != 'b0) begin
                if ((rWr_ptr_now + 'b1) > pDEPTH_RAM) begin
                    rRd_count <= rRd_count - 'b1;
                    rRd_ptr_now <= 'b0;
                    rRd_ptr_succ <= 'd0;
                end
                else begin
                    rRd_count <= rRd_count - 'b1;
                    rRd_ptr_now <= rRd_ptr_now + 'b1;    
                end
                rfifo_rd_en <= 'b0;
            end
            else begin
                rRd_count <= olen_pac + 1'b1;
                rfifo_rd_en <= 'b1;
            end
        end
        else begin
            rRd_count <= 'b0;
            rRd_ptr_succ <= rRd_ptr_now;
        end
    end

    // next last
    always @(posedge iclk) begin
        if (rRd_count == 'b10) onext_last <= 1'b1;
        else onext_last <= 1'b0;
    end 

    // Read and write pointers check
    assign ofull = (((rWr_ptr_succ > rRd_ptr_succ) ? 
                     (rWr_ptr_succ - rRd_ptr_succ) : 
                     (rRd_ptr_succ - rWr_ptr_succ)) > pMAX_PACKET_LENGHT) ? 1'b1 : 1'b0;
    assign oempty = (rWr_ptr_succ == rRd_ptr_succ) ?  1'b1 : 1'b0;
    // read_counter_output
    assign obytes_to_read = rRd_count;
    // Inner fifo flags // may removed after testing
    assign ofifo_em   = rfifo_empty;
    assign ofifo_full = rfifo_full;

endmodule
