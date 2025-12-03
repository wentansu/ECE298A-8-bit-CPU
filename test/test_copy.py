# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

INSTRUCTIONS = [
    {"name": "NO_OP",         "opcode": 0x0, "type": ["N"]},
    {"name": "ADD",           "opcode": 0x1, "type": ["R", "I"]},
    {"name": "SUB",      "opcode": 0x2, "type": ["R", "I"]},
    {"name": "SHL",    "opcode": 0x3, "type": ["O", "I"]},
    {"name": "SHR",   "opcode": 0x4, "type": ["O", "I"]},
    {"name": "AND",           "opcode": 0x5, "type": ["R", "I"]},
    {"name": "OR",            "opcode": 0x6, "type": ["R", "I"]},
    {"name": "XOR",           "opcode": 0x7, "type": ["R", "I"]},
    {"name": "NOT",           "opcode": 0x8, "type": ["O", "I"]},
    {"name": "LOAD", "opcode": 0xA, "type": ["I"]},
    {"name": "GREAT",  "opcode": 0xB, "type": ["R", "I"]},
    {"name": "LESS",     "opcode": 0xC, "type": ["R", "I"]},
    {"name": "EQUAL",      "opcode": 0xD, "type": ["R", "I"]},
]

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

    # for instruction in INSTRUCTIONS:
    #     opcode = instruction["opcode"]

    #     for type in instruction["type"]:
    #         for sources in TYPES[type]:

    #             # Set the input values you want to test
    #             dut.ui_in.value = (sources << 4) | opcode

    #             # Wait for one clock cycle to see the output values
    #             await ClockCycles(dut.clk, 5)

    #             # The following assersion is just an example of how to check the output values.
    #             # Change it to match the actual expected output of your module:
    #             print(f"{sources:04b} {instruction['name'].rjust(5)} {str(instruction['type']).rjust(10)}", dut.uio_out.value, dut.uo_out.value)

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

    # # ADD A 1 = 9
    # dut.ui_in.value = 0b00010001
    # await ClockCycles(dut.clk, 1)
    # dut.ui_in.value = 0b00000001
    # await ClockCycles(dut.clk, 4)
    # print("Output:", dut.uo_out.value)

    # # AND A ACC = 8
    # dut.ui_in.value = 0b11010101
    # await ClockCycles(dut.clk, 1)
    # await ClockCycles(dut.clk, 4)
    # print("Output:", dut.uo_out.value)

    # LOAD B 0
    dut.ui_in.value = 0b00101010
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0b00000000
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # # SHL B = 30
    # dut.ui_in.value = 0b00100011
    # await ClockCycles(dut.clk, 1)
    # await ClockCycles(dut.clk, 4)
    # print("Output:", dut.uo_out.value)

    # # NOT Acc
    # dut.ui_in.value = 0b00111000
    # await ClockCycles(dut.clk, 1)
    # await ClockCycles(dut.clk, 4)
    # print("Output:", dut.uo_out.value)

    # LOAD Acc <= Reg A
    # dut.ui_in.value = 0b01111010
    # await ClockCycles(dut.clk, 1)
    # # dut.ui_in.value = 0b00001010
    # await ClockCycles(dut.clk, 4)
    # print("Output:", dut.uo_out.value)

    # # Invalid
    # dut.ui_in.value = 0b11111111
    # await ClockCycles(dut.clk, 1)
    # print("Output:", dut.uo_out.value)
    # await ClockCycles(dut.clk, 1)
    
    # BEZ B 15
    dut.ui_in.value = 0b00101110
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0b00001111
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # JUMP 1
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
    # LOAD B 10
    dut.ui_in.value = 0b00101010
    await ClockCycles(dut.clk, 1)
    dut.ui_in.value = 0b00001010
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # NO OP
    dut.ui_in.value = 0b0
    await ClockCycles(dut.clk, 1)
    await ClockCycles(dut.clk, 4)
    print("Output:", dut.uo_out.value)

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.