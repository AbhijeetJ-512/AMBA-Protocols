module AHB_Bus_System #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 32,
    parameter NO_OF_SLAVES = 2,
    parameter SLAVE_ADDR_BITS = 23
)(
    // Global Signals
    input HRESETn,
    input HCLK,

    // Master Interface
    input [ADDRESS_WIDTH-1:0] HADDR,
    input HWRITE,
    input [2:0] HSIZE,
    input [2:0] HBURST,
    input [3:0] HPROT,
    input [1:0] HTRANS,
    input HMASTLOCK,
    input HREADY,

    input  [DATA_WIDTH-1:0] HWDATA,
    output [DATA_WIDTH-1:0] HRDATA,

    output HREADYOUT,
    output HRESP
);

    // Internal Signals
    wire [NO_OF_SLAVES-1:0] HSEL;
    wire [NO_OF_SLAVES-1:0] HREADYOUT_S;
    wire [NO_OF_SLAVES-1:0] HRESP_IN;
    wire [NO_OF_SLAVES*DATA_WIDTH-1:0] HRDATA_IN;  // Flattened HRDATA array
    
    // Instantiate AHB Master (Manager)
    Manager #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH)
    ) master_inst (
        .i_start(i_start),
        .i_haddr(i_haddr),
        .i_hwrite(i_hwrite),
        .i_hsize(i_hsize),
        .i_hwdata(i_hwdata),
        .i_hburst(i_hburst),

        .HRESETn(HRESETn),
        .HCLK(HCLK),

        .HREADY(HREADY),
        .HRESP(HRESP),
        .HRDATA(HRDATA),
        .HWDATA(HWDATA),

        .o_hrdata(o_hrdata),
        .HADDR(HADDR),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HBURST(HBURST),
        .HPROT(HPROT),
        .HTRANS(HTRANS),
        .HMASTLOCK(HMASTLOCK)
    );


    // Instantiate AHB Decoder
    AHB_Decoder #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH),
        .NO_OF_SLAVES(NO_OF_SLAVES),
        .SLAVE_ADDR_BITS(SLAVE_ADDR_BITS)
    ) decoder_inst (
        .HADDR(HADDR),
        .HSEL(HSEL)
    );

    // Generate and Instantiate Slaves
    genvar i;
    generate
        for (i = 0; i < NO_OF_SLAVES; i = i + 1) begin : Slave_Instances
            Subordinate #(
                .DATA_WIDTH(DATA_WIDTH),
                .ADDRESS_WIDTH(ADDRESS_WIDTH),
                .DEPTH_WIDTH(1024)
            ) slave_inst (
                .HRESETn(HRESETn),
                .HCLK(HCLK),
                .HSELx(HSEL[i]),
                .HADDR(HADDR),
                .HWRITE(HWRITE),
                .HSIZE(HSIZE),
                .HBURST(HBURST),
                .HPROT(HPROT),
                .HTRANS(HTRANS),
                .HMASTLOCK(HMASTLOCK),
                .HREADY(HREADY),
                .HWDATA(HWDATA),
                .HRDATA(HRDATA_IN[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]), // Corrected HRDATA indexing
                .HREADYOUT(HREADYOUT_S[i]),
                .HRESP(HRESP_IN[i])
            );
        end
    endgenerate

    // Instantiate AHB Mux
    AHB_Mux #(
        .NO_OF_SLAVES(NO_OF_SLAVES),
        .DATA_WIDTH(DATA_WIDTH)
    ) mux_inst (
        .HSEL(HSEL),
        .HREADYOUT(HREADYOUT_S),
        .HRESP_IN(HRESP_IN),
        .HRDATA_IN(HRDATA_IN),
        .HREADY(HREADYOUT),
        .HRESP(HRESP),
        .HRDATA(HRDATA)
    );

endmodule
