/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`include "control_lut.v"
`include "alu.v"
`include "counter.v"
`include "reg.v"
`include "mux.v"

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
  reg [2:0] state;
  wire [15:0] control_signals;

  localparam FETCH     = 3'b000;
  localparam DECODE    = 3'b001;
  localparam EXECUTE   = 3'b010;
  localparam WRITEBACK = 3'b011;
  localparam OUTPUT    = 3'b100;

  localparam ZERO = 8'b0;

  control_lut lookup_table (
    .instruction(instruction),
    .state(state),
    .control_signals(control_signals)
  );

  wire [3:0] alu_op = control_signals[3:0];
  wire [1:0] alu_src = control_signals[5:4];
  wire out = control_signals[7];
  wire immediate_load = control_signals[9];
  wire instruction_load = control_signals[10];
  wire reg_write = control_signals[11];
  wire [1:0] reg_dest = control_signals[13:12];

  wire reg_write_A = (reg_write == 1 && reg_dest == 2'b01) ? 1 : 0;
  wire reg_write_B = (reg_write == 1 && reg_dest == 2'b10) ? 1 : 0;
  wire reg_write_acc = (reg_write == 1 && reg_dest == 2'b11) ? 1 : 0;

  wire [7:0] pc_in = 8'b0;
  wire [7:0] pc_out;
  wire pc_load = 0;
  wire pc_inc  = state == OUTPUT ? 1 : 0;

  counter pc (
    .ui_in(pc_in),
    .load(pc_load),
    .uo_out(pc_out),
    .clk(clk),
    .inc(pc_inc)
  );

  wire [7:0] immediate;

  register instructionReg (
    .mode(instruction_load),
    .uo_out(instruction),
    .uio_in(ui_in),
    .clk(clk),
    .rst_n(rst_n)
  );

  register immediateReg (
    .mode(immediate_load),
    .uo_out(immediate),
    .uio_in(ui_in),
    .clk(clk),
    .rst_n(rst_n)
  );

  wire [7:0] regA_out;
  wire [7:0] regB_out;
  wire [7:0] acc_out;

  register regA (
    .mode(reg_write_A),
    .uo_out(regA_out),
    .uio_in(immediate),
    .clk(clk),
    .rst_n(rst_n)
  );

  register regB (
    .mode(reg_write_B),
    .uo_out(regB_out),
    .uio_in(immediate),
    .clk(clk),
    .rst_n(rst_n)
  );

  wire [7:0] alu_src2;

  mux multiplexer (
    .a(immediate),
    .b(ZERO),
    .c(regB_out),
    .d(acc_out),
    .select(alu_src),
    .out(alu_src2)
  );

  wire [7:0] alu_result;

  alu alu_unit (
    .alu_op(alu_op),
    .ui_in(regA_out),
    .uo_out(alu_result),
    .uio_in(alu_src2),
    .clk(clk),
    .rst_n(rst_n)
  );

  register acc (
    .mode(reg_write_acc),
    .uo_out(acc_out),
    .uio_in(alu_result),
    .clk(clk),
    .rst_n(rst_n)
  );

  // Control signals
  localparam [15:0] FETCH_CONTROL_SIGNALS               = 16'h0400;
  localparam [15:0] DECODE_CONTROL_SIGNALS_I_TYPE       = {4'h0, 4'h2, 8'h00};
  localparam [15:0] DECODE_CONTROL_SIGNALS              = 16'h0000;
  localparam [15:0] WRITEBACK_CONTROL_SIGNALS           = 16'h3880;
  localparam [15:0] WRITEBACK_CONTROL_SIGNALS_LOAD      = 16'h0800;

  assign uio_oe = 8'hFF;
  assign uio_out = {pc_out[7:0]};
  assign uo_out = out ? acc_out : 8'bZ;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= FETCH;
    end else begin
      case (state)
        FETCH: state <= DECODE;
        DECODE: state <= EXECUTE;
        EXECUTE: begin
          state <= WRITEBACK;
        end
        WRITEBACK: begin
          state <= OUTPUT;
        end
        OUTPUT: begin
          state <= FETCH;
        end
        default: state <= FETCH;
      endcase
    end
  end

  // List unused signals
  wire _unused = &{
      uio_in, ena, control_signals[15:14], control_signals[8], control_signals[6], pc_out[7:6]
  };

endmodule
