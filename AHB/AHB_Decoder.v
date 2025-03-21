module AHB_Decoder #(
    parameter DATA_WIDTH = 32,   
    parameter ADDRESS_WIDTH = 32, 
    parameter NO_OF_SLAVES = 2
)(
    input  [ADDRESS_WIDTH-1:0] HADDR,  
    output reg [NO_OF_SLAVES-1:0] HSEL 
);

    localparam SLAVE_ADDR_BITS = $clog2(NO_OF_SLAVES); 

    always @(*) begin
        HSEL = {NO_OF_SLAVES{1'b0}}; 
        
        case (HADDR[ADDRESS_WIDTH-1:ADDRESS_WIDTH-SLAVE_ADDR_BITS]) 
            0: HSEL = (1 << 0);
            1: HSEL = (1 << 1);
            2: HSEL = (1 << 2);
            3: HSEL = (1 << 3);
            4: HSEL = (1 << 4);
            5: HSEL = (1 << 5);
            6: HSEL = (1 << 6);
            7: HSEL = (1 << 7);
            8: HSEL = (1 << 8);
            default: HSEL = {NO_OF_SLAVES{1'b0}}; 
        endcase
    end
endmodule
