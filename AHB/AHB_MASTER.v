module Manager #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 32
)(
    
    // Input from TB
    input i_start,                              //Start Signal
    input [ADDRESS_WIDTH-1:0] i_haddr,          // Data Address
    input i_hwrite,                             //Read or write operation(Read-0 , Write-1)
    input [2:0] i_hsize,                        // Size to send
    input [DATA_WIDTH-1:0] i_hwdata,            // Data to send
    input [2:0] i_hburst,                       // Burst type


    // Global Signal
    input HRESETn,
    input HCLK,

    // Transfer Response(Slave)
    input HREADY,
    input HRESP,

    // Data
    input [DATA_WIDTH-1:0] HRDATA,              // Slave Read Data
    output reg [DATA_WIDTH-1:0] HWDATA,         // SLave Write Data


    output reg [DATA_WIDTH-1:0] o_hrdata,       // Read Data from SLave
    
    // Address and Control 
    output reg [DATA_WIDTH-1:0] HADDR,          // Output Address
    output reg HWRITE,                          // Write/Read output
    output reg [2:0] HSIZE,                     // Transfer Size
    output reg [2:0] HBURST,                    // Burst Type
    output reg [3:0] HPROT,                     // 
    output reg [1:0] HTRANS,                    // Transfer type
    output reg HMASTLOCK                        // Lock
);

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

// STATES
reg [1:0] state, next_state;

reg [3:0] burst_count;
reg [DATA_WIDTH-1:0]HWDATA_reg;
reg  read_flag;
reg [2:0] read_size;
reg start_samp;

// State machine 
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn)
        state <= IDLE; 
    else if(HREADY)
        state <= next_state; 
end

always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn)
        HTRANS <= IDLE;
    else if (HREADY)
        case(next_state)
            IDLE: HTRANS <= IDLE;
            NONSEQ : HTRANS  <= NONSEQ;
            SEQ : HTRANS <= SEQ;
        endcase
end


// Next State Logic
always @(*) begin 
  case (state)  
    IDLE: next_state = (start_samp) ? (NONSEQ) : (IDLE);
    NONSEQ: next_state = (!start_samp) ? IDLE : (HBURST!=SINGLE) ? SEQ : NONSEQ;
    SEQ: next_state = (!start_samp) ? IDLE : (burst_count>0) ? SEQ : (start_samp) ? NONSEQ : IDLE; 
    default: next_state = IDLE;
  endcase 
end

// Lock 
always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
        HMASTLOCK <= 1'b0;   
    end
    else if (state == IDLE && start_samp) begin
        HMASTLOCK <= 1'b1;  
    end
    else if (state == SEQ && burst_count == 0) begin
        HMASTLOCK <= 1'b0;  
    end
end



// Stage Actions
always @(posedge HCLK or negedge HRESETn) begin
    if(!HRESETn) begin
        HADDR <= ADDRESS_WIDTH'0;
        HWRITE <= 1'b1;
        burst_count <= 3'b000;
        HWDATA <= DATA_WIDTH'0;
        HSIZE <= BYTE;
        HBURST <= SINGLE;
    end
    else
        case(state)
            IDLE: begin                                 // IDLE Stage
                if(start_samp && HREADY) begin
                    HADDR <= i_haddr;
                    HWRITE <= i_hwrite;
                    HSIZE <= i_hsize;
                    HBURST <= i_hburst;
                    HWRITE <= i_hwrite;
                    HWDATA_reg <= i_hwdata;
                    burst_count <= 3'b000;  
                end
                start_samp <= i_start;
            end

            NONSEQ : begin                              // NONSEQ Stage
                if(HREADY) begin
                    if(HBURST == SINGLE)
                        HADDR <= i_haddr;
                    else if((HBURST == INCR4)||(HBURST == INCR8) || (HBURST == INCR16)) begin   // Incrementing burst
                        case(HSIZE) 
                            BYTE: HADDR <= HADDR + 1;
                            HALFWORD : HADDR <= HADDR + 2;
                            WORD : HADDR <= HADDR + 4;
                        endcase
                    end
                    else if (HBURST ==  WRAP4) begin
                        case(HSIZE)
                            BYTE : HADDR <= {HADDR[ADDRESS_WIDTH-1:2], HADDR[1:0] + 2'd1};
                            HALFWORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:3], HADDR[2:0] + 3'd2};
                            WORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:4], HADDR[3:0] + 4'd4};
                        endcase
                    end
                    else if (HBURST ==  WRAP8) begin
                        case(HSIZE)
                            BYTE : HADDR <= {HADDR[ADDRESS_WIDTH-1:3], HADDR[2:0] + 3'd1};
                            HALFWORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:4], HADDR[3:0] + 4'd2};
                            WORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:5], HADDR[4:0] + 5'd4};
                        endcase
                    end
                    else if (HBURST ==  WRAP16) begin
                        case(HSIZE)
                            BYTE : HADDR <= {HADDR[ADDRESS_WIDTH-1:4], HADDR[3:0] + 4'd1};
                            HALFWORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:5], HADDR[4:0] + 5'd2};
                            WORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:6], HADDR[5:0] + 6'd4};
                        endcase
                    end
                    
                    // Writing Data
                    HWDATA_reg <= i_hwdata;
                    HWDATA <= HWDATA_reg;

                    if(HBURST == SINGLE) begin
                        HBURST <= i_hburst;
                        HSIZE <= i_hsize;
                        HWDATA <= i_hwdata;
                    end
                    read_flag <= ~HWRITE;                                   //Read Flag
                    read_size <= (~HWRITE) ? HSIZE : read_size;             // Read Size 

                    case (HBURST)                                           // Assigning Burst Count
                        SINGLE:  burst_count <= 4'd0;  
                        INCR4:   burst_count <= 4'd2;
                        INCR8:   burst_count <= 4'd6;
                        INCR16:  burst_count <= 4'd14;
                        WRAP4:   burst_count <= 4'd2;
                        WRAP8:   burst_count <= 4'd6;
                        WRAP16:  burst_count <= 4'd14;
                        default: burst_count <= 4'd0;
                    endcase

                end

                if(read_flag)                                               // Read Transfer
                    case(read_size)
                        BYTE :o_hrdata[31:24] <= HRDATA[31:24];
                        HALFWORD : o_hrdata[31:16] <= HRDATA[31:16];
                        WORD : o_hrdata <= HRDATA;
                    endcase
                
                start_samp <= i_start;
            end


            SEQ : begin
                if(HREADY) begin
                    burst_count <= burst_count - 1;
                    if(burst_count > 0) begin
                        if((HBURST == INCR4)||(HBURST == INCR8) || (HBURST == INCR16)) begin
                            case(HSIZE) 
                                BYTE: HADDR <= HADDR + 1;
                                HALFWORD : HADDR <= HADDR + 2;
                                WORD : HADDR <= HADDR + 4;
                            endcase
                        end  
                    end
                    else if (HBURST ==  WRAP4) begin
                        case(HSIZE)
                            BYTE : HADDR <= {HADDR[ADDRESS_WIDTH-1:2], HADDR[1:0] + 2'd1};
                            HALFWORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:3], HADDR[2:0] + 3'd2};
                            WORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:4], HADDR[3:0] + 4'd4};
                        endcase
                    end
                    else if (HBURST ==  WRAP8) begin
                        case(HSIZE)
                            BYTE : HADDR <= {HADDR[ADDRESS_WIDTH-1:3], HADDR[2:0] + 3'd1};
                            HALFWORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:4], HADDR[3:0] + 4'd2};
                            WORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:5], HADDR[4:0] + 5'd4};
                        endcase
                    end
                    else if (HBURST ==  WRAP16) begin
                        case(HSIZE)
                            BYTE : HADDR <= {HADDR[ADDRESS_WIDTH-1:4], HADDR[3:0] + 4'd1};
                            HALFWORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:5], HADDR[4:0] + 5'd2};
                            WORD : HADDR <= {HADDR[ADDRESS_WIDTH-1:6], HADDR[5:0] + 6'd4};
                        endcase
                    end
                    else
                        HADDR <= i_haddr;
                    
                    HWDATA_reg <= i_hwdata;
                    HWDATA <= HWDATA_reg;

                    if(burst_count == 0) begin
                        HBURST <= i_hburst;
                        HSIZE <= i_hsize;
                        HWDATA <= i_hwdata;
                        case(i_hburst) 
                            SINGLE:  burst_count <= 4'd0;  
                            INCR4:   burst_count <= 4'd2;
                            INCR8:   burst_count <= 4'd6;
                            INCR16:  burst_count <= 4'd14;
                            WRAP4:   burst_count <= 4'd2;
                            WRAP8:   burst_count <= 4'd6;
                            WRAP16:  burst_count <= 4'd14;
                            default: burst_count <= 4'd0;
                        endcase
                    end

                    if(read_flag)
                        case(read_size)
                            BYTE :o_hrdata[31:24] <= HRDATA[31:24];
                            HALFWORD : o_hrdata[31:16] <= HRDATA[31:16];
                            WORD : o_hrdata <= HRDATA;
                        endcase
                    start_samp<=i_start;
                end
            end
        endcase
    end
endmodule