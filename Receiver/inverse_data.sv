//  Module: inverse_data
//
module inverse_data #(
    pDATA_WIDTH = 8
)(
    
    input  logic [pDATA_WIDTH-1:0] idata,  
    input  logic                   ienable,
    output logic [pDATA_WIDTH-1:0] odata   
);

always_comb begin 
    if (ienable) odata = ~idata;
    else odata = idata;
end

endmodule: inverse_data
