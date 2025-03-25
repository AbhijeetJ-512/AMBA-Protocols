module AHB_Decoder #(
    parameter DATA_WIDTH = 32,   
    parameter ADDRESS_WIDTH = 32, 
    parameter NO_OF_SLAVES = 2,
    parameter SLAVE_ADDR_BITS = 23
)(
    input  [ADDRESS_WIDTH-1:0] HADDR,  
    output reg [NO_OF_SLAVES-1:0] HSEL
);

always @(*) begin
    HSEL = {NO_OF_SLAVES{1'b0}};
    
    if (HADDR[ADDRESS_WIDTH-1:ADDRESS_WIDTH-SLAVE_ADDR_BITS] < NO_OF_SLAVES) begin
        HSEL[HADDR[ADDRESS_WIDTH-1:ADDRESS_WIDTH-SLAVE_ADDR_BITS]] = 1'b1;
    end
end

endmodule
