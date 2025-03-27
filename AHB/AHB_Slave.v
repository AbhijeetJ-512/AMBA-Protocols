module Subordinate #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 32,
    parameter DEPTH_WIDTH = 1024
)(  // Global Signals
    input HRESETn,
    input HCLK,

    // Select
    input HSELx,

    // Address and Control
    input  [ADDRESS_WIDTH-1:0] HADDR,
    input  HWRITE,
    input  [2:0] HSIZE,
    input  [2:0] HBURST,
    input  [3:0] HPROT,
    input  [1:0] HTRANS,
    input  HMASTLOCK,
    input HREADY,

    // Data 
    input [DATA_WIDTH-1:0] HWDATA,
    output reg [DATA_WIDTH-1:0] HRDATA,

    // Transfer Response
    output reg HREADYOUT,
    output reg HRESP
);

// Parameter for wait
localparam WAIT_READ = 0;
localparam WAIT_WRITE = 0;

// Parameters for HSIZE
localparam BYTE = 3'b000;
localparam HALFWORD = 3'b001;
localparam WORD = 3'b010;

// Parameters for HBURST
localparam SINGLE = 3'b000;
localparam INCR = 3'b001;
localparam WRAP4 = 3'b010;
localparam INCR4 = 3'b011;
localparam WRAP8 = 3'b100;
localparam INCR8 = 3'b101;
localparam WRAP16 = 3'b110;
localparam INCR16 = 3'b111;

// Parameters for HTRANS
localparam IDLE = 2'b00;
localparam BUSY = 2'b01;
localparam NONSEQ = 2'b10;
localparam SEQ = 2'b11;

reg [7:0] mem [0:DEPTH_WIDTH-1];

reg [4:0] wait_counter;
reg write_en;

reg [2:0] hsize_samp;   
reg [ADDRESS_WIDTH-1:0] haddr_samp;
reg [DATA_WIDTH-1:0] hwdata_samp;
reg hwrite_samp;
reg hsel_samp; 


always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin
        HRESP <= 1'b0;
        wait_counter <= 5'b0;
        write_en <= 1'b0;
    end
    else if((HSELx && HREADY) || (hsel_samp && HREADYOUT)) 
        case(HTRANS) 
            IDLE : begin
                HRESP <= 1'b0;
                HREADYOUT <= 1'b1;
                wait_counter <= 'b0;
                write_en <= 1'b0;
                hsel_samp <= HSELx;
            end
            default : begin
                HRESP <= 1'b0;

                if(HREADY) begin
                    hwdata_samp <= HWDATA;
                    haddr_samp <= HADDR;
                    hsel_samp <= HSELx;
                    hsize_samp <= HSIZE;
                    hwrite_samp <= HWRITE;
                end
                else if((HWRITE && wait_counter == 0) || (hwrite_samp && wait_counter > 0)) begin           // Write Operation on slave
                    if (wait_counter < WAIT_WRITE) begin
                        HREADYOUT  <= 1'b0;
                        wait_counter <= wait_counter + 1;
                        write_en     <= 1'b0;
                    end
                    else begin
                        HREADYOUT  <= 1'b1;
                        wait_counter <= 'b0;
                        write_en     <= 1'b1;
                    end
                end
                else begin
                    if (wait_counter < WAIT_READ) begin                     // Read Transfer
                        HREADYOUT  <= 1'b0;
                        wait_counter <= wait_counter + 1;
                        write_en     <= 1'b0;
                    end
                    else begin
                        HREADYOUT  <= 1'b1;
                        wait_counter <= 'b0;
                        write_en     <= 1'b0;
                    end
                end
            end
        endcase
    else begin
        HREADYOUT <= 1'b1;
        HRESP <= 1'b0;
    end
end

// Memory Write (Big-Endian)
always @(posedge HCLK) begin
    if (write_en && hsel_samp) begin
        case (hsize_samp)
            BYTE: 
                mem[haddr_samp] <= hwdata_samp[31:24];

            HALFWORD: begin
                mem[haddr_samp]     <= hwdata_samp[31:24];
                mem[haddr_samp + 1] <= hwdata_samp[23:16];
            end

            WORD: begin
                mem[haddr_samp]     <= hwdata_samp[31:24];
                mem[haddr_samp + 1] <= hwdata_samp[23:16];
                mem[haddr_samp + 2] <= hwdata_samp[15:8];
                mem[haddr_samp + 3] <= hwdata_samp[7:0];
            end
        endcase
    end
end


// Memory Read Operation
always @(*) begin
    HRDATA = 32'b0; // Default to zero

    if (hwrite_samp == 1'b0) begin
        case (hsize_samp)
            BYTE: begin
                HRDATA = {mem[haddr_samp], 24'b0};
            end
            HALFWORD: begin
                HRDATA = {mem[haddr_samp], mem[haddr_samp + 1], 16'b0};
            end
            WORD: begin
                HRDATA = {mem[haddr_samp], mem[haddr_samp + 1], mem[haddr_samp + 2], mem[haddr_samp + 3]};
            end
        endcase
    end
end


endmodule