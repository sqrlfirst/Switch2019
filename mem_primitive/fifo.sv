module fifo
    #(
        parameter pBITS  = 8,               // parameter declaration 
                  pWIDHT = 4
    )
    (
        input wire              iclk,       // Signal declaration 
        input wire              ireset, 
        input wire              ird, 
        input wire              iwr,
        input wire  [pBITS-1:0] iw_data,
        output wire             oempty,
        output wire             ofull,
        output wire [pBITS-1:0] or_data
    );       

    // Inner signal declaration
    reg [pBITS-1:0]          rArray [pWIDHT-1:0];
    reg [$clog2(pWIDHT)-1:0]    rW_ptr      = '0;
    reg [$clog2(pWIDHT)-1:0]    rW_ptr_next = '0;
    reg [$clog2(pWIDHT)-1:0]    rW_ptr_succ = '0;

    reg [$clog2(pWIDHT)-1:0]    rR_ptr      = '0;
    reg [$clog2(pWIDHT)-1:0]    rR_ptr_next = '0;
    reg [$clog2(pWIDHT)-1:0]    rR_ptr_succ = '0;

    reg                         rFull;
    reg                         rEmpty;
    reg                         rFull_next;
    reg                         rEmpty_next;

    wire wWr_en;

    // register file write operation
    always @(posedge iclk)
        if (wWr_en)
            rArray[rW_ptr] <= iw_data;
    // register file read operation
    assign or_data = rArray[rR_ptr];
    // write enable if FIFO is not ful
    assign wWr_en = iwr & ~rFull;

    // FIFO controll logic 
    always @(posedge iclk,posedge ireset) begin
        if (ireset) begin
            rW_ptr <= 0;
            rR_ptr <= 0;
            rFull  <= 1'b0;
            rEmpty <= 1'b1;
        end 
        else begin
            rW_ptr <= rW_ptr_next;
            rR_ptr <= rR_ptr_next;
            rFull  <= rFull_next;
            rEmpty <= rEmpty_next;
        end
    end

    // next-state logic 
    always @* begin
        // successive pointer values 
        rW_ptr_succ = rW_ptr + 1;
        rR_ptr_succ = rR_ptr + 1;
        // default keep old values
        rW_ptr_next = rW_ptr;
        rR_ptr_next = rR_ptr;
        rFull_next  = rFull;
        rEmpty_next = rEmpty;
        case ({iwr, ird})
            //2'b00:
            2'b01: begin  // read
                if(~rEmpty) begin // not EMPTY
                    rR_ptr_next = rR_ptr_succ;
                    rFull_next  = 1'b0;
                    if (rR_ptr_succ == rW_ptr) begin
                        rEmpty_next = 1'b1;
                    end
                end
            end
            2'b10: begin  // write
                if (~rFull) begin // not FULL
                    rW_ptr_next = rW_ptr_succ;
                    rEmpty_next = 1'b0;
                    if (rW_ptr_succ == rR_ptr) begin
                       rFull_next = 1'b1; 
                    end
                end
            end
            2'b11: begin  // write and read
                rW_ptr_next = rW_ptr_succ;
                rR_ptr_next = rR_ptr_succ;
            end 
             
        endcase
        
    end

    // output
    assign ofull = rFull;
    assign oempty = rEmpty;

endmodule 
