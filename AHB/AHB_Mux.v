module AHB_Mux #(
    parameter NO_OF_SLAVES = 2,
    parameter DATA_WIDTH = 32
) (
    input  wire [NO_OF_SLAVES-1:0] HSEL,
    input  wire [NO_OF_SLAVES-1:0] HREADYOUT,
    input  wire [NO_OF_SLAVES-1:0] HRESP_IN,
    input  wire [NO_OF_SLAVES-1:0][DATA_WIDTH-1:0] HRDATA_IN,
    
    output reg  HREADY,
    output reg  HRESP,
    output reg  [DATA_WIDTH-1:0] HRDATA  
);

integer i;

always @(*) begin
    HREADY = 1'b1;  // Default Ready signal
    HRESP  = 1'b0;  // Default Response: OKAY
    HRDATA = {DATA_WIDTH{1'b0}};  // Default Data: 0

    for (i = 0; i < NO_OF_SLAVES; i = i + 1) begin
        if (HSEL[i]) begin
            HREADY = HREADYOUT[i];
            HRESP  = HRESP_IN[i];
            HRDATA = HRDATA_IN[i];
        end
    end
end

endmodule
