`include "header.v"

module MAC_arbiter
    (
        input wire                              iclk,
        input wire [pMAX_PORT_NUMBER-1:0]       i_newSA,
        output reg [pADRESS-1:0]                o_port_num,
        output reg [pMAX_PORT_NUMBER-1:0]       o_show_SA,
        output reg                              o_write_en
    );

    reg [pADRESS-1:0]                       r_working_port = '0;

    always @(posedge iclk) begin
    if (i_newSA [r_working_port] == 1) begin
        o_port_num<=r_working_port;
        o_show_SA [r_working_port] <= 1;
        o_write_en<=1;
        end
        else o_write_en<=0;
    if (r_working_port==2'b11)
        r_working_port<=2'b00;
    r_working_port<=r_working_port+1;
    end

 
 endmodule

    