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

  initial clk = 0;
  always #5 clk = ~clk;

  //test logic

  integer pass_count;
  integer fail_count;

  task apply_and_check;
    input [7:0] t_ui_in;
    input [7:0] t_uio_in;
    input [7:0] expected;
    input integer test_id;
    begin
      ui_in  = t_ui_in;
      uio_in = t_uio_in;
      @(posedge clk);
      #1;
      if (uo_out === expected) begin
        pass_count = pass_count + 1;
      end else begin
        $display("FAIL [test %0d]: ui_in=0x%02x uio_in=0x%02x  got=0x%02x  exp=0x%02x",
                 test_id, t_ui_in, t_uio_in, uo_out, expected);
        fail_count = fail_count + 1;
      end
    end
  endtask

  integer i;
  reg [7:0] a, b;

  initial begin
    pass_count = 0;
    fail_count = 0;

    // Reset
    ena   = 1;
    rst_n = 0;
    ui_in  = 8'h00;
    uio_in = 8'h00;
    repeat(2) @(posedge clk);
    rst_n = 1;
    @(posedge clk);

    // --- No-op (uio_in[3:0] = 0) ---
    $display("--- No-op ---");
    apply_and_check(8'hFF, 8'h00, 8'h00, 0);
    apply_and_check(8'h00, 8'h00, 8'h00, 1);

    // --- floor(log2(ui_in))  uio_in[3]=1 ---
    $display("--- floor(log2) ---");
    apply_and_check(8'b00000000, 8'b00001000, 8'd0, 10);
    apply_and_check(8'b00000001, 8'b00001000, 8'd0, 11);
    apply_and_check(8'b00000010, 8'b00001000, 8'd1, 12);
    apply_and_check(8'b00000100, 8'b00001000, 8'd2, 13);
    apply_and_check(8'b00001000, 8'b00001000, 8'd3, 14);
    apply_and_check(8'b00010000, 8'b00001000, 8'd4, 15);
    apply_and_check(8'b00100000, 8'b00001000, 8'd5, 16);
    apply_and_check(8'b01000000, 8'b00001000, 8'd6, 17);
    apply_and_check(8'b10000000, 8'b00001000, 8'd7, 18);
    apply_and_check(8'b11111111, 8'b00001000, 8'd7, 19);
    apply_and_check(8'b00001111, 8'b00001000, 8'd3, 20);

    // --- Bitwise OR  uio_in[2]=1 ---
    // A = {2'b00, ui_in[7:2]},  B = {2'b00, ui_in[1:0], uio_in[7:4]}
    $display("--- Bitwise OR ---");
    for (i = 0; i < 16; i = i + 1) begin
      ui_in  = $urandom & 8'hFF;
      uio_in = ($urandom & 8'hF0) | 8'h04;
      a = {2'b00, ui_in[7:2]};
      b = {2'b00, ui_in[1:0], uio_in[7:4]};
      apply_and_check(ui_in, uio_in, a | b, 100 + i);
    end
    apply_and_check(8'h00, 8'h04, 8'h00, 120);
    apply_and_check(8'hFF, 8'hF4, 8'h3F, 121);

    // --- Addition  uio_in[1]=1 ---
    $display("--- Addition ---");
    for (i = 0; i < 16; i = i + 1) begin
      ui_in  = $urandom & 8'hFF;
      uio_in = ($urandom & 8'hF0) | 8'h02;
      a = {2'b00, ui_in[7:2]};
      b = {2'b00, ui_in[1:0], uio_in[7:4]};
      apply_and_check(ui_in, uio_in, a + b, 200 + i);
    end
    apply_and_check(8'h00, 8'h02, 8'h00, 220);

    // --- Subtraction  uio_in[0]=1 ---
    $display("--- Subtraction ---");
    for (i = 0; i < 16; i = i + 1) begin
      ui_in  = $urandom & 8'hFF;
      uio_in = ($urandom & 8'hF0) | 8'h01;
      a = {2'b00, ui_in[7:2]};
      b = {2'b00, ui_in[1:0], uio_in[7:4]};
      apply_and_check(ui_in, uio_in, a - b, 300 + i);
    end
    apply_and_check(8'h00, 8'h01, 8'h00, 320);

    // --- Summary ---
    #10;
    $display("========================================");
    $display("Results: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count == 0)
      $display("ALL TESTS PASSED");
    else
      $display("SOME TESTS FAILED");
    $display("========================================");
    $finish;
  end

endmodule
