module lut (
    input  wire [7:0] instruction,
    input  wire [1:0] state,
    output reg  [15:0] control_signals
);

    // Check if instruction is R type or O type
    `define IS_IN_RTYPE(val) ((val==4'h1)||(val==4'h2)||(val==4'h5)||(val==4'h6)||(val==4'h7)||(val==4'hB)||(val==4'hC)||(val==4'hD))
    `define IS_IN_OTYPE(val) ((val==4'h3)||(val==4'h4)||(val==4'h8))

    // State[1:0]
    localparam FETCH     = 2'b00;
    localparam DECODE    = 2'b01;
    localparam EXECUTE   = 2'b10;
    localparam WRITEBACK = 2'b11;

    // ALUOp[3:0]
    localparam ALU_NO_OP        = 4'b0000;
    localparam ALU_ADD          = 4'b0001;
    localparam ALU_SUB          = 4'b0010;
    localparam ALU_SHIFT_LEFT   = 4'b0011;
    localparam ALU_SHIFT_RIGHT  = 4'b0100;
    localparam ALU_AND          = 4'b0101;
    localparam ALU_OR           = 4'b0110;
    localparam ALU_XOR          = 4'b0111;
    localparam ALU_NOT          = 4'b1000;
    localparam ALU_GREATER_THAN = 4'b1001;
    localparam ALU_LESS_THAN    = 4'b1010;
    localparam ALU_EQUAL_TO     = 4'b1011;

    // ALUSrc[1:0]
    localparam ALUSRC_REG_B = 2'b00;
    localparam ALUSRC_IMM   = 2'b01;
    localparam ALUSRC_ACC   = 2'b10;
    localparam ALUSRC_ZERO  = 2'b11;

    // Instruction types
    // reg [3:0] R_TYPE [0:7];
    // reg [3:0] O_TYPE [0:2];

    // initial begin
    //     R_TYPE[0] = 4'h1;
    //     R_TYPE[1] = 4'h2;
    //     R_TYPE[2] = 4'h5;
    //     R_TYPE[3] = 4'h6;
    //     R_TYPE[4] = 4'h7;
    //     R_TYPE[5] = 4'hB;
    //     R_TYPE[6] = 4'hC;
    //     R_TYPE[7] = 4'hD;

    //     O_TYPE[0] = 4'h3;
    //     O_TYPE[1] = 4'h4;
    //     O_TYPE[2] = 4'h8;
    // end

    reg [15:0] lut [0:1023]; // LUT
    wire [9:0] index = {state, instruction}; // Index of LUT element

    // Initialize LUT
    initial begin
        // Initialize all control signals
        for (integer i = 0; i < 256; i = i + 1) begin
            lut[i] = 16'h0000;
        end

        // FETCH
        // Skip No op
        for (integer i = 1; i < 256; i = i + 1) begin
            lut[{FETCH, i[7:0]}] = 16'h0400;
        end

        // DECODE
        // Skip No op
        for (integer i = 1; i < 256; i = i + 1) begin
            if (i[7:6] == 2'b00) begin
                // Using immediate value (I type)
                lut[{EXECUTE, i[7:0]}] = {4'h0, 4'h2, 8'h00};
            end
        end

        // EXECUTE
        // Skip No op
        for (integer i = 1; i < 256; i = i + 1) begin
            if (`IS_IN_RTYPE(i[3:0])) begin
                // R type instructions
                // Assume Source 1 is always Reg A
                lut[{EXECUTE, i[7:0]}] = {8'h00, 2'b00, i[7:6], i[3:0]};
            end else if (`IS_IN_OTYPE(i[3:0])) begin
                // O type instructions
                // Assume Source is always Reg A
                if (i[7:6] == 2'b00) begin
                    // Using immediate value (I type)
                    lut[{EXECUTE, i[7:0]}] = {8'h00, 2'b00, 2'b00, i[3:0]};
                end else begin
                    lut[{EXECUTE, i[7:0]}] = {8'h00, 2'b00, 2'b01, i[3:0]};
                end
            end else if (i[3:0] == 4'hA) begin
                // Load
                // Not using ALU
                lut[{EXECUTE, i[7:0]}] = {8'h00, 2'b00, 2'b01, 4'h0};
            end
        end    

        // WRITEBACK
        // Skip No op
        for (integer i = 1; i < 256; i = i + 1) begin
            // Load
            if (i[3:0] != 4'hA) begin
                lut[{WRITEBACK, i[7:0]}] = 16'h3880;
            end else begin
                lut[{WRITEBACK, i[7:0]}] = {2'b00, i[5:4], 12'h800};
            end
        end
    end

    // Return value in LUT based on index
    always @(*) begin
        control_signals = lut[index];
    end

endmodule