# test/test_instr_fetch.py
import os
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles, Timer

# ---- configurable knobs via env (optional) ----
SYNC_LATENCY = int(os.getenv("IF_LATENCY", "1"))   # cycles from PC apply -> instr valid (0/1/2…)
CLK_PERIOD_NS = int(os.getenv("IF_CLK_NS", "10"))  # 100 MHz default
RESET_CYCLES  = int(os.getenv("IF_RST_CYC", "2"))  # async rst low cycles

# A small demo "program": PC -> INSTR mapping (edit to match your design)
# Keys/values can be decimal or hex (ints). We'll mask to bus widths below.
PROGRAM = {
    0x00: 0x13,  # e.g., NOP/ADDI x0,x0,0
    0x01: 0x37,
    0x02: 0x6F,
    0x03: 0x63,
    0x10: 0xAA,
    0x1F: 0x55,
}

# --------- helpers ---------
def pick_sig(dut, *names):
    """Return the first signal that exists on the DUT from names list, else None."""
    for n in names:
        if hasattr(dut, n):
            return getattr(dut, n)
    return None

def fully_driven(sig) -> bool:
    """True if signal has no X/Z bits."""
    s = sig.value.binstr.lower()
    return ('x' not in s) and ('z' not in s)

async def maybe_reset(dut):
    rst_n = pick_sig(dut, "rst_n", "resetn", "reset_n", "rst", "rstb")
    clk   = pick_sig(dut, "clk", "clock")
    if clk is not None:
        cocotb.start_soon(Clock(clk, CLK_PERIOD_NS, units="ns").start())
    # If no reset present, just return
    if rst_n is None:
        return
    # Async low reset
    rst_n.value = 0
    await (ClockCycles(clk, RESET_CYCLES) if clk is not None else Timer(10, units="ns"))
    rst_n.value = 1
    if clk is not None:
        await RisingEdge(clk)

async def apply_pc_and_wait(dut, pc_sig, instr_sig, pc_val):
    """Drive PC and wait for SYNC_LATENCY cycles if a clock exists; else small time."""
    pc_sig.value = pc_val
    clk = pick_sig(dut, "clk", "clock")
    if clk is None:
        # purely combinational: give it a delta + a little time
        await Timer(1, units="ns")
    else:
        # synchronous: wait the configured latency
        if SYNC_LATENCY <= 0:
            await RisingEdge(clk)  # at least one edge to sample inputs cleanly
        else:
            await ClockCycles(clk, SYNC_LATENCY)

@cocotb.test()
async def instr_fetch_table_check(dut):
    """
    Drive PC addresses and check the returned instruction/opcode
    against the PROGRAM mapping above.
    """
    # Find signals (common aliases supported)
    pc    = pick_sig(dut, "pc", "pc_addr", "addr", "address")
    instr = pick_sig(dut, "instr", "instruction", "op", "opcode", "data", "rd_data")

    assert pc is not None,    "Couldn't find a PC/address signal (tried: pc, pc_addr, addr, address)"
    assert instr is not None, "Couldn't find an instruction/op signal (tried: instr, instruction, op, opcode, data, rd_data)"

    # Optional enables
    ena = pick_sig(dut, "ena", "en", "enable", "cs", "chip_en")
    if ena is not None:
        ena.value = 1

    # Size info (mask expected values to bus widths)
    pc_mask    = (1 << len(pc)) - 1
    instr_mask = (1 << len(instr)) - 1

    # Default other pins
    ui_in  = pick_sig(dut, "ui_in")
    uio_in = pick_sig(dut, "uio_in")
    if ui_in  is not None:  ui_in.value  = 0
    if uio_in is not None:  uio_in.value = 0

    await maybe_reset(dut)

    # Run through the table
    for addr, expected in PROGRAM.items():
        addr_m = addr & pc_mask
        exp_m  = expected & instr_mask

        await apply_pc_and_wait(dut, pc, instr, addr_m)

        # Basic "driven" check to catch X/Z
        assert fully_driven(instr), (
            f"Instruction bus has X/Z at PC=0x{addr_m:X}: {instr.value.binstr}"
        )

        got = int(instr.value)
        assert got == exp_m, (
            f"Mismatch at PC=0x{addr_m:X}: expected 0x{exp_m:0{(len(instr)+3)//4}X}, "
            f"got 0x{got:0{(len(instr)+3)//4}X}"
        )
