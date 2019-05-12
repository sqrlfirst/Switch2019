`include "header.v"

module receiver_arb_mac_tb;

    reg                         iclk;
    wire [7:0]                  wgmii_data;
    wire                        wgmii_rx_val;
    reg                         rrx_er0='0;

    wire [3:0]                  wshowSA;
    wire [2:0]                  wfsm_state0;
    wire                        w_fsm_state_changed_0;
    wire                        wdv0;
    wire                        wrx_er0;
    wire [7:0]                  wrx_d0;
    wire [13:0]                 wosa;
    wire                        wnewSA;

    wire [$clog2(pPORT_NUM)-1:0]                        wport_num;
    wire                                                wwr_en;

    reg [13:0]                                          i_MAC_DA='0;
    wire [$clog2(pPORT_NUM)-1:0]                        oMAC_table_port_num_0;
    wire [$clog2(pPORT_NUM)-1:0]                        oMAC_table_port_num_1;
    wire [$clog2(pPORT_NUM)-1:0]                        oMAC_table_port_num_2;
    wire [$clog2(pPORT_NUM)-1:0]                        oMAC_table_port_num_3;

    Ethernet_rx_frame GMII0 
    (
        .i_rx_clk               (iclk),                     // CON
        .i_rx_dv                (wgmii_rx_val),             // CON
        .i_rx_er                (rrx_er0),                  // CON
        .i_rx_d                 (wgmii_data),               // CON
        .ishowSA                (wshowSA[0]),               // CON
        .o_fsm_state            (wfsm_state0),              // CON
        .o_fsm_state_changed    (w_fsm_state_changed_0),
        .o_rx_dv_4cd            (wdv0),
        .o_rx_er_4cd            (wrx_er0),
        .o_rx_d4cd              (wrx_d0),
        .osa                    (wosa),
        .onewsa                 (wnewSA)
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
        .o_port_num_0       (oMAC_table_port_num_0),
        .o_port_num_1       (oMAC_table_port_num_1),
        .o_port_num_2       (oMAC_table_port_num_2),
        .o_port_num_3       (oMAC_table_port_num_3)
    );

    always #1
    begin
        iclk = ~iclk;
    end

    initial
    begin
       iclk = 0;
    end

endmodule
