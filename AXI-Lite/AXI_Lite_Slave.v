module axi_lite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH / 8,
    parameter DATA_DEPTH = 512
)(
    // Global Signals
    input wire                        aclk,
    input wire                        areset_n,

    // Read Address Channel
    input wire [ADDR_WIDTH-1:0]       araddr,
    input wire                        arvalid,
    output reg                        arready,

    // Read Data Channel
    output reg [DATA_WIDTH-1:0]       rdata,
    output reg [1:0]                  rresp,
    output reg                        rvalid,
    input wire                        rready,

    // Write Address Channel
    input wire [ADDR_WIDTH-1:0]       awaddr,
    input wire                        awvalid,
    output reg                        awready,

    // Write Data Channel
    input wire [DATA_WIDTH-1:0]       wdata,
    input wire [STRB_WIDTH-1:0]       wstrb,
    input wire                        wvalid,
    output reg                        wready,

    // Write Response Channel
    output reg [1:0]                  bresp,
    output reg                        bvalid,
    input wire                        bready
);

    // AXI response codes
    localparam OKAY   = 2'b00;
    localparam SLVERR = 2'b10;

    // Internal memory
    reg [DATA_WIDTH-1:0] mem [0:DATA_DEPTH-1];

    // FSM states for write transaction
    localparam WR_IDLE   = 0;
    localparam WR_DATA   = 1;
    localparam WR_RESP   = 2;

    // FSM states for read transaction
    localparam RD_IDLE   = 0;
    localparam RD_DATA   = 1;

    reg [1:0] wr_state;
    reg [1:0] rd_state;

    reg [ADDR_WIDTH-1:0] awaddr_reg;
    reg [ADDR_WIDTH-1:0] araddr_reg;

    integer i;
    // Write FSM
    always @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            wr_state <= WR_IDLE;
            awready  <= 1'b0;
            wready   <= 1'b0;
            bvalid   <= 1'b0;
            bresp    <= OKAY;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    awready <= 1'b1;
                    if (awvalid && awready) begin
                        awaddr_reg <= awaddr;
                        awready    <= 1'b0;
                        wready     <= 1'b1;
                        wr_state   <= WR_DATA;
                    end
                end

                WR_DATA: begin
                    if (wvalid && wready) begin
                        for (i = 0; i < STRB_WIDTH; i = i + 1) begin
                            if (wstrb[i]) begin
                                mem[awaddr_reg[$clog2(DATA_DEPTH)+1:2]][8*i +: 8] <= wdata[8*i +: 8];
                            end
                        end
                        wready   <= 1'b0;
                        bvalid   <= 1'b1;
                        bresp    <= OKAY;
                        wr_state <= WR_RESP;
                    end
                end

                WR_RESP: begin
                    if (bvalid && bready) begin
                        bvalid   <= 1'b0;
                        wr_state <= WR_IDLE;
                    end
                end

                default: wr_state <= WR_IDLE;
            endcase
        end
    end

    // Read FSM
    always @(posedge aclk or negedge areset_n) begin
        if (!areset_n) begin
            rd_state <= RD_IDLE;
            arready  <= 1'b0;
            rvalid   <= 1'b0;
            rresp    <= OKAY;
            rdata    <= 'b0;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    arready <= 1'b1;
                    if (arvalid && arready) begin
                        araddr_reg <= araddr;
                        arready    <= 1'b0;
                        rdata      <= mem[araddr[$clog2(DATA_DEPTH)+1:2]];
                        rresp      <= OKAY;
                        rvalid     <= 1'b1;
                        rd_state   <= RD_DATA;
                    end
                end

                RD_DATA: begin
                    if (rvalid && rready) begin
                        rvalid   <= 1'b0;
                        rd_state <= RD_IDLE;
                    end
                end

                default: rd_state <= RD_IDLE;
            endcase
        end
    end

endmodule