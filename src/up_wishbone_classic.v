//******************************************************************************
// file:    up_wishbone_classic.v
//
// author:  JAY CONVERTINO
//
// date:    2024/03/01
//
// about:   Brief
// Wishbone Classic slave to uP interface
//
// license: License MIT
// Copyright 2024 Jay Convertino
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
//
//******************************************************************************

`timescale 1ns/100ps

/*
 * Module: up_wishbone_classic
 *
 * Wishbone Classic slave to uP up_wishbone_classic
 *
 * Parameters:
 *
 *   ADDRESS_WIDTH   - Width of the Wishbone address port in bits.
 *   BUS_WIDTH       - Width of the Wishbone bus data port in bytes.
 *
 * Ports:
 *
 *   clk              - Clock
 *   rst              - Positive reset
 *   s_wb_cyc         - Bus Cycle in process
 *   s_wb_stb         - Valid data transfer cycle
 *   s_wb_we          - Active High write, low read
 *   s_wb_addr        - Bus address
 *   s_wb_data_i      - Input data
 *   s_wb_sel         - Device Select
 *   s_wb_bte         - Burst Type Extension
 *   s_wb_cti         - Cycle Type
 *   s_wb_ack         - Bus transaction terminated
 *   s_wb_data_o      - Output data
 *   s_wb_err         - Active high when a bus error is present
 *   up_rreq          - uP bus read request
 *   up_rack          - uP bus read ack
 *   up_raddr         - uP bus read address
 *   up_rdata         - uP bus read data
 *   up_wreq          - uP bus write request
 *   up_wack          - uP bus write ack
 *   up_waddr         - uP bus write address
 *   up_wdata         - uP bus write data
 */
module up_wishbone_classic #(
    parameter ADDRESS_WIDTH = 16,
    parameter BUS_WIDTH     = 4
  ) 
  (
    input                                           clk,
    input                                           rst,
    input                                           s_wb_cyc,
    input                                           s_wb_stb,
    input                                           s_wb_we,
    input   [ADDRESS_WIDTH-1:0]                     s_wb_addr,
    input   [BUS_WIDTH*8-1:0]                       s_wb_data_i,
    input   [BUS_WIDTH-1:0]                         s_wb_sel,
    input   [ 1:0]                                  s_wb_bte,
    input   [ 2:0]                                  s_wb_cti,
    output                                          s_wb_ack,
    output  [BUS_WIDTH*8-1:0]                       s_wb_data_o,
    output                                          s_wb_err,
    output                                          up_rreq,
    input                                           up_rack,
    output  [ADDRESS_WIDTH-(BUS_WIDTH/2)-1:0]       up_raddr,
    input   [BUS_WIDTH*8-1:0]                       up_rdata,
    output                                          up_wreq,
    input                                           up_wack,
    output  [ADDRESS_WIDTH-(BUS_WIDTH/2)-1:0]       up_waddr,
    output  [BUS_WIDTH*8-1:0]                       up_wdata
  );

  `include "wb_common.v"

  localparam shift = BUS_WIDTH/2;

  genvar index;

  wire          valid;
  wire          up_ack;

  reg [ADDRESS_WIDTH-1:0] r_wb_addr;
  reg                     r_req;
  reg                     r_err;
  reg [ 7:0]              r_rst;

  // var: valid
  // Indicate valid request from wishbone.
  assign valid = s_wb_cyc & s_wb_stb & ~r_rst[0] & ~r_err;

  // var: up_rreq
  // Convert wishbone read requests to up requests
  assign up_rreq  = ~s_wb_we & r_req;

  // var: up_wreq
  // Convert wishbone write requests to up requests
  assign up_wreq  =  s_wb_we & r_req;

  // var: s_wb_err
  // check for burst address errors
  assign s_wb_err =  r_err;

  // var: up_raddr
  // assign address to read address port if selected
  assign up_raddr = (~s_wb_we & ~r_rst[0] ? s_wb_addr[ADDRESS_WIDTH-1:shift] : 0);

  // var: up_waddr
  // assign address to write address port if selected
  assign up_waddr = ( s_wb_we & ~r_rst[0] ? s_wb_addr[ADDRESS_WIDTH-1:shift] : 0);

  // var: up_ack
  // ack is ack for both, or them so either may pass
  assign up_ack = (up_rack | up_wack);

  // var: s_wb_ack
  // combined uP ack is wishbone ack.
  assign s_wb_ack = up_ack;

  //part select write
  //part select isn't supported by the uP interface. Needs to be added outside the core to the device if needed.
  generate
    for(index = 0; index < BUS_WIDTH; index = index + 1)
    begin
      assign up_wdata[((index+1)*8)-1:index*8] = ((~r_rst[0] | ~s_wb_sel[index]) ? s_wb_data_i[((index+1)*8)-1:index*8] : 0);
    end
  endgenerate

  //part select read
  //part select isn't supported by the uP interface. Needs to be added outside the core to the device if needed.
  generate
    for(index = 0; index < BUS_WIDTH; index = index + 1)
    begin
      assign s_wb_data_o[((index+1)*8)-1:index*8] = ((~r_rst[0] | s_wb_sel[index]) ? up_rdata[((index+1)*8)-1:index*8] : 0);
    end
  endgenerate

  // Burst state control
  always @(posedge clk)
  begin
    if(r_rst[0]) begin
      r_req <= 1'b0;
      r_err <= 1'b0;
      r_wb_addr <= 0;
    end else begin
      r_err     <= 1'b0;
      r_wb_addr <= s_wb_addr;

      case(s_wb_cti)
        CTI_CLASSIC:
        begin
          r_req <= valid & !up_ack;
        end
        CTI_CONST_BURST:
        begin
          r_req <= valid;

          if((r_wb_addr != s_wb_addr) && r_req)
          begin
            r_err <= 1'b1;
          end
        end
        CTI_INC_BURST:
        begin
          r_req <= valid;

          if((s_wb_addr != wb_next_adr(r_wb_addr, s_wb_cti, s_wb_bte, BUS_WIDTH * 8)) && r_req)
          begin
            r_err <= 1'b1;
          end
        end
        CTI_END_OF_BURST:
        begin
          r_req <= valid & !up_ack;
        end
        default:
        begin
          r_req <= 1'b0;
          r_err <= 1'b1;
        end
      endcase
    end
  end

  //hold reset for 8 more clock cycles to help with routing
  always @(posedge clk)
  begin
    if(rst)
    begin
      r_rst <= ~0;
    end else begin
      r_rst <= {1'b0, r_rst[7:1]};
    end
  end
endmodule
