`include "header.v"

module MAC_table
    (
        input wire                                  iclk,
        input wire                                  i_write_enable,
        input wire [$clog2(pPORT_NUM)-1:0]          i_port_num,
        input wire [$clog2(pMAC_MEM_DEPTH)-1:0]     i_MAC_SA,
        input wire [$clog2(pMAC_MEM_DEPTH)-1:0]     i_MAC_DA,
        output reg [$clog2(pPORT_NUM)-1:0]          o_port_num
    );

    //Memory registers
    reg [$clog2(pPORT_NUM)-1:0]                       r_port_num [pSLOTS-1:0] = '{default: 'b0};
    reg [pTIME-1:0]                                   r_time [pSLOTS-1:0] = '{default: 'd300};

    //Registers for counter
    reg [$clog2(pMAC_MEM_DEPTH)-1:0]                r_d_counter = '0; 
    reg [$clog2(pONE_SECOND)-1:0]           r_FBC = '0;

    always @(posedge iclk) begin
        if (r_FBC==15'd32768) r_FBC <= 0;
        r_FBC <= r_FBC+1;
    end

    always @(posedge iclk) begin //Write MAC
        if (i_write_enable) begin
            r_port_num[i_MAC_SA] <= i_port_num;
            r_time[i_MAC_SA] <= 9'd300;
        end
        else if  (r_FBC > 'd16383) begin
            r_d_counter <= r_d_counter+1;
            r_time[r_d_counter] <= r_time[r_d_counter]-1;
        end
        o_port_num <= r_port_num[i_MAC_DA]; //Read MAC
    end

endmodule
    