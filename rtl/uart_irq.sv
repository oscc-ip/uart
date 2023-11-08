// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// -- Adaptable modifications are redistributed under compatible License --
//
// Copyright (c) 2023 Beijing Institute of Open Source Chip
// uart is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

module uart_irq #(
    parameter FIFO_DEPTH = 16
) (
    input  logic                        clk_i,
    input  logic                        rst_n_i,
    input  logic [                 2:0] irq_en_i,
    input  logic                        thre_i,
    input  logic                        cti_i,
    input  logic                        pe_i,
    input  logic [$clog2(FIFO_DEPTH):0] rx_elem_i,
    input  logic [$clog2(FIFO_DEPTH):0] tx_elem_i,
    input  logic [                 1:0] trg_level_i,
    input  logic [                 1:0] clr_int_i,
    output logic [                 1:0] iir_o,
    output logic                        irq_o
);

  logic [1:0] s_iir_n, s_iir_q;
  logic s_trg_level_done;

  always_comb begin
    s_trg_level_done = 1'b0;
    unique case (trg_level_i)
      2'b00: if ($unsigned(rx_elem_i) == 1) s_trg_level_done = 1'b1;
      2'b01: if ($unsigned(rx_elem_i) == 4) s_trg_level_done = 1'b1;
      2'b10: if ($unsigned(rx_elem_i) == 8) s_trg_level_done = 1'b1;
      2'b11: if ($unsigned(rx_elem_i) == 14) s_trg_level_done = 1'b1;
    endcase
  end

  always_comb begin
    if (clr_int_i == 2'b0) s_iir_n = s_iir_q;
    else s_iir_n = s_iir_q & ~(clr_int_i);

    if (irq_en_i[2] & pe_i) begin
      s_iir_n = 2'b00;
    end else if (irq_en_i[0] & (s_trg_level_done | thre_i)) begin
      s_iir_n = 2'b01;
    end else if (irq_en_i[0] & cti_i) begin
      s_iir_n = 2'b01;
    end else if (irq_en_i[1] & tx_elem_i == 0) begin
      s_iir_n = 2'b11;
    end
  end

  always_ff @(posedge clk_i, negedge rst_n_i) begin
    if (~rst_n_i) begin
      s_iir_q <= 2'b00;
    end else begin
      s_iir_q <= s_iir_n;
    end
  end

  assign iir_o = s_iir_q;
  assign irq_o = s_iir_q != 2'b00;

endmodule

