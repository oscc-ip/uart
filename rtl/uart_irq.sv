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
    parameter FIFO_DEPTH     = 16,
    parameter LOG_FIFO_DEPTH = $clog2(FIFO_DEPTH)

) (
    input  logic                    clk_i,
    input  logic                    rst_n_i,
    input  logic                    clr_int_i,
    input  logic [             2:0] irq_en_i,
    input  logic                    thre_i,
    input  logic                    cti_i,
    input  logic                    pe_i,
    input  logic [LOG_FIFO_DEPTH:0] rx_elem_i,
    input  logic [LOG_FIFO_DEPTH:0] tx_elem_i,
    input  logic [             1:0] trg_level_i,
    output logic [             2:0] ip_o,
    output logic                    irq_o
);

  logic [2:0] s_ip_d, s_ip_q;
  logic s_trg_level_done;

  always_comb begin
    s_trg_level_done = 1'b0;
    unique case (trg_level_i)
      2'b00:   if (rx_elem_i == 4'd1) s_trg_level_done = 1'b1;
      2'b01:   if (rx_elem_i == 4'd2) s_trg_level_done = 1'b1;
      2'b10:   if (rx_elem_i == 4'd8) s_trg_level_done = 1'b1;
      2'b11:   if (rx_elem_i == 4'd14) s_trg_level_done = 1'b1;
      default: s_trg_level_done = 1'b0;
    endcase
  end

  always_comb begin
    s_ip_d = s_ip_q;
    if (clr_int_i) begin
      s_ip_d = 3'b000;
    end else if (irq_en_i[2] & pe_i) begin
      s_ip_d = 3'b100;
    end else if (irq_en_i[1] & tx_elem_i == 0) begin
      s_ip_d = 3'b010;
    end else if (irq_en_i[0] & (s_trg_level_done | thre_i)) begin
      s_ip_d = 3'b001;
    end else if (irq_en_i[0] & cti_i) begin
      s_ip_d = 3'b001;
    end
  end

  dffr #(3) u_ip_dffr (
      clk_i,
      rst_n_i,
      s_ip_d,
      s_ip_q
  );

  assign ip_o  = s_ip_q;
  assign irq_o = s_ip_q != 3'b000;

endmodule

