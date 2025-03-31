`timescale 1ns / 1ps

module testbench;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter STRB_WIDTH = DATA_WIDTH / 8;

    // Clock and reset
    reg aclk;
    reg areset_n;

    // Wires to connect BFM <-> DUT
    wire [ADDR_WIDTH-1:0] awaddr;
    wire                  awvalid;
    wire                  awready;

    wire [DATA_WIDTH-1:0] wdata;
    wire [STRB_WIDTH-1:0] wstrb;
    wire                  wvalid;
    wire                  wready;

    wire [1:0]            bresp;
    wire                  bvalid;
    wire                  bready;

    wire [ADDR_WIDTH-1:0] araddr;
    wire                  arvalid;
    wire                  arready;

    wire [DATA_WIDTH-1:0] rdata;
    wire [1:0]            rresp;
    wire                  rvalid;
    wire                  rready;
    reg [DATA_WIDTH-1:0] read_data;

    // Clock generation
    initial aclk = 0;
    always #5 aclk = ~aclk;

    // Reset generation
    initial begin
        areset_n = 0;
        #20;
        areset_n = 1;
    end

    initial begin
        $dumpfile("waveform.vcd");     // Dump file name
        $dumpvars(0, testbench);       // Dump all variables in testbench hierarchy
    end

    // Instantiate DUT (Slave)
    axi_lite_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) dut (
        .aclk(aclk),
        .areset_n(areset_n),
        .araddr(araddr),
        .arvalid(arvalid),
        .arready(arready),
        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),
        .rready(rready),
        .awaddr(awaddr),
        .awvalid(awvalid),
        .awready(awready),
        .wdata(wdata),
        .wstrb(wstrb),
        .wvalid(wvalid),
        .wready(wready),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready)
    );

    // Instantiate BFM (Master)
    axi_lite_master_bfm #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) master (
        .aclk(aclk),
        .areset_n(areset_n),
        .awaddr(awaddr),
        .awvalid(awvalid),
        .awready(awready),
        .wdata(wdata),
        .wstrb(wstrb),
        .wvalid(wvalid),
        .wready(wready),
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready),
        .araddr(araddr),
        .arvalid(arvalid),
        .arready(arready),
        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),
        .rready(rready)
    );
    initial begin
        #30;  // wait until reset is done

        $display("Starting AXI-Lite simulation...");
        master.axi_write(32'h10, 32'hABCDEF);
        $display("Write complete.");

        #10;

        master.axi_read(32'h10, read_data);
        $display("Read data = 0x%08X", read_data);

        #20;
        $finish;
    end

endmodule
