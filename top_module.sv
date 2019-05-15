`include "header.v"

module top_module
    (
        input wire          iclk,                       // General clock
        input wire [$clog2(pMAC_MEM_DEPTH)-1:0]         i_MAC_DA,
        output wire         oMAC_table_port_num;

        input wire          i_rx_clk_0,    // GMII0 
        input wire          i_rx_dv_0,     // GMII0
        input wire          i_rx_er_0,     // GMII0 
        input wire  [7:0]   i_rx_d_0,      // GMII0
        output wire [2:0]   o_fsm_state_0,
        output reg          o_fsm_state_changed_0 = 0,

        output wire         o_rx_dv_4cd_0,
        output wire         o_rx_er_4cd_0,
        output wire [7:0]   o_rx_d4cd_0,
        
        input wire          i_rx_clk_1,    // GMII1 
        input wire          i_rx_dv_1,     // GMII1
        input wire          i_rx_er_1,     // GMII1 
        input wire  [7:0]   i_rx_d_1,      // GMII1
        output wire [2:0]   o_fsm_state_1,
        output reg          o_fsm_state_changed_1 = 0,
    
        output wire         o_rx_dv_4cd_1,
        output wire         o_rx_er_4cd_1,
        output wire [7:0]   o_rx_d4cd_1,

        input wire          i_rx_clk_2,    // GMII2 
        input wire          i_rx_dv_2,     // GMII2
        input wire          i_rx_er_2,     // GMII2 
        input wire  [7:0]   i_rx_d_2,      // GMII2
        output wire [2:0]   o_fsm_state_2,
        output reg          o_fsm_state_changed_2 = 0,
    
        output wire         o_rx_dv_4cd_2,
        output wire         o_rx_er_4cd_2,
        output wire [7:0]   o_rx_d4cd_2,
        
        input wire          i_rx_clk_3,    // GMII3 
        input wire          i_rx_dv_3,     // GMII3
        input wire          i_rx_er_3,     // GMII3 
        input wire  [7:0]   i_rx_d_3,      // GMII3
        output wire [2:0]   o_fsm_state_3,
        output reg          o_fsm_state_changed_3 = 0,//тут объявлять надо???
    
        output wire         o_rx_dv_4cd_3,
        output wire         o_rx_er_4cd_3,
        output wire [7:0]   o_rx_d4cd_3
    );

    // wires for MAC_arb SA
    wire [pPORT_NUM-1:0]            wnewSA;
    wire [pPORT_NUM-1:0]            wshowSA;
    wire [$clog2(pPORT_NUM)-1:0]    wport_num;
    wire                            wwr_en;
    wire [13:0]                     wosa;
    // wires for out of Ethrenet to mem 0     
    wire                            wdv0;      
    wire [7:0]                      wrx_d0;     
    wire                            wrx_er0;
    wire [2:0]                      wfsm_state0;    
    // wires for out of Ethrenet to mem 1     
    wire                            wdv1;      
    wire [7:0]                      wrx_d1;     
    wire                            wrx_er1;
    wire [2:0]                      wfsm_state1;
    // wires for out of Ethrenet to mem 2     
    wire                            wdv2;      
    wire [7:0]                      wrx_d2;     
    wire                            wrx_er2;
    wire [2:0]                      wfsm_state2;
    // wires for out of Ethrenet to mem 3     
    wire                            wdv3;      
    wire [7:0]                      wrx_d3;     
    wire                            wrx_er3;
    wire [2:0]                      wfsm_state3;    

    Ethernet_rx_frame GMII0 
    (
        .i_rx_clk               (i_rx_clk_0),
        .i_rx_dv                (i_rx_dv_0),
        .i_rx_er                (i_rx_er_0),
        .i_rx_d                 (i_rx_d_0),
        .ishowSA                (wshowSA[0]),
        .o_fsm_state            (wfsm_state0),
        .o_fsm_state_changed    (o_fsm_state_changed_0),
        .o_rx_dv_4cd            (wdv0),
        .o_rx_er_4cd            (wrx_er0),
        .o_rx_d4cd              (wrx_d0),
        .osa                    (wosa),
        .onewsa                 (wnewSA[0])
    );

    Ethernet_rx_frame GMII1 
    (
        .i_rx_clk               (i_rx_clk_1),
        .i_rx_dv                (i_rx_dv_1),
        .i_rx_er                (i_rx_er_1),
        .i_rx_d                 (i_rx_d_1),
        .ishowSA                (wshowSA[1]),
        .o_fsm_state            (wfsm_state1),
        .o_fsm_state_changed    (o_fsm_state_changed_1),
        .o_rx_dv_4cd            (wdv1),
        .o_rx_er_4cd            (wrx_er1),
        .o_rx_d4cd              (wrx_d1),
        .osa                    (wosa),
        .onewsa                 (wnewSA[1])
    );

    Ethernet_rx_frame GMII2 
    (
        .i_rx_clk               (i_rx_clk_2),
        .i_rx_dv                (i_rx_dv_2),
        .i_rx_er                (i_rx_er_2),
        .i_rx_d                 (i_rx_d_2),
        .ishowSA                (wshowSA[2]),
        .o_fsm_state            (wfsm_state2),
        .o_fsm_state_changed    (o_fsm_state_changed_2),
        .o_rx_dv_4cd            (wdv2),
        .o_rx_er_4cd            (wrx_er2),
        .o_rx_d4cd              (wrx_d2),
        .osa                    (wosa),
        .onewsa                 (wnewSA[2])
    );

    Ethernet_rx_frame GMII3 
    (
        .i_rx_clk               (i_rx_clk_3),
        .i_rx_dv                (i_rx_dv_3),
        .i_rx_er                (i_rx_er_3),
        .i_rx_d                 (i_rx_d_3),
        .ishowSA                (wshowSA[3]),
        .o_fsm_state            (wfsm_state3),
        .o_fsm_state_changed    (o_fsm_state_changed_3),
        .o_rx_dv_4cd            (wdv3),
        .o_rx_er_4cd            (wrx_er3),
        .o_rx_d4cd              (wrx_d3),
        .osa                    (wosa),
        .onewsa                 (wnewSA[3])
    );

    MAC_arbiter sa_arbiter
    (
        .iclk                   (iclk),
        .i_newSA                (wnewSA),
        .o_port_num             (wport_num),
        .o_show_SA              (wshowSA),
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

    copy_packet_to_mem mem0 
    (
        .iclk                                (iclk),
        .irst                                (),
        .idv                                 (),
        .irx_d                               (),
        .irx_er                              (),
        .iframe_state                        (),
        .ird_en                              (),              // for pre_arb
        .iready                              (),              // Avalon-ST                                                                // Ended there
        .oempty_sram                         (),
        .ofull_sram                          (),
        .oempty_fifo                         (),
        .ofull_fifo                          (),
        .olen_plus_ptr                       (),
        .oda                                 (),                
        .ovalid                              (),              // Avalon-ST
        .odata                               (),              // Avalon-ST
        .oerror                              (),              // Avalon-ST
        .ochannel                            (),              // Avalon-ST
        .ostartofpacket                      (),              // Avalon-ST
        .oendofpacket                        ()               // Avalon-ST
    );

    copy_packet_to_mem mem1 
    (
        .iclk                                (),
        .irst                                (),
        .idv                                 (),
        .irx_d                               (),
        .irx_er                              (),
        .iframe_state                        (),
        .ird_en                              (),              // for pre_arb
        .iready                              (),              // Avalon-ST                                                                // Ended there
        .oempty_sram                         (),
        .ofull_sram                          (),
        .oempty_fifo                         (),
        .ofull_fifo                          (),
        .olen_plus_ptr                       (),
        .oda                                 (),                
        .ovalid                              (),              // Avalon-ST
        .odata                               (),              // Avalon-ST
        .oerror                              (),              // Avalon-ST
        .ochannel                            (),              // Avalon-ST
        .ostartofpacket                      (),              // Avalon-ST
        .oendofpacket                        ()               // Avalon-ST
    );

    copy_packet_to_mem mem2 
    (
        .iclk                                (),
        .irst                                (),
        .idv                                 (),
        .irx_d                               (),
        .irx_er                              (),
        .iframe_state                        (),
        .ird_en                              (),              // for pre_arb
        .iready                              (),              // Avalon-ST                                                                // Ended there
        .oempty_sram                         (),
        .ofull_sram                          (),
        .oempty_fifo                         (),
        .ofull_fifo                          (),
        .olen_plus_ptr                       (),
        .oda                                 (),                
        .ovalid                              (),              // Avalon-ST
        .odata                               (),              // Avalon-ST
        .oerror                              (),              // Avalon-ST
        .ochannel                            (),              // Avalon-ST
        .ostartofpacket                      (),              // Avalon-ST
        .oendofpacket                        ()               // Avalon-ST
    );

    copy_packet_to_mem mem3 
    (
        .iclk                                (),
        .irst                                (),
        .idv                                 (),
        .irx_d                               (),
        .irx_er                              (),
        .iframe_state                        (),
        .ird_en                              (),              // for pre_arb
        .iready                              (),              // Avalon-ST                                                                // Ended there
        .oempty_sram                         (),
        .ofull_sram                          (),
        .oempty_fifo                         (),
        .ofull_fifo                          (),
        .olen_plus_ptr                       (),
        .oda                                 (),                
        .ovalid                              (),              // Avalon-ST
        .odata                               (),              // Avalon-ST
        .oerror                              (),              // Avalon-ST
        .ochannel                            (),              // Avalon-ST
        .ostartofpacket                      (),              // Avalon-ST
        .oendofpacket                        ()               // Avalon-ST
    );
endmodule