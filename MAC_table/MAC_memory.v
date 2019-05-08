`include "header.v"

module MAC_memory
    (
        input wire                              iclk,
        input wire [pMAX_PORT_NUMBER-1:0]       i_newSA,
        input wire [$clog2(pSLOTS)-1:0]         irx_SA,
        output reg [pMAX_PORT_NUMBER-1:0]       o_port_num,
        output reg [pMAX_PORT_NUMBER-1:0]       o_show_SA,
        output reg                              o_write_en
    );

    //reg [pADRESS-1:0]                       r_port_num [pSLOTS-1:0] ='{default: 'b0};
    //reg [pTIME-1:0]                         r_time [pSLOTS-1:0] ='{default: 'd300};
   

    //reg [$clog2(pSLOTS)-1:0]                r_d_counter='0; 
    //reg [$clog2(pONE_SECOND)-1:0]           r_FBC='0;
    reg [pADRESS-1:0]                       r_working_port = '0;



    /*always @(posedge iclk) begin
    if (r_FBC==15'd32768) 
       r_FBC<=0;
    r_FBC<=r_FBC+1;
    end*/


    always @(posedge iclk) begin
    if (i_newSA [r_working_port] == 1) begin
        o_port_num<=r_working_port;
        o_show_SA [r_working_port] <= 1;
        o_write_en<=1;
        else o_write_en<=0;
        end
    if (r_working_port==2'b11) 
        r_working_port<=2'b00;
    else r_working_port<=r_working_port+1;
    end

    
    /*always @(posedge iclk) begin                        //Getting MAC adress
        if ((iFSM_state!==lpNO_FRAME)&(iFSM_state!==lpPREAMBLE)&(iFSM_state!==lpFCS)) 
            r_counter_len<=r_counter_len+1;       
        if ((iFSM_state==lpSA)|(iFSM_state==lpLENGTH)|(iFSM_state==lpDATA)) begin 
        case (r_counter_len)
        'd11: r_MAC_higher<=irx_d [5:0];    //write Adress
        'd12: r_MAC_lower<=irx_d;
        'd13: r_adress<={r_MAC_higher,r_MAC_lower};
        'd14: r_write_en<=1'b1;
        'd15: begin
                r_write_en<=1'b0;
                r_read_adress<=r_adress;
                end
        endcase
        end
        if (iFSM_state==lpFCS) 
            r_counter_len<='0;
        end*/

    /*always @(posedge iclk) begin 
        if (r_write_en) begin
            r_port_num[r_adress] <= i_port_num;
            r_time[r_adress] <= 9'd300;
        end
        else if  (r_FBC > 'd16383) begin
            r_d_counter<=r_d_counter+1;
            r_time[r_d_counter]<=r_time[r_d_counter]-1;
        end
        o_port_num<=r_port_num[r_read_adress];
        end*/

    endmodule

//Секудный таймер на PSP

    