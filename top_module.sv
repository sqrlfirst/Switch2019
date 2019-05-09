`include "header.v"

module top_module
(
        input wire          iclk,                       // General clock
        
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
    wire                            MAC_table_port_num;

Ethernet_rx_frame GMII0 
(
    .i_rx_clk               (i_rx_clk_0),
    .i_rx_dv                (i_rx_dv_0),
    .i_rx_er                (i_rx_er_0),
    .i_rx_d                 (i_rx_d_0),
    .ishowSA                (wshowSA[0]),
    .o_fsm_state            (o_fsm_state_0),
    .o_fsm_state_changed    (o_fsm_state_changed_0),
    .o_rx_dv_4cd            (o_rx_dv_4cd_0),
    .o_rx_er_4cd            (o_rx_er_4cd_0),
    .o_rx_d4cd              (o_rx_d4cd_0),
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
    .o_fsm_state            (o_fsm_state_1),
    .o_fsm_state_changed    (o_fsm_state_changed_1),
    .o_rx_dv_4cd            (o_rx_dv_4cd_1),
    .o_rx_er_4cd            (o_rx_er_4cd_1),
    .o_rx_d4cd              (o_rx_d4cd_1),
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
    .o_fsm_state            (o_fsm_state_2),
    .o_fsm_state_changed    (o_fsm_state_changed_2),
    .o_rx_dv_4cd            (o_rx_dv_4cd_2),
    .o_rx_er_4cd            (o_rx_er_4cd_2),
    .o_rx_d4cd              (o_rx_d4cd_2),
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
    .o_fsm_state            (o_fsm_state_3),
    .o_fsm_state_changed    (o_fsm_state_changed_3),
    .o_rx_dv_4cd            (o_rx_dv_4cd_3),
    .o_rx_er_4cd            (o_rx_er_4cd_3),
    .o_rx_d4cd              (o_rx_d4cd_3),
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
.i_MAC_DA           (),
.o_port_num         (MAC_table_port_num)
);
endmodule