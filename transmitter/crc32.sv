module eth_crc32_cnt
(
     input ieth_clk,//ethernet clock
     //service header info
     input iafter_d5,//start crc32 count
     input ipayload_end,//last payload byte
     input ieth_ena ,
     input [7:0] ieth_data,
     //output ethernet data
     output logic[0:3][7:0]ocrc32_data = 'b0
);
//
//--------------------------------------------------------------------------------
function integer eth_crc32_8d(input integer crc32, input logic [7:0] data);
     bit [ 7:0] d;
     bit [31:0] c;
     bit [31:0] newcrc;
  begin
     for (int i=0;i<8;i++)
         d[i] = data[7-i];
     //
     c = crc32;
     newcrc[0] = d[6] ^ d[0] ^ c[24] ^ c[30];
     newcrc[1] = d[7] ^ d[6] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ c[30] ^ c[31];
     newcrc[2] = d[7] ^ d[6] ^ d[2] ^ d[1] ^ d[0] ^ c[24] ^ c[25] ^ 
c[26] ^ c[30] ^ c[31];
     newcrc[3] = d[7] ^ d[3] ^ d[2] ^ d[1] ^ c[25] ^ c[26] ^ c[27] ^ c[31];
     newcrc[4] = d[6] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[24] ^ c[26] ^ 
c[27] ^ c[28] ^ c[30];
     newcrc[5] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[24] 
^ c[25] ^ c[27] ^ c[28] ^ c[29] ^ c[30] ^ c[31];
     newcrc[6] = d[7] ^ d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ c[25] ^ c[26] 
^ c[28] ^ c[29] ^ c[30] ^ c[31];
     newcrc[7] = d[7] ^ d[5] ^ d[3] ^ d[2] ^ d[0] ^ c[24] ^ c[26] ^ 
c[27] ^ c[29] ^ c[31];
     newcrc[8] = d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[0] ^ c[24] ^ c[25] ^ 
c[27] ^ c[28];
     newcrc[9] = d[5] ^ d[4] ^ d[2] ^ d[1] ^ c[1] ^ c[25] ^ c[26] ^ 
c[28] ^ c[29];
     newcrc[10] = d[5] ^ d[3] ^ d[2] ^ d[0] ^ c[2] ^ c[24] ^ c[26] ^ 
c[27] ^ c[29];
     newcrc[11] = d[4] ^ d[3] ^ d[1] ^ d[0] ^ c[3] ^ c[24] ^ c[25] ^ 
c[27] ^ c[28];
     newcrc[12] = d[6] ^ d[5] ^ d[4] ^ d[2] ^ d[1] ^ d[0] ^ c[4] ^ c[24] 
^ c[25] ^ c[26] ^ c[28] ^ c[29] ^ c[30];
     newcrc[13] = d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[2] ^ d[1] ^ c[5] ^ c[25] 
^ c[26] ^ c[27] ^ c[29] ^ c[30] ^ c[31];
     newcrc[14] = d[7] ^ d[6] ^ d[4] ^ d[3] ^ d[2] ^ c[6] ^ c[26] ^ 
c[27] ^ c[28] ^ c[30] ^ c[31];
     newcrc[15] = d[7] ^ d[5] ^ d[4] ^ d[3] ^ c[7] ^ c[27] ^ c[28] ^ 
c[29] ^ c[31];
     newcrc[16] = d[5] ^ d[4] ^ d[0] ^ c[8] ^ c[24] ^ c[28] ^ c[29];
     newcrc[17] = d[6] ^ d[5] ^ d[1] ^ c[9] ^ c[25] ^ c[29] ^ c[30];
     newcrc[18] = d[7] ^ d[6] ^ d[2] ^ c[10] ^ c[26] ^ c[30] ^ c[31];
     newcrc[19] = d[7] ^ d[3] ^ c[11] ^ c[27] ^ c[31];
     newcrc[20] = d[4] ^ c[12] ^ c[28];
     newcrc[21] = d[5] ^ c[13] ^ c[29];
     newcrc[22] = d[0] ^ c[14] ^ c[24];
     newcrc[23] = d[6] ^ d[1] ^ d[0] ^ c[15] ^ c[24] ^ c[25] ^ c[30];
     newcrc[24] = d[7] ^ d[2] ^ d[1] ^ c[16] ^ c[25] ^ c[26] ^ c[31];
     newcrc[25] = d[3] ^ d[2] ^ c[17] ^ c[26] ^ c[27];
     newcrc[26] = d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[18] ^ c[24] ^ c[27] ^ 
c[28] ^ c[30];
     newcrc[27] = d[7] ^ d[5] ^ d[4] ^ d[1] ^ c[19] ^ c[25] ^ c[28] ^ 
c[29] ^ c[31];
     newcrc[28] = d[6] ^ d[5] ^ d[2] ^ c[20] ^ c[26] ^ c[29] ^ c[30];
     newcrc[29] = d[7] ^ d[6] ^ d[3] ^ c[21] ^ c[27] ^ c[30] ^ c[31];
     newcrc[30] = d[7] ^ d[4] ^ c[22] ^ c[28] ^ c[31];
     newcrc[31] = d[5] ^ c[23] ^ c[29];
     eth_crc32_8d = newcrc;
  end
  endfunction
//--------------------------------------------------------------------------------
//
logic [31:0]rcrc = '1;
wire [3:0] wcrc [0:7];
generate
genvar i;
  for (i=31;i>=0;i=i-1)begin:flip_crc_bits
     assign wcrc [i[4:2]][3-i[1:0]] = ~rcrc[i];
     end
endgenerate
//-------------------------------------------------------------------
//1.при изменении указателя заголовка, начинаем формировать запросы в 
//память пакета с "адресом" данных
//2. приходящие данные
//-------------------------------------------------------------------
localparam logic [1:0] WAIT_ST = 0;
localparam logic [1:0] CRC32_ST = 1;
localparam logic [1:0] COUNT_ST = 2;
logic[1:0] frame_fsm = WAIT_ST;
logic crc_insert = 'b0;
//
//-------------------------------------------------------------------
always_ff@(posedge ieth_clk)begin
     case (frame_fsm)
     WAIT_ST:begin
         if (iafter_d5 && ieth_ena)begin
             rcrc <= 32'hFF_FF_FF_FF;
             frame_fsm <= COUNT_ST;
             rcrc <= eth_crc32_8d(32'hFF_FF_FF_FF,ieth_data);
             end
         end
     //
     COUNT_ST:begin
         if (ieth_ena)begin
             rcrc <= eth_crc32_8d(rcrc,ieth_data);
             end
        //
        if (ipayload_end)begin
            ocrc32_data[0] <= {wcrc[6],wcrc[7]};//crc32
            ocrc32_data[1] <= {wcrc[4],wcrc[5]};//crc32
            ocrc32_data[2] <= {wcrc[2],wcrc[3]};//crc32
            ocrc32_data[3] <= {wcrc[0],wcrc[1]};//crc32
            frame_fsm <= WAIT_ST;
            end
         end
     default:begin
         frame_fsm <= WAIT_ST;
         end
     endcase
     //
     end
//-------------------------------------------------------------------
//
endmodule