module copy_packet_to_mem_tb;

    reg                     iclk      ;         
    reg                     i_rst     ;
    wire                    wdv       ;
    wire [7:0]              wrx_d     ;         // 7:0
    wire                    wrx_er    ;
    wire [2:0]              wFSM_state;
    reg                     ird_en    = 'b0;
    wire                    oempty         ;
    wire                    ofull          ;
    wire [7:0]                    or_data        ;
    wire [10:0]                   olen_pac       ;
    wire                    onext_last     ;
    wire [11:0]                   obytes_to_read; 
    wire                    ofifo_em   ;   
    wire                    ofifo_full ;    
    
    
       

    copy_packet_to_mem 
    #(
        .pDATA_WIDTH                  (8),                     
        .pMIN_PACKET_LENGHT           (64), 
        .pMAX_PACKET_LENGHT           (1536), 
        .pFIFO_WIDTH                  (), 
        .pDEPTH_RAM                   (), 
        .pFIFO_DEPTH                  () 
    ) DUT
    (
        .iclk                   (iclk),
        .i_rst                  (i_rst),
        .idv                    (wdv),
        .irx_d                  (wrx_d),
        .irx_er                 (wrx_er),
        .iframe_state           (wFSM_state),
        .ird_en                 (ird_en),
        .oempty                 (oempty),
        .ofull                  (ofull),
        .or_data                (or_data),
        .olen_pac               (olen_pac), 
        .onext_last             (onext_last),
        .obytes_to_read         (obytes_to_read),
        .ofifo_em               (ofifo_em),
        .ofifo_full             (ofifo_full)
    );

    Ethernet_frame_analyzer_tb_w_io
    helping_stick
    (
        .iclk                   (iclk), 
        .o_fsm_state            (wFSM_state),
        .o_rx_data              (wrx_d),
        .o_rx_er                (wrx_er),
        .o_rx_dv                (wdv)
    );

    always begin 
        #1 iclk = ~iclk;
    end 

    initial begin
        iclk = 0;
        i_rst = 1; 
        #1 i_rst = 0;
        #1500 ird_en = 1; 
        
    end 

    always @(negedge onext_last) begin
        ird_en = 0;
    end
    // always begin
    //     if (onext_last == 1) ird_en = 0;
    // end
    initial begin
        #5000 $finish;
    end

endmodule