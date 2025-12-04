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
  reg reset;

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
  wire alu_operand = control_signals[6];
  wire out = control_signals[7];
  wire pc_load = control_signals[8];
  wire immediate_load = control_signals[9];
  wire instruction_load = control_signals[10];
  wire reg_write = control_signals[11];
  wire [1:0] reg_dest = control_signals[13:12];
  wire reg_src_A = control_signals[14];
  wire reg_src_B = control_signals[15];

  wire reg_write_A = (reg_write == 1 && reg_dest == 2'b01) ? 1 : 0;
  wire reg_write_B = (reg_write == 1 && reg_dest == 2'b10) ? 1 : 0;
  wire reg_write_acc = (reg_write == 1 && reg_dest == 2'b11) ? 1 : 0;

  reg branch;
  wire [7:0] pc_out;

  wire pc_inc  = ((state == OUTPUT) || invalid_ins) && !branch;
  wire send_ins = (state == OUTPUT) || invalid_ins;
  wire invalid_ins = (state == DECODE) && (instruction != 8'h0) && (control_signals == 16'hFFFF);

  wire load_branch = branch && (alu_result == 8'b1);

  counter pc (
    .ui_in(immediate),
    .load(load_branch),
    .uo_out(pc_out),
    .clk(clk),
    .inc(pc_inc),
    .rst_n(reset)
  );

  wire [7:0] immediate;

  register instructionReg (
    .mode(instruction_load),
    .uo_out(instruction),
    .uio_in(ui_in),
    .clk(clk),
    .rst_n(reset)
  );

  register immediateReg (
    .mode(immediate_load),
    .uo_out(immediate),
    .uio_in(ui_in),
    .clk(clk),
    .rst_n(reset)
  );

  wire [7:0] regA_out;
  wire [7:0] regB_out;
  wire [7:0] acc_out;

  wire [7:0] reg_source_A_out;
  wire [7:0] reg_source_B_out;

  mux reg_source_A (
    .a(immediate),
    .b(acc_out),
    .c(ZERO),
    .d(ZERO),
    .select({1'b0, reg_src_A}),
    .out(reg_source_A_out)
  );

  mux reg_source_B (
    .a(immediate),
    .b(acc_out),
    .c(ZERO),
    .d(ZERO),
    .select({1'b0, reg_src_B}),
    .out(reg_source_B_out)
  );

  register regA (
    .mode(reg_write_A),
    .uo_out(regA_out),
    .uio_in(reg_source_A_out),
    .clk(clk),
    .rst_n(reset)
  );

  register regB (
    .mode(reg_write_B),
    .uo_out(regB_out),
    .uio_in(reg_source_B_out),
    .clk(clk),
    .rst_n(reset)
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
    .alu_operand(alu_operand),
    .ui_in(regA_out),
    .uo_out(alu_result),
    .uio_in(alu_src2),
    .clk(clk),
    .rst_n(reset)
  );

  register acc (
    .mode(reg_write_acc),
    .uo_out(acc_out),
    .uio_in(alu_result),
    .clk(clk),
    .rst_n(reset)
  );

  assign uio_oe = 8'hFF;
  assign uio_out = {send_ins, invalid_ins, pc_out[5:0]};
  assign uo_out = (invalid_ins == 0 && out && state == OUTPUT) ? acc_out : 8'bZ;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset
      state <= FETCH;
      reset <= 0;
    end else begin
      case (state)
        FETCH: begin
          if (!reset) begin
            state <= FETCH;
            reset <= 1;
            branch <= 0;
          end else begin
            state <= DECODE;
            branch <= 0;
          end
        end
        DECODE: begin
          if (invalid_ins) begin
            state <= FETCH;
          end else begin
            state <= EXECUTE;
          end
        end
        EXECUTE: begin
          state <= WRITEBACK;
          branch <= pc_load;
        end
        WRITEBACK: begin
          state <= OUTPUT;
          branch <= 0;
        end
        OUTPUT: begin
          state <= FETCH;
        end
        default: begin
          state <= FETCH;
        end
      endcase
    end
  end

  // List unused signals
  wire _unused = &{
      uio_in, ena, pc_out[7:6]
  };

endmodule
