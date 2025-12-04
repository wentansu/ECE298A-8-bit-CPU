# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 40 ns (25 MHz)
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0

    dut._log.info("Test project behavior")

    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 6)

    # LOAD A 8
    dut.ui_in.value = 0b00011010
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0b00001000
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # ADD A 1 = 9
    dut.ui_in.value = 0b00010001
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0b00000001
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # AND A ACC = 8
    dut.ui_in.value = 0b11010101
    await ClockCycles(dut.clk, 1)
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # LOAD B 0
    dut.ui_in.value = 0b00101010
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0b00000000
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # SHL B = 0
    dut.ui_in.value = 0b00100011
    await ClockCycles(dut.clk, 1)
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # NOT Acc = 11111111
    dut.ui_in.value = 0b00111000
    await ClockCycles(dut.clk, 1)
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # LOAD Acc <= Reg A = 8
    dut.ui_in.value = 0b01111010
    await ClockCycles(dut.clk, 1)
    # dut.ui_in.value = 0b00001010
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # Invalid = Z
    dut.ui_in.value = 0b11111111
    await ClockCycles(dut.clk, 1)
    print("Output:", dut.uo_out.value)
    await ClockCycles(dut.clk, 1)
    
    # BEZ B 15 = 1
    dut.ui_in.value = 0b00101110
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0b00001111
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # JUMP 1 = 1
    dut.ui_in.value = 0b00001001
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0b00000001
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)
    # LOAD B 10 = 10
    dut.ui_in.value = 0b00101010
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0b00001010
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # NO OP = Z
    dut.ui_in.value = 0b0
    await ClockCycles(dut.clk, 1)
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)
