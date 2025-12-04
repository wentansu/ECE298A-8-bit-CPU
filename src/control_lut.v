module control_lut (
    input  wire [7:0] instruction,
    input  wire [2:0] state,
    output reg  [15:0] control_signals
);

    // Check if instruction is R type or O type
    `define IS_RTYPE(val) ((val==4'h1)||(val==4'h2)||(val==4'h5)||(val==4'h6)||(val==4'h7)||(val==4'hB)||(val==4'hC)||(val==4'hD))
    `define IS_OTYPE(val) ((val==4'h3)||(val==4'h4)||(val==4'h8))
    `define IS_JTYPE(val) ((val==4'h9))
    `define IS_BTYPE(val) ((val==4'hE)||(val==4'hF))
    `define IS_ITYPE(val) ((val==2'b0))

    // State[2:0]
    localparam FETCH     = 3'b000;
    localparam DECODE    = 3'b001;
    localparam EXECUTE   = 3'b010;
    localparam WRITEBACK = 3'b011;
    localparam OUTPUT    = 3'b100;

    // Control signals
    localparam [15:0] FETCH_CONTROL_SIGNALS               = 16'h0400;
    localparam [15:0] DECODE_CONTROL_SIGNALS_I_TYPE       = {4'h0, 4'h2, 8'h00};
    localparam [15:0] DECODE_CONTROL_SIGNALS              = 16'h0000;
    localparam [15:0] WRITEBACK_CONTROL_SIGNALS           = 16'h3880;
    localparam [15:0] OUTPUT_CONTROL_SIGNALS              = 16'h0080;

    localparam [3:0] LOAD = 4'hA;

    reg [15:0] lut [0:255]; // LUT

    // Initialize LUT
    initial begin
        // Initialize all control signals
        for (integer i = 0; i < 256; i = i + 1) begin
            lut[i] = 16'h0000;
        end

        // EXECUTE
        for (integer i = 0; i < 256; i = i + 1) begin
            if (`IS_JTYPE(i[3:0])) begin
                // JUMP
                // Source 2 and 1 must be 00
                if (i[7:4] == 4'h0) begin
                    lut[i[7:0]] = {4'h0, 4'h1, 2'b01, 2'b11, i[3:0]};
                end
            end else if (`IS_BTYPE(i[3:0])) begin
                // BEZ or BNEZ
                // Source 2 must be 00, source 1 cannot be imm
                if (i[7:6] == 2'b00 && i[5:4] != 2'b00) begin
                    if (i[5:4] == 2'b01) begin
                        // Reg A
                        lut[i[7:0]] = {4'h0, 4'h1, 2'b10, 2'b01, i[3:0]};
                    end else begin
                        // Reg B or Acc
                        lut[i[7:0]] = {4'h0, 4'h1, 2'b11, i[5:4], i[3:0]};
                    end
                end
            end else if (i[3:0] == LOAD) begin
                // LOAD
                if (i[7:6] != 2'b11 && i[5:4] == 2'b11) begin
                    // Destination is Acc
                    if (i[7:6] == 2'b01) begin
                        // Source is Reg A
                        lut[i[7:0]] = {2'b00, 2'b11, 4'h8, 2'b00, 2'b01, 4'hA};
                    end else begin
                        // Source is Reg B or Imm
                        lut[i[7:0]] = {2'b00, 2'b11, 4'h8, 2'b01, i[7:6], 4'hA};
                    end
                end else if (i[5:4] != 2'b00) begin
                    // Destination is Reg A or Reg B
                    if (i[7:6] == 2'b00) begin
                        // Load from immediate
                        lut[i[7:0]] = {2'b00, i[5:4], 4'h8, 2'b01, 2'b00, 4'hA};
                    end else if (i[7:6] == 2'b11) begin
                        // Load from acc
                        lut[i[7:0]] = {i[5:4], i[5:4], 4'h8, 2'b01, 2'b11, 4'hA};
                    end
                end
            end else if (`IS_RTYPE(i[3:0])) begin
                // R type instructions
                // Source 1 is always Reg A
                if (i[5:4] == 2'b01 && i[7:6] != 2'b01) begin
                    lut[i[7:0]] = {8'h00, 2'b00, i[7:6], i[3:0]};
                end
            end else if (`IS_OTYPE(i[3:0])) begin
                // O type instructions
                // Operand is selected from Reg A and output of multiplexer
                // Source 2 must be 00
                if (i[7:6] == 2'b00) begin
                    // Reg A
                    if (i[5:4] == 2'b01) begin
                        lut[i[7:0]] = {8'h00, 2'b00, 2'b01, i[3:0]};
                    end else begin
                        lut[i[7:0]] = {8'h00, 2'b01, i[5:4], i[3:0]};
                    end
                end
            end
        end    

        // No op
        lut[8'h00] = 16'h0010;
    end

    // Return value in LUT based on index
    always @(*) begin
        case (state)
            FETCH: begin
                control_signals = FETCH_CONTROL_SIGNALS;
            end
            DECODE: begin
                if (lut[instruction] == 16'h0) begin
                    control_signals = 16'hFFFF;
                end else begin
                    if (`IS_ITYPE(instruction[7:6])) begin
                        control_signals = DECODE_CONTROL_SIGNALS_I_TYPE;
                    end else begin
                        control_signals = DECODE_CONTROL_SIGNALS;
                    end
                end
            end
            EXECUTE: begin
                control_signals = lut[instruction];
            end
            WRITEBACK: begin
                if (instruction == 8'h00) begin
                    control_signals = 16'h0;
                end else begin
                    control_signals = WRITEBACK_CONTROL_SIGNALS;
                end
            end
            OUTPUT: begin
                if (instruction == 8'h00) begin
                    control_signals = 16'h0;
                end else begin
                    control_signals = OUTPUT_CONTROL_SIGNALS;
                end
            end

            default: begin
                control_signals = lut[8'h00];
            end
        endcase
    end

endmodule