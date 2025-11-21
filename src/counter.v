module counter (
    input  wire [7:0] ui_in,    // Dedicated inputs
    input  wire       load,
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire       clk,
    input  wire       inc   
);
  //sets reg
  reg [7:0] counter;

  wire [7:0]dat = ui_in;

  // All output pins must be assigned. If not used, assign to 0.
  //assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  always @(posedge clk) begin
    if (load)
      counter <= dat;
    else if (inc)
      counter <= counter + 8'b1;
  end

  assign uo_out = counter;

endmodule