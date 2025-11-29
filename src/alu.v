// ---------------------------------------------------------------------------
// 8-bit adder: used for ADD operation
// 0 : ADD
// 1 : SUB
// ---------------------------------------------------------------------------
module adder8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire      op,
    output reg [7:0] sum
);
    always @* begin
        case (op)
            0: sum = a + b;
            1: sum = a - b;
            default: sum = 8'h00;       // unused / safe default
        endcase
    end
endmodule

// ---------------------------------------------------------------------------
// 8-bit logic unit: OR, AND, NOR
//   00 : AND
//   01 : OR
//   10 : NOR
//   11 : XOR
// ---------------------------------------------------------------------------
module logic_unit8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [1:0] sel,
    output reg  [7:0] y
);
    always @* begin
        case (sel)
            2'b00: y = a & b;         // AND
            2'b01: y = a | b;         // OR
            2'b10: y = ~(a | b);      // NOR
            2'b11: y = a ^ b;         // XOR
            default: y = 8'h00;       // unused / safe default
        endcase
    end
endmodule

// ---------------------------------------------------------------------------
// 8-bit logical shifter
// 0 : shift left
// 1 : shift right
// ---------------------------------------------------------------------------
module shifter8 (
    input  wire [7:0] a,
    input  wire [2:0] shamt,
    input  wire       dir,      // 0 = left, 1 = right
    output wire [7:0] y
);
    assign y = dir ? (a >> shamt) : (a << shamt);
endmodule

module alu (
    
    input  wire [7:0] ui_in,
    input  wire [7:0] uio_in,
    output wire [7:0] uo_out,
    input  wire [2:0] alu_op,    
    input  wire       clk,
    input  wire       rst_n
);

    // Decode function select
    wire [2:0] func_sel = alu_op;

    wire [7:0] A = ui_in;
    wire [7:0] B = uio_in;
    wire [2:0] shamt = uio_in[2:0];

    // ---------------------- Submodule outputs -------------------------------
    // ADD
    wire [7:0] add_sum;

    adder8 u_adder8 (
        .a   (A),
        .b   (B),
        .op  (func_sel[0]),
        .sum (add_sum)
    );

    // Logic (OR/AND/NOR)
    wire [7:0] logic_y;
    logic_unit8 u_logic8 (
        .a   (A),
        .b   (B),
        .sel (func_sel[1:0]),   // 00=OR, 01=AND, 10=NOR
        .y   (logic_y)
    );

    // Shifter
    wire [7:0] shift_y;

    shifter8 u_shifter8 (
        .a     (A),
        .shamt (shamt),
        .dir   (func_sel[0]),
        .y     (shift_y)
    );

    // ---------------------- Operation select mux ----------------------------
    reg [7:0] alu_y;
    reg       alu_flag;  // use as carry/flag output

    always @* begin
        case (func_sel)
            3'b000: begin
                // ADD
                alu_y    = add_sum;
                alu_flag = 0;       // carry
            end

            3'b001:  begin
                // SUB
                alu_y    = add_sum;
                alu_flag = 0;       // carry
            end
            3'b010: begin
                // shift left
                alu_y    = shift_y;
                alu_flag = 1'b0;
            end
            3'b011: begin
                // shift right
                alu_y    = shift_y;
                alu_flag = 1'b0;
            end

            3'b100: begin
                // logic ops: OR, AND, NOR
                alu_y    = logic_y;
                alu_flag = 1'b0;
            end

            3'b101: begin
                // logic ops: OR, AND, NOR
                alu_y    = logic_y;
                alu_flag = 1'b0;
            end

            3'b110: begin
                // logic ops: OR, AND, NOR
                alu_y    = logic_y;
                alu_flag = 1'b0;
            end
            3'b111: begin
                // logic ops: OR, AND, NOR
                alu_y    = logic_y;
                alu_flag = 1'b0;
            end

            default: begin
                alu_y    = 8'h00;
                alu_flag = 1'b0;
            end
        endcase
    end

    // ----------------------------- Registers --------------------------------
    reg [7:0] y_q;

    always @(posedge clk) begin
        if (!rst_n) begin
            y_q    <= 8'h00;
        end else begin
            y_q    <= alu_y;
        end
        // if ena == 0, hold previous values
    end

    // Outputs
    assign uo_out  = y_q;

endmodule
