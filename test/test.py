# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles
from cocotb.triggers import Timer


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    # clock = Clock(dut.clk, 10, unit="us")
    # cocotb.start_soon(clock.start())

    # Reset
    # dut._log.info("Reset")
    # dut.ena.value = 1
    # dut.ui_in.value = 0
    # dut.uio_in.value = 0
    # dut.rst_n.value = 0
    # await ClockCycles(dut.clk, 10)
    # dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    dut.a.value = 0b10101010
    dut.b.value = 0b11110000
    dut.c.value = 0b01010101
    dut.d.value = 0b00000000
    dut.select.value = 0b00

    # Wait for one clock cycle to see the output values
    # await ClockCycles(dut.clk, 1)
    await Timer(1, units="ns")

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.out.value == 0b10101010

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
    dut.select.value = 0b01
    await Timer(1, units="ns")
    print(dut.out.value)

    dut.select.value = 0b10
    await Timer(1, units="ns")
    print(dut.out.value)

    dut.select.value = 0b11
    await Timer(1, units="ns")
    print(dut.out.value)

    dut.a.value = 0b00110011
    dut.select.value = 0b00
    await Timer(1, units="ns")
    print(dut.out.value)
