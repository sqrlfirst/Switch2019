// paprameters for packet state 
localparam [2:0] lpNO_FRAME  =  3'b000,     // No data
                 lpPREAMBLE =  3'b001,     // Preambula
                 lpDELIMETER =  3'b010,     // Delimiter
                 lpDA  =  3'b011,     // Destination Adress
                 lpSA  =  3'b100,     // Source Adress
                 lpLENGTH = 3'b101,   //Length
                 lpDATA = 3'b110,     // Data
                 lpFCS  = 3'b111;     // CRC  


parameter               pMAX_PORT_NUMBER = 4,
                        pADRESS = 2,      //Capacity for port №   
                        pSLOTS = 16384,   //№ of adresses   
                        pDATA_WIDTH=8,
                        pTIME = 9,         //Capacity for save time = 300 seconds 
                        pMAX_PACKET_LENGHT = 1536,
                        pONE_SECOND = 327686;
                        


