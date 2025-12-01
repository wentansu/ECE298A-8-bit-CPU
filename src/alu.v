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
// 8-bit logic unit: AND, OR, XOR, NOT
// ---------------------------------------------------------------------------
module logic_unit8 (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [3:0] sel,
    output reg  [7:0] y
);
    always @* begin
        case (sel)
            4'h5: y = a & b;         // AND
            4'h6: y = a | b;         // OR
            4'h7: y = a ^ b;         // XOR
            4'h8: y = ~a;            // NOT
            4'hB: y = {7'b0, (a < b)};
            4'hC: y = {7'b0, (a == b)};
            4'hD: y = {7'b0, (a > b)};
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
    input  wire       dir,      // 0 = left, 1 = right
    output wire [7:0] y
);
    assign y = dir ? (a >> 1) : (a << 1);
endmodule

module alu (
    
    input  wire [7:0] ui_in,
    input  wire [7:0] uio_in,
    output wire [7:0] uo_out,
    input  wire [3:0] alu_op,    
    input  wire       clk,
    input  wire       rst_n
);

    // Decode function select
    wire [3:0] func_sel = alu_op;

    wire [7:0] A = ui_in;
    wire [7:0] B = uio_in;

    // ---------------------- Submodule outputs -------------------------------
    // ADD
    wire [7:0] add_sum;
    wire add_sub = (func_sel == 4'h1) ? 0 : 1;

    adder8 u_adder8 (
        .a   (A),
        .b   (B),
        .op  (add_sub),
        .sum (add_sum)
    );

    // Logic (OR/AND/NOR)
    wire [7:0] logic_y;

    logic_unit8 u_logic8 (
        .a   (A),
        .b   (B),
        .sel (func_sel),
        .y   (logic_y)
    );

    // Shifter
    wire [7:0] shift_y;
    wire left_right = (func_sel == 4'h3) ? 0 : 1;

    shifter8 u_shifter8 (
        .a     (A),
        .dir   (left_right),
        .y     (shift_y)
    );

    // ---------------------- Operation select mux ----------------------------
    reg [7:0] alu_y;
    // reg       alu_flag;  // use as carry/flag output

    always @* begin
        case (func_sel)
            4'h1: begin
                // ADD
                alu_y    = add_sum;
                // alu_flag = 0;       // carry
            end

            4'h2:  begin
                // SUB
                alu_y    = add_sum;
                // alu_flag = 0;       // carry
            end
            4'h3: begin
                // shift left
                alu_y    = shift_y;
                // alu_flag = 1'b0;
            end
            4'h4: begin
                // shift right
                // shift right
                alu_y    = shift_y;
                // alu_flag = 1'b0;
            end

            4'h5: begin
                // logic ops: AND, OR, XOR, NOT
                alu_y    = logic_y;
                // alu_flag = 1'b0;
            end

            4'h6: begin
                // logic ops: AND, OR, XOR, NOT
                alu_y    = logic_y;
                // alu_flag = 1'b0;
            end

            4'h7: begin
                // logic ops: AND, OR, XOR, NOT
                alu_y    = logic_y;
                // alu_flag = 1'b0;
            end
            4'h8: begin
                // logic ops: AND, OR, XOR, NOT
                alu_y    = logic_y;
                //alu_flag = 1'b0;
            end

            4'hA: begin
                alu_y = uio_in;
                // alu_flag = 1'b0;
            end

            4'hB: begin
                alu_y    = logic_y;
                // alu_flag = 1'b0;
            end

            4'hC: begin
                alu_y    = logic_y;
                // alu_flag = 1'b0;
            end

            4'hD: begin
                alu_y    = logic_y;
                // alu_flag = 1'b0;
            end

            4'h0: begin
                alu_y = 8'h00;
                // alu_flag = 1'b0;
            end

            default: begin
                alu_y    = 8'h00;
                // alu_flag = 1'b0;
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
