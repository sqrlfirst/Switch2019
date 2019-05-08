
// paprameters for packet state
localparam [2:0] lpND  =  3'b000,     // No data
                 lpPRE =  3'b001,     // Preambula
                 lpSFD =  3'b010,     // Delimiter
                 lpDA  =  3'b011,     // Destination Adress
                 lpSA  =  3'b100,     // Source Adress
                 lpDATA = 3'b101,     // Data
                 lpCRC  = 3'b110;     // CRC  

parameter        pFSM_BUS_WIDHT = 3;

// local parameters for copy_packet_to_mem FSM_write
localparam [1:0] lpWAIT      = 2'b00,
                 lpWRITE     = 2'b01,
                 lpCHECK_CRC = 2'b10;

parameter        pFSM_WRITE_BUS  = 2;

// Packet Memory parameters 
parameter   pDATA_WIDTH        = 8,                     
            pMIN_PACKET_LENGHT = 64,
            pMAX_PACKET_LENGHT = 1536,
            pFIFO_WIDTH        = $clog2(pMAX_PACKET_LENGHT),
            pDEPTH_RAM         = 2*pMAX_PACKET_LENGHT,
            pFIFO_DEPTH        = pDEPTH_RAM/pMIN_PACKET_LENGHT;
