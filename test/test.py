# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

NO_OP   = 0x0
ADD     = 0x1
SUB     = 0x2
SHL     = 0x3
SHR     = 0x4
AND     = 0x5
OR      = 0x6
XOR     = 0x7
NOT     = 0x8
LOAD    = 0xA
LESS    = 0xB
EQUAL   = 0xC
GREATER = 0xD
JUMP    = 0x9
BEZ     = 0xE
BNEZ    = 0xF

NONE = 0b00
IMM = 0b00
REGA = 0b01
REGB = 0b10
ACC = 0b11

# SRC_2 SRC_1 OPCODE
# IMM
# (OPCODE, SRC_1, SRC_2, IMM)
INSTRUCTIONS = [
    (NO_OP, NONE, NONE, NONE),
    (LOAD, REGA, NONE, 5),
    (LOAD, REGB, NONE, 10),
    (SUB, REGA, IMM, 1),
    (LOAD, REGA, ACC, NONE),
    (BNEZ, REGA, NONE, 4),
    (SHL, REGB, NONE, NONE)
]

async def reset(dut):
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 6)

async def send(dut, opcode: int, source_1: int, source_2: int, immediate: int) -> int:
    instruction = (source_2 << 6) + (source_1 << 4) + opcode
    dut.ui_in.value = instruction
    await ClockCycles(dut.clk, 1)
    if immediate: dut.ui_in.value = immediate
    await ClockCycles(dut.clk, 4)
    try:
        uio_value = int(dut.uio_out.value)
        status = uio_value >> 6
    except:
        uio_value = 64
        status = 0b10
    if status == 0b10:
        dut._log.info(f"RES: {dut.uo_out.value}")
        return (uio_value & (0b00111111))
    else:
        dut._log.info(f"ERR: {dut.uo_out.value}")
        return -1

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 40 ns (25 MHz)
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    await reset(dut)

    dut._log.info("Test project behavior")

    i = 0
    count = 0
    while True:
        count += 1
        if count == 64: break
        if i >= len(INSTRUCTIONS): break
        instruction = INSTRUCTIONS[i]
        dut._log.info(f"INS {i}: {instruction[2]:02b} {instruction[1]:02b} {instruction[0]:X}")
        if instruction[3]: dut._log.info(f"IMM: {instruction[3]}")
        result = await send(dut, instruction[0], instruction[1], instruction[2], instruction[3])
        if result < 0: break
        if result < (i + 1):
            i = result - 1
        else:
            i += 1
