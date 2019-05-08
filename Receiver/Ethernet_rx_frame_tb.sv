module Ethernet_rx_frame_tb();

    wire [7:0] wgmii_data;
    wire wgmii_rx_val;
    
    reg iclk;
    reg enable;
    reg reset;
    reg r_inv_enable;

    wire [2:0]  o_fsm_state;
    wire        o_fsm_state_ch;
    wire        o_rx_dv_4cd;
    wire        o_rx_er_4cd;
    wire [7:0]  o_rx_d4cd;


    wire [2:0]  o_fsm_state2;
    wire        o_fsm_state_ch2;
    wire        o_rx_dv_4cd2;
    wire        o_rx_er_4cd2;
    wire [7:0]  o_rx_d4cd2;

    wire [7:0]  wgmii_data_inv;
    
    pcap2gmii
    #(
        .pPCAP_FILENAME     ("1111.pcap") 
    ) 
        genpack
    (
        .iclk           (iclk),
        .ipause         (1'b0),
        .oval           (wgmii_rx_val),
        .odata          (wgmii_data),
        .opkt_cnt       ()
    );

    //Ethernet_RX_Frame_analyzer_4cd
    //DUT
    //(
    //    .i_rx_clk               (iclk),
    //    .i_rx_dv                (wgmii_rx_val),
    //    .i_rx_er                (reset),
    //    .i_rx_d                 (wgmii_data),
    //    .o_fsm_state            (o_fsm_state),
    //    .o_fsm_state_changed    (o_fsm_state_ch),
    //    .o_rx_dv_4cd            (o_rx_dv_4cd),
    //    .o_rx_er_4cd            (o_rx_er_4cd),
    //    .o_rx_d4cd              (o_rx_d4cd)
    //);   

    Ethernet_RX_frame_5cd
    DUT5cd
    (
        .i_rx_clk               (iclk),
        .i_rx_dv                (wgmii_rx_val),
        .i_rx_er                (reset),
        .i_rx_d                 (wgmii_data_inv),
        .o_fsm_state            (o_fsm_state2),
        .o_fsm_state_changed    (o_fsm_state_ch2),
        .o_rx_dv_4cd            (o_rx_dv_4cd2),
        .o_rx_er_4cd            (o_rx_er_4cd2),
        .o_rx_d4cd              (o_rx_d4cd2)
    );

    inverse_data #( .pDATA_WIDTH (8)) data_inv
    ( 
        .idata                  (wgmii_data),  
        .ienable                (r_inv_enable),
        .odata                  (wgmii_data_inv) 
    );
    
    always #1
    begin
        iclk = ~iclk;
    end
    

    always @(posedge iclk) $display(o_fsm_state);

    initial
    begin
       iclk = 0;
       r_inv_enable = 0;
       enable = 1;
       reset = 0;
       #600 r_inv_enable = 1;
       #4   r_inv_enable = 0;
       #1500
       reset = 1;
       #20
       reset = 0;
    end    


    initial begin
        #5000 $finish;
    end
endmodule