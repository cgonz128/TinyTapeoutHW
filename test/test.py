# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


import cocotb
from cocotb.triggers import Timer


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # All test logic is in tb.v's initial block.
    # Wait long enough for it to complete (clock is 10ns period,
    # ~70 test cases with 1 cycle each + reset overhead = ~1us is plenty).
    await Timer(2, units="us")

    dut._log.info("Done - see tb.v output above for pass/fail details")