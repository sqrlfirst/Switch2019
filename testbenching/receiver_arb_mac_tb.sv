module receiver_arb_mac_tb;

    reg                         iclk;
    wire [7:0]                  wgmii_data;
    wire                        wgmii_rx_val;
    reg                         rrx_er0;

    wire [3:0]                  wshowSA;
    wire [2:0]                  wfsm_state0;
    wire

    Ethernet_rx_frame GMII0 
    (
        .i_rx_clk               (iclk),                     // CON
        .i_rx_dv                (wgmii_rx_val),             // CON
        .i_rx_er                (rrx_er_0),                 // CON
        .i_rx_d                 (wgmii_data),               // CON
        .ishowSA                (wshowSA[0]),               // CON
        .o_fsm_state            (wfsm_state0),              // CON
        .o_fsm_state_changed    (o_fsm_state_changed_0),
        .o_rx_dv_4cd            (wdv0),
        .o_rx_er_4cd            (wrx_er0),
        .o_rx_d4cd              (wrx_d0),
        .osa                    (wosa),
        .onewsa                 (wnewSA[0])
    );

    pcap2gmii
    #(
        .pPCAP_FILENAME     ("1111.pcap") 
    ) 
        genpack
    (
        .iclk           (iclk),                     // CON
        .ipause         (1'b0),
        .oval           (wgmii_rx_val),             // CON
        .odata          (wgmii_data),               // CON
        .opkt_cnt       ()
    );

    MAC_arbiter sa_arbiter
    (
        .iclk                   (iclk),             // CON
        .i_newSA                (wnewSA),
        .o_port_num             (wport_num),
        .o_show_SA              (wshowSA),          // CON
        .o_write_en             (wwr_en)
    );

    MAC_table MAC_table
    (
        .iclk               (iclk),
        .i_write_enable     (wwr_en),
        .i_port_num         (wport_num),
        .i_MAC_SA           (wosa),
        .i_MAC_DA           (i_MAC_DA),
        .o_port_num         (oMAC_table_port_num)
    );


    reg [2:0]               rSA_const = 'b0;

    assign wnewSA[3:1] = rSA_const;              // just const for some values

endmodule
