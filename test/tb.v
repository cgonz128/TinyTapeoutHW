`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
  tt_um_cgonz128 user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  // -------------------------------------------------
  // Assertion helper
  // -------------------------------------------------
  task automatic expect(input [7:0] exp, input string name);
    begin
      #1; // allow combinational settle
      assert (uo_out === exp)
        else begin
          $error("ASSERT FAIL (%s): got %0d (0x%02x), expected %0d (0x%02x)",
                 name, uo_out, uo_out, exp, exp);
          $fatal;
        end
      $display("PASS (%s): %0d (0x%02x)", name, uo_out, uo_out);
    end
  endtask

  // -------------------------------------------------
  // Tests
  // -------------------------------------------------
  initial begin
    // defaults
    clk   = 1'b0;
    rst_n = 1'b1;
    ena   = 1'b1;
    ui_in  = 8'h00;
    uio_in = 8'h00;

    $display("=== TinyTapeout ALU Assertion Test ===");

    // -------------------------
    // flog2 (uio_in[3])
    // -------------------------
    uio_in = 8'b0000_1000;
    ui_in  = 8'b0010_0000; // MSB = 5
    expect(8'd5, "flog2(0x20)");

    ui_in  = 8'b0000_0001;
    expect(8'd0, "flog2(0x01)");

    ui_in  = 8'b1000_0000;
    expect(8'd7, "flog2(0x80)");

    // -------------------------
    // OR (uio_in[2])
    // -------------------------
    uio_in = 8'b0000_0100;
    ui_in  = 8'b1101_0100;
    expect(8'b00001101, "OR");

    // -------------------------
    // ADD (uio_in[1])
    // -------------------------
    uio_in = 8'b0000_0010;
    ui_in  = 8'b0011_0010;
    expect(8'b0, "ADD");

    // -------------------------
    // SUB (uio_in[0])
    // -------------------------
    uio_in = 8'b0000_0100;
    ui_in  = 8'b0101_0001;
    expect(8'd4, "SUB");

    // -------------------------
    // Default case
    // -------------------------
    uio_in = 8'b0000_0000;
    ui_in  = 8'hFF;
    expect(8'd0, "DEFAULT");

    $display("🎉 ALL ASSERTIONS PASSED");
    $finish;
  end

endmodule
