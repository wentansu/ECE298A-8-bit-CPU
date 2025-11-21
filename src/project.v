/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`include "control_lut.v"
`include "alu.v"
`include "counter.v"
`include "reg.v"

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
  wire [7:0] instruction_reg;
  wire [7:0] immediate_reg;
  wire [15:0] control_signals;

  localparam FETCH     = 2'b00;
  localparam DECODE    = 2'b01;
  localparam EXECUTE   = 2'b10;
  localparam WRITEBACK = 2'b11;

  assign instruction = ui_in;
  assign state = EXECUTE;

  control_lut lookup_table (
    .instruction(instruction),
    // .state(state),
    .control_signals(control_signals)
  );

  wire [7:0] pc_in;
  wire [7:0] pc_out;
  wire load = 0;
  wire inc = 1;

  counter pc (
    .ui_in(pc_in),
    .load(load),
    .uo_out(pc_out),
    .clk(clk),
    .inc(inc)
  );


  wire [7:0] regA_out;
  wire [7:0] regA_in;
  wire mode = 0;

  register regA (
    .mode(mode),
    .uo_out(regA_out),
    .uio_in(regA_in),
    .clk(clk),
    .rst_n(rst_n)
  );

  wire [7:0] alu_result;
  wire [2:0] alu_op;
  wire [7:0] alu_src1;
  wire [7:0] alu_src2;

  alu alu_unit (
    .alu_op(alu_op),
    .ui_in(alu_src1),
    .uo_out(alu_result),
    .uio_in(alu_src2),
    .clk(clk),
    .rst_n(rst_n)
  );

  // Control signals for FETCH, DECODE, WRITEBACK
  localparam [15:0] FETCH_CONTROL_SIGNALS = 16'h0400;
  localparam [15:0] DECODE_CONTROL_SIGNALS_I_TYPE = {4'h0, 4'h2, 8'h00};
  localparam [15:0] DECODE_CONTROL_SIGNALS = 16'h0000;
  localparam [15:0] WRITEBACK_CONTROL_SIGNALS = 16'h3880;
  localparam [15:0] WRITEBACK_CONTROL_SIGNALS_LOAD = 16'h0800; // [13:12] = instruction[5:4]

  wire ins_load = control_signals[0];
  wire imm_load = control_signals[1];

  always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // assign instruction_reg = 8'b0;
            // assign immediate_reg   = 8'b0;
        end else begin
            if (ins_load) begin
                // capture instruction/opcode from io_in
                // assign instruction_reg = io_in;
            end
            if (imm_load) begin
                // capture immediate on the cycle where ImmLoad asserted
                // assign immediate_reg = io_in;
            end
        end
  end

  // always @(posedge clk or negedge rst_n) begin
  //       if (!rst_n) begin
  //           state <= FETCH;
  //       end else begin
  //           case (state)
  //               FETCH:     state <= DECODE;
  //               DECODE:    state <= EXECUTE;
  //               EXECUTE:   state <= WRITEBACK;
  //               WRITEBACK: state <= FETCH;
  //               default:   state <= FETCH;
  //           endcase
  //       end
  // end

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = control_signals[7:0];
  assign uio_out = control_signals[15:8];
  assign uio_oe  = 8'hff;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule