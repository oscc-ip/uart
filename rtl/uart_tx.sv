// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// , agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express , implied. See the License for the
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

module uart_tx (
    input  logic        clk_i,
    input  logic        rst_n_i,
    output logic        tx_o,
    output logic        busy_o,
    input  logic        cfg_en_i,
    input  logic [15:0] cfg_div_i,         // NOTE: no parameterization
    input  logic        cfg_parity_en_i,
    input  logic [ 1:0] cfg_parity_sel_i,
    input  logic [ 1:0] cfg_bits_i,
    input  logic        cfg_stop_bits_i,
    input  logic [ 7:0] tx_data_i,
    input  logic        tx_valid_i,
    output logic        tx_ready_o
);

  typedef enum logic [2:0] {
    IDLE,
    START_BIT,
    DATA,
    PARITY,
    STOP_BIT_FIRST,
    STOP_BIT_LAST
  } fsm_t;

  fsm_t s_fsm_d, s_fsm_q;

  logic [7:0] s_reg_data_d, s_reg_data_q;
  logic [2:0] s_reg_bit_cnt_d, s_reg_bit_cnt_q;
  logic [2:0] s_target_bits;
  logic s_parity_bit_d, s_parity_bit_q;
  logic s_sample_data, s_baudgen_en, s_bit_done;
  logic [15:0] baud_cnt;  // NOTE: no parameterization

  assign busy_o = (s_fsm_q != IDLE);
  always_comb begin
    unique case (cfg_bits_i)
      2'b00: s_target_bits = 3'd4;
      2'b01: s_target_bits = 3'd5;
      2'b10: s_target_bits = 3'd6;
      2'b11: s_target_bits = 3'd7;
    endcase
  end

  always_comb begin
    s_fsm_d         = s_fsm_q;
    tx_o            = 1'b1;
    s_sample_data   = 1'b0;
    s_reg_bit_cnt_d = s_reg_bit_cnt_q;
    s_reg_data_d    = {1'b1, s_reg_data_q[7:1]};
    tx_ready_o      = 1'b0;
    s_baudgen_en    = 1'b0;
    s_parity_bit_d  = s_parity_bit_q;
    unique case (s_fsm_q)
      IDLE: begin
        if (cfg_en_i) tx_ready_o = 1'b1;
        if (tx_valid_i) begin
          s_fsm_d       = START_BIT;
          s_sample_data = 1'b1;
          s_reg_data_d  = tx_data_i;
        end
      end
      START_BIT: begin
        tx_o           = 1'b0;
        s_parity_bit_d = 1'b0;
        s_baudgen_en   = 1'b1;
        if (s_bit_done) s_fsm_d = DATA;
      end
      DATA: begin
        tx_o           = s_reg_data_q[0];
        s_baudgen_en   = 1'b1;
        s_parity_bit_d = s_parity_bit_q ^ s_reg_data_q[0];
        if (s_bit_done) begin
          if (s_reg_bit_cnt_q == s_target_bits) begin
            s_reg_bit_cnt_d = 'h0;
            if (cfg_parity_en_i) begin
              s_fsm_d = PARITY;
            end else begin
              s_fsm_d = STOP_BIT_FIRST;
            end
          end else begin
            s_reg_bit_cnt_d = s_reg_bit_cnt_q + 1;
            s_sample_data   = 1'b1;
          end
        end
      end
      PARITY: begin
        unique case (cfg_parity_sel_i)
          2'b00: tx_o = ~s_parity_bit_q;
          2'b01: tx_o = s_parity_bit_q;
          2'b10: tx_o = 1'b0;
          2'b11: tx_o = 1'b1;
        endcase

        s_baudgen_en = 1'b1;
        if (s_bit_done) s_fsm_d = STOP_BIT_FIRST;
      end
      STOP_BIT_FIRST: begin
        tx_o         = 1'b1;
        s_baudgen_en = 1'b1;
        if (s_bit_done) begin
          if (cfg_stop_bits_i) s_fsm_d = STOP_BIT_LAST;
          else s_fsm_d = IDLE;
        end
      end
      STOP_BIT_LAST: begin
        tx_o         = 1'b1;
        s_baudgen_en = 1'b1;
        if (s_bit_done) begin
          s_fsm_d = IDLE;
        end
      end
      default: s_fsm_d = IDLE;
    endcase
  end

  always_ff @(posedge clk_i, negedge rst_n_i) begin
    if (~rst_n_i) begin
      s_fsm_q         <= IDLE;
      s_reg_data_q    <= 8'hFF;
      s_reg_bit_cnt_q <= 'h0;
      s_parity_bit_q  <= 1'b0;
    end else begin
      if (s_bit_done) begin
        s_parity_bit_q <= s_parity_bit_d;
      end

      if (s_sample_data) begin
        s_reg_data_q <= s_reg_data_d;
      end

      s_reg_bit_cnt_q <= s_reg_bit_cnt_d;
      if (cfg_en_i) s_fsm_q <= s_fsm_d;
      else s_fsm_q <= IDLE;
    end
  end

  always_ff @(posedge clk_i, negedge rst_n_i) begin
    if (~rst_n_i) begin
      baud_cnt   <= 'h0;
      s_bit_done <= 1'b0;
    end else begin
      if (s_baudgen_en) begin
        if (baud_cnt == cfg_div_i) begin
          baud_cnt   <= 'h0;
          s_bit_done <= 1'b1;
        end else begin
          baud_cnt   <= baud_cnt + 1;
          s_bit_done <= 1'b0;
        end
      end else begin
        baud_cnt   <= 'h0;
        s_bit_done <= 1'b0;
      end
    end
  end

endmodule
