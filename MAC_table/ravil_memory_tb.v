module ravil_memory_tb();

    wire [7:0] wgmii_data;
    wire wgmii_rx_val;
    
    reg iclk;
    reg enable;
    reg reset;

    wire [2:0]  o_fsm_state;
    wire        o_fsm_state_ch;
    wire        o_rx_dv_4cd;
    wire [7:0]  o_rx_d4cd;
    wire        o_FR_error;
    wire [1:0]   o_number;

    reg [1:0]   r_port_num;

    pcap2gmii
    #(
        .pPCAP_FILENAME     ("test.pcap") 
    ) 
        genpack
    (
        .iclk           (iclk),
        .ipause         (1'b0),
        .oval           (wgmii_rx_val),
        .odata          (wgmii_data),
        .opkt_cnt       ()
    );

    frame_receiver
    module_1 
    (
        .iclk               	(iclk),
        .irx_dv                 (wgmii_rx_val),
        .irx_er                 (reset),
        .irx_data               (wgmii_data),
        .o_state                (o_fsm_state),
        .o_change               (o_fsm_state_ch),
        .o_dv                   (o_rx_dv_4cd),
        .o_data                 (o_rx_d4cd),
        .o_error                (o_FR_error)        
    );   

    MAC_memory
    DUT
    (
        .iclk                   (iclk),
        .i_port_num             (r_port_num),
        .irx_d                  (o_rx_d4cd),
        .iFSM_state             (o_fsm_state),
        .i_dv                   (o_rx_dv_4cd),
        .o_port_num             (o_number)
        );
    
    always #1
    begin
        iclk = ~iclk;
    end

    always @(posedge iclk) $display(o_fsm_state);

    initial
    begin
       iclk = 0;
       enable = 1;
       reset = 0;
       r_port_num=2'b00;
       #1500
       reset = 1;
       #2
       reset = 0;
    end   

    always @(negedge o_rx_dv_4cd) begin
    if (r_port_num==2'b11)
        r_port_num<=2'b00;
    r_port_num<=r_port_num+1;
    end
        
    initial begin
        #70000 $finish;
    end
    
endmodule