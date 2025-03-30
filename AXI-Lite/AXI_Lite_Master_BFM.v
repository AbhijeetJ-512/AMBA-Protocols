module axi_lite_master_bfm #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH / 8
)(
    input wire                       aclk,
    input wire                       areset_n,

    // AXI4-Lite Master Interface
    output reg [ADDR_WIDTH-1:0]      awaddr,
    output reg                       awvalid,
    input wire                       awready,

    output reg [DATA_WIDTH-1:0]      wdata,
    output reg [STRB_WIDTH-1:0]      wstrb,
    output reg                       wvalid,
    input wire                       wready,

    input wire [1:0]                 bresp,
    input wire                       bvalid,
    output reg                       bready,

    output reg [ADDR_WIDTH-1:0]      araddr,
    output reg                       arvalid,
    input wire                       arready,

    input wire [DATA_WIDTH-1:0]      rdata,
    input wire [1:0]                 rresp,
    input wire                       rvalid,
    output reg                       rready
);

    // Initialization block
    initial begin
        awaddr  = {ADDR_WIDTH{1'b0}};
        awvalid = 0;
        wdata   = {DATA_WIDTH{1'b0}};
        wstrb   = {STRB_WIDTH{1'b1}};  // Assume full strobes
        wvalid  = 0;
        bready  = 0;
        araddr  = {ADDR_WIDTH{1'b0}};
        arvalid = 0;
        rready  = 0;
    end

    // AXI Write Task
    task axi_write;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
        begin
            awaddr  <= addr;
            awvalid <= 1'b1;

            @(posedge aclk);
            // Wait for AWREADY
            while (!awready)
                @(posedge aclk);

            awvalid <= 1'b0;

            wdata  <= data;
            wvalid <= 1'b1;

            // Wait for WREADY
            while (!wready)
                @(posedge aclk);

            wvalid <= 1'b0;

            bready <= 1'b1;

            // Wait for BVALID
            while (!bvalid)
                @(posedge aclk);

            bready <= 1'b0;

            @(posedge aclk);
        end
    endtask

    // AXI Read Task
    task axi_read;
        input  [ADDR_WIDTH-1:0] addr;
        output [DATA_WIDTH-1:0] data_out;
        begin
            @(posedge aclk);
            araddr  <= addr;
            arvalid <= 1'b1;
            @(posedge aclk);
            // Wait for ARREADY
            while (!arready)
                @(posedge aclk);

            arvalid <= 1'b0;

            rready <= 1'b1;

            // Wait for RVALID
            while (!rvalid)
                @(posedge aclk);

            data_out = rdata;

            rready <= 1'b0;

            @(posedge aclk);
        end
    endtask

endmodule

