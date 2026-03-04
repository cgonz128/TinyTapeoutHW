# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Operations are selected by uio_in[3:0] (one-hot):
    #   uio_in[3] -> floor(log2(ui_in))
    #   uio_in[2] -> A | B
    #   uio_in[1] -> A + B
    #   uio_in[0] -> A - B
    # where:
    #   A = {2'b00, ui_in[7:2]}
    #   B = {2'b00, ui_in[1:0], uio_in[7:4]}

    # --- floor(log2) ---
    for ui, expected in [
        (0b00000000, 0),
        (0b00000001, 0),
        (0b00000010, 1),
        (0b00000100, 2),
        (0b00001000, 3),
        (0b00010000, 4),
        (0b00100000, 5),
        (0b01000000, 6),
        (0b10000000, 7),
        (0b11111111, 7),
        (0b00001111, 3),
    ]:
        dut.ui_in.value = ui
        dut.uio_in.value = 0b00001000  # uio_in[3]=1
        await ClockCycles(dut.clk, 1)
        assert dut.uo_out.value == expected, \
            f"floor(log2): ui_in={ui:#010b} expected={expected} got={dut.uo_out.value}"

    # --- Bitwise OR ---
    for ui, uio, expected in [
        (0x00, 0x04, 0x00),
        (0xFF, 0xF4, 0x3F),
        (0b11001100, 0b10100100, (0b00110011 | 0b00001010)),  # A=0x33, B=0x0A
    ]:
        dut.ui_in.value  = ui
        dut.uio_in.value = uio  # uio_in[2]=1
        await ClockCycles(dut.clk, 1)
        a = (ui >> 2) & 0x3F
        b = ((ui & 0x03) << 4) | ((uio >> 4) & 0x0F)
        exp = a | b
        assert dut.uo_out.value == exp, \
            f"OR: ui_in={ui:#04x} uio_in={uio:#04x} expected={exp} got={dut.uo_out.value}"

    # --- Addition ---
    for ui, uio in [
        (0x00, 0x02),
        (0xFF, 0x02),
        (0x14, 0x1E),  # original template values: ui_in=20, uio_in=30
        (0b10110100, 0b11010010),
    ]:
        dut.ui_in.value  = ui
        dut.uio_in.value = uio  # uio_in[1]=1
        await ClockCycles(dut.clk, 1)
        a = (ui >> 2) & 0x3F
        b = ((ui & 0x03) << 4) | ((uio >> 4) & 0x0F)
        exp = (a + b) & 0xFF
        assert dut.uo_out.value == exp, \
            f"ADD: ui_in={ui:#04x} uio_in={uio:#04x} expected={exp} got={dut.uo_out.value}"

    # --- Subtraction ---
    for ui, uio in [
        (0x00, 0x01),
        (0xFF, 0xF1),
        (0b11111100, 0b00000001),  # A=0x3F, B=0x00 -> 0x3F
    ]:
        dut.ui_in.value  = ui
        dut.uio_in.value = uio  # uio_in[0]=1
        await ClockCycles(dut.clk, 1)
        a = (ui >> 2) & 0x3F
        b = ((ui & 0x03) << 4) | ((uio >> 4) & 0x0F)
        exp = (a - b) & 0xFF
        assert dut.uo_out.value == exp, \
            f"SUB: ui_in={ui:#04x} uio_in={uio:#04x} expected={exp} got={dut.uo_out.value}"

    dut._log.info("All tests passed")
