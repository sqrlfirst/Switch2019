`define NULL 0

// Engineer:	Chris Shucksmith
// Description:
//	Utility to replay a packets from a pcap file over a single-byte bus
//  for use in network handling test benches.
//    http://wiki.wireshark.org/Development/LibpcapFileFormat

module pcap2gmii
#(
    parameter       pPCAP_FILENAME   = "none",
    parameter int   pIPG_LENGTH      = 12,
    parameter int   pPREAMBLE_LENGTH = 7
)
(
    input           iclk        ,
    input  bit      ipause      ,
    output bit      oval        ,
    output bit [7:0]odata       ,
    output bit [7:0]opkt_cnt
);

`include "crc.v"

// buffers for message
bit [7:0]  rglobal_header [0:23];
bit [7:0]  rpacket_header [0:15];

bit [7:0]  rdata;
bit [31:0] rcrc;

//Ethernet CRC32
wire [3:0][7:0] wcrc;
genvar j,k;

generate for (j=0; j < 4; j++)
begin : crc32_mirror_and_xor
    for (k=0; k < 8; k++)
    begin
        assign wcrc[j][k] = ~rcrc[31-j*8-k];
    end
end
endgenerate

bit [1:0] rfcscnt;


integer swapped = 0;
integer toNanos = 0;
integer file = 0;
integer r    = 0;
integer eof  = 0;
integer i    = 0;
integer pktSz  = 0;
integer diskSz = 0;
integer countIPG = 0;
integer countPRE = 0;
integer countFCS = 0;

initial 
begin
    // open pcap file
    if (pPCAP_FILENAME == "none") begin
        $display("pcap filename parameter not set");
        $finish(1);
    end
    
    file = $fopen(pPCAP_FILENAME, "rb");
    if (file == `NULL) begin
        $display("can't read pcap input");
        $finish(1);
    end
    
    // read binary rglobal_header
    // r = $fread(file, rglobal_header);
    r = $fread(rglobal_header,file);
    
    // check magic signature to determine byte ordering
    if (rglobal_header[0] == 8'hD4 && rglobal_header[1] == 8'hC3 && rglobal_header[2] == 8'hB2) begin
        $display(" pcap endian: swapped, ms");
        swapped = 1;
        toNanos = 32'd1000000;
    end else if (rglobal_header[0] == 8'hA1 && rglobal_header[1] == 8'hB2 && rglobal_header[2] == 8'hC3) begin
        $display(" pcap endian: native, ms");
        swapped = 0;
        toNanos = 32'd1000000;
    end else if (rglobal_header[0] == 8'h4D && rglobal_header[1] == 8'h3C && rglobal_header[2] == 8'hb2) begin
        $display(" pcap endian: swapped, nanos");
        swapped = 1;
        toNanos = 32'd1;
    end else if (rglobal_header[0] == 8'hA1 && rglobal_header[1] == 8'hB2 && rglobal_header[2] == 8'h3c) begin
        $display(" pcap endian: native, nanos");
        swapped = 0;
        toNanos = 32'd1;
    end else begin
        $display(" pcap endian: unrecognised format %02x%02x%02x%02x", rglobal_header[0], rglobal_header[1], rglobal_header[2], rglobal_header[3] );
        $finish(1);
    end
end

enum {stIGP, stCHKFILE, stPREAMBLE, stSFD, stDATA, stFCS} rstate = stIGP, rnextstate, rfsm = stIGP;

always_comb 
begin
    case (rstate)
    stIGP       : rnextstate = stCHKFILE    ;
    stCHKFILE   : rnextstate = stPREAMBLE   ;
    stPREAMBLE  : rnextstate = stSFD        ;
    stSFD       : rnextstate = stDATA       ;
    stDATA      : rnextstate = stFCS        ;
    stFCS       : rnextstate = stIGP        ;
    endcase
end

always @(posedge iclk)
begin
    case (rstate)
    stIGP : begin
        if (countIPG > 0)
        begin
            countIPG <= countIPG - 1;
        end
        else
        begin
            eof = $feof(file);
            
            if ((eof == 0) && (ipause == 1'b0))
            begin
                // reload interpacket gap & preamble counters
                countIPG <= (pIPG_LENGTH     -1);
                countPRE <= (pPREAMBLE_LENGTH-1);
                countFCS <= 3;
            
                rstate <= rnextstate;
            end
        end
    end
    stCHKFILE : begin
        //read header
        r   = $fread(rpacket_header, file);
        eof = $feof (file);
        
        if (eof == 0) 
        begin
            if (swapped == 1) begin
                pktSz  = {rpacket_header[11],rpacket_header[10],rpacket_header[9] ,rpacket_header[8] };
                diskSz = {rpacket_header[15],rpacket_header[14],rpacket_header[13],rpacket_header[12]};
            end 
            else 
            begin
                pktSz  = {rpacket_header[ 8],rpacket_header[ 9],rpacket_header[10],rpacket_header[11]};
                diskSz = {rpacket_header[12],rpacket_header[13],rpacket_header[14],rpacket_header[15]};
            end
    
            $display("  packet %0d: incl_length %0d orig_length %0d eof %0d", opkt_cnt, pktSz, diskSz, eof );
            
            opkt_cnt <= opkt_cnt + 1'b1;
            rstate   <= rnextstate;
        end
    end        
    stPREAMBLE : begin
        if (countPRE > 0)
            countPRE <= countPRE - 1;
        else
            rstate <= rnextstate;
    end
    stSFD : begin
        rstate <= rnextstate;
    end
    stDATA : begin
        if (diskSz > 0) diskSz <= diskSz - 1;
        
        rdata <= $fgetc(file);
        eof    = $feof (file);
        
        if ((eof != 0) || (diskSz == 1)) rstate <= rnextstate;
    end
    stFCS : begin
        if (countFCS > 0)
            countFCS <= countFCS - 1;
        else
            rstate <= rnextstate;
    end
    endcase
    
    //copy state to FSM
    rfsm    <= rstate;
        
    case (rfsm)
    stIGP : begin
        odata <=  'b0;
        oval  <= 1'b0;
    end
    stPREAMBLE : begin
        odata <= 8'h55;
        oval  <= 1'b1;
    end
    stSFD : begin
        odata   <= 8'hD5;
        oval    <= 1'b1;
        rcrc    <=  '1;
        rfcscnt <=  'b0;
    end
    stDATA : begin
        odata <= rdata;
        oval  <= 1'b1;
        rcrc  <= eth_crc32_8d(rcrc, rdata);
    end
    stFCS : begin
        odata   <= wcrc[rfcscnt];
        oval    <= 1'b1;
        rfcscnt <= rfcscnt + 1'b1;
    end
    endcase
end

endmodule
