module FSM_frame 
(
input wire iclk,//тактирующий сигнал
input wire ienable,//сигнал разрешения формирования пакета
input wire [10:0] ilen,//входная длина поля данных
input wire [7:0] idata_byte,//передающийся байт
output reg [2:0] ost,//состояние КА на выходе
output reg [7:0] obyte// выходящий байт
);

reg [2:0] rcurst, rnextst;//текущее и следующее состояник КА
reg [10:0] count;//счетчик для перехода между состояниями
reg [10:0] rlendata;//переменная для длины поля данных
reg [0:3][7:0] rcrc;// сама контрольная сумма
reg [7:0] rbyte;
integer i = 3;
//переменные для модуля crc32
reg after_d;
reg load_end;
reg crc_eth_en;

//state of FSM
localparam [2:0] stIGP=3'b0, stPREAMBLE=3'b1, stSFD=3'b10, stDADDR=3'b11, stSADDR=3'b100, stLENTYPE=3'b101, stDATA=3'b110, stFCS = 3'b111;
localparam [3:0] lPAUSE = 12;//задержка между пакетиками
localparam [31:0] lCRC32 = 32'h04C11DB7;//пораждающий полином

//инициализация некоторых значений
initial begin
    count <= 'b0;//счетчик в 0
    rcurst <= stIGP;//начальное состояние КА
    rlendata <= 'b0;

    //переменные для модуля crc32
    after_d <= 0;
    load_end <= 0;
    crc_eth_en
 <= 0;
end

eth_crc32_cnt gen_eth_crc32 
(
.ieth_clk               (iclk),
.iafter_d5              (after_d),
.ipayload_end           (load_end),
.ieth_ena               (crc_eth_en),
.ieth_data              (idata_byte),
.ocrc32_data            (rcrc)
);

//логика перехода состояний
always @(posedge iclk) 
begin 
    case (rcurst)
        stIGP       : rnextst = stPREAMBLE;
        stPREAMBLE  : rnextst = stSFD;
        stSFD       : rnextst = stDADDR;
        stDADDR     : rnextst = stSADDR;
        stSADDR     : rnextst = stLENTYPE;
        stLENTYPE   : rnextst = stDATA;
        stDATA      : rnextst = stFCS;
        stFCS       : rnextst = stIGP;
    endcase
end

always @(posedge iclk) begin 
    //переход в состояния КА
    case (rcurst)
        stIGP:begin
            if(ienable & count>lPAUSE-2)begin
                rcurst <= rnextst;
                count <= 0; 
                i <= 3;
                rbyte<=idata_byte;
            end
            else begin
                count <= count + 1;
            end
            //rbyte<=idata_byte;
        end

        stPREAMBLE: begin
            if (count < 6)
                count <= count + 1;
            else begin
                rcurst <= rnextst;
                count <= 0;
                after_d <= 1;
                crc_eth_en<= 1;
            end
            rbyte<=idata_byte;
        end
        stSFD: begin
                rcurst <= rnextst;
                count <= 0;
                rbyte<=idata_byte;
        end
        stDADDR: begin
            if (count < 5)
                count <= count + 1;
            else begin
                rcurst <= rnextst;
                count <= 0;
            end
            rbyte<=idata_byte;
        end
        stSADDR: begin
            if (count < 5)
                count <= count + 1;
            else begin
                rcurst <= rnextst;
                count <= 0;
            end
            rbyte<=idata_byte;
        end
        stLENTYPE:begin
            if (count < 1)
                count <= count + 1;
            else begin
                rcurst <= rnextst;
                rlendata <= ilen;
                count <= 0;
            end
            rbyte<=idata_byte;
        end
        stDATA: begin
            if (rlendata > 1) begin
                rlendata <= rlendata-1;
                rbyte<=idata_byte;
            end
            else begin
                rcurst <= rnextst;
                load_end <= 1;
                crc_eth_en<= 0;
                rbyte<=rcrc[i];
                i=i-1;
            end
        end
        stFCS: begin
            load_end = 0;
            if (count < 3)
                count <= count + 1;
            else begin
            rcurst <= rnextst;
            count <= 0;
            after_d <= 0;
            end
                rbyte<=rcrc[i];
                i=i-1;
        end
    endcase
end

//знаем текущее состояние и выходящий байт

assign ost = rcurst;
assign obyte = rbyte;
endmodule