/*
 * Tri-state output register with single R/W* control.
 * ui_in[0] = R_nW  (0 = READ: drive bus; 1 = WRITE: capture uio_in on clk)
 */

module register (
    input  wire       mode,
    output wire [7:0] uo_out,   // mirrors internal register
    input  wire [7:0] uio_in,   // shared data bus (into DUT)
    input  wire       clk,
    input  wire       rst_n
);

  reg [7:0] reg_q;

  // Async reset; WRITE when RnW==0
  always @(posedge clk) begin
    if (!rst_n) begin
      reg_q <= 8'd0;
    end else if (mode) begin
      reg_q <= uio_in;          // WRITE: capture bus
    end
  end

  // Dedicated outputs always driven
  assign uo_out  = reg_q;

endmodule
