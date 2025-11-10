/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`include "lut.v"

`default_nettype none

module tt_um_8_bit_cpu (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire [7:0] instruction;
  wire [1:0] state;
  wire [15:0] control_signals;

  assign instruction = ui_in;
  assign state = 2'b10;

  lut lookup_table (
    .instruction(instruction),
    .state(state),
    .control_signals(control_signals)
  );

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = control_signals[7:0];
  assign uio_out = control_signals[15:8];
  assign uio_oe  = 8'hff;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
