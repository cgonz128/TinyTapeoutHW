/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_cgonz128 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  wire [7:0] flog2;
  assign flog2 = (ui_in[7])? 8'd7: 
                (ui_in[6])? 8'd6: 
                (ui_in[5])? 8'd5:
                (ui_in[4])? 8'd4:
                (ui_in[3])? 8'd3:
                (ui_in[2])? 8'd2:
                (ui_in[1])? 8'd1:
                            8'd0;

  assign uo_out = (uio_in[3])?  flog2 :
                  (uio_in[2])?  {2'b00, ui_in[7:2]} | {2'b00, ui_in[1:0], uio_in[7:4]} :
                  (uio_in[1])?  {2'b00, ui_in[7:2]} + {2'b00, ui_in[1:0], uio_in[7:4]} :
                  (uio_in[0])?  {2'b00, ui_in[7:2]} - {2'b00, ui_in[1:0], uio_in[7:4]}: 0;
          
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
