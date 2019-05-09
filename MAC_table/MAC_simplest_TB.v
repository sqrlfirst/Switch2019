`include "header.v"

module MAC_simplest_tb();

reg                               clock='0;
reg                               write_enable='0;
reg [pADRESS-1:0]                 port_num='0;;
reg [13:0]                        SA='0;
reg [13:0]                        DA='0;
wire [pADRESS-1:0]                PORT_NUM;

MAC_table
TABLE
(
 .iclk              (clock),
 .i_write_enable    (write_enable),
 .i_port_num        (port_num),
 .i_MAC_SA          (SA),
 .i_MAC_DA          (DA),
 .o_port_num        (PORT_NUM)
);

always #1
    begin
        clock = ~clock;
    end

always #19
    begin
        write_enable = ~write_enable;
    end

always #20
    begin
    if (port_num==2'b11)
        port_num<=2'b00;
    port_num<=port_num+1;;
    end

   always #21
    begin
    if (port_num==2'b11)
        port_num<=2'b00;
    SA<=SA+1;;
    end 

    always #22
    begin
    DA<=DA+1;;
    end 

 initial begin
        #70000 $finish;
    end

    endmodule

