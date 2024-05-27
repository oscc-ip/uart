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

module uart_rx (
    input  logic        clk_i,
    input  logic        rst_n_i,
    input  logic        rx_i,
    output logic        busy_o,
    input  logic        cfg_en_i,
    input  logic [15:0] cfg_div_i,
    input  logic        cfg_parity_en_i,
    input  logic [ 1:0] cfg_parity_sel_i,
    input  logic [ 1:0] cfg_bits_i,
    output logic        err_o,
    input  logic        err_clr_i,
    output logic [ 7:0] rx_data_o,
    output logic        rx_valid_o,
    input  logic        rx_ready_i
);

  typedef enum logic [2:0] {
    IDLE,
    START_BIT,
    DATA,
    SAVE_DATA,
    PARITY,
    STOP_BIT
  } fsm_t;

  fsm_t s_fsm_d, s_fsm_q;

  logic [7:0] s_reg_data_d, s_reg_data_q;
  logic [2:0] reg_rx_sync, s_reg_bit_cnt_d, s_reg_bit_cnt_q;
  logic [2:0] s_target_bits;
  logic s_parity_bit_d, s_parity_bit_q;
  logic s_sample_data, s_baudgen_en, s_bit_done;
  logic s_start_bit, s_set_error, s_rx_fall;
  logic [15:0] s_baud_cnt;

  assign busy_o = (s_fsm_q != IDLE);
  always_comb begin
    unique case (cfg_bits_i)
      2'b00:   s_target_bits = 3'd4;
      2'b01:   s_target_bits = 3'd5;
      2'b10:   s_target_bits = 3'd6;
      2'b11:   s_target_bits = 3'd7;
      default: s_target_bits = 3'd4;
    endcase
  end

  always_comb begin
    s_sample_data   = 1'b0;
    rx_valid_o      = 1'b0;
    s_baudgen_en    = 1'b0;
    s_start_bit     = 1'b0;
    s_set_error     = 1'b0;
    s_fsm_d         = s_fsm_q;
    s_parity_bit_d  = s_parity_bit_q;
    s_reg_bit_cnt_d = s_reg_bit_cnt_q;
    s_reg_data_d    = s_reg_data_q;
    unique case (s_fsm_q)
      IDLE: begin
        if (s_rx_fall) begin
          s_fsm_d      = START_BIT;
          s_baudgen_en = 1'b1;
          s_start_bit  = 1'b1;
        end
      end
      START_BIT: begin
        s_parity_bit_d = 1'b0;
        s_baudgen_en   = 1'b1;
        s_start_bit    = 1'b1;
        if (s_bit_done) s_fsm_d = DATA;
      end
      DATA: begin
        s_baudgen_en   = 1'b1;
        s_parity_bit_d = s_parity_bit_q ^ reg_rx_sync[2];
        case (cfg_bits_i)
          2'b00: s_reg_data_d = {3'b000, reg_rx_sync[2], s_reg_data_q[4:1]};
          2'b01: s_reg_data_d = {2'b00, reg_rx_sync[2], s_reg_data_q[5:1]};
          2'b10: s_reg_data_d = {1'b0, reg_rx_sync[2], s_reg_data_q[6:1]};
          2'b11: s_reg_data_d = {reg_rx_sync[2], s_reg_data_q[7:1]};
        endcase

        if (s_bit_done) begin
          s_sample_data = 1'b1;
          if (s_reg_bit_cnt_q == s_target_bits) begin
            s_reg_bit_cnt_d = 'h0;
            s_fsm_d         = SAVE_DATA;
          end else begin
            s_reg_bit_cnt_d = s_reg_bit_cnt_q + 1;
          end
        end
      end
      SAVE_DATA: begin
        s_baudgen_en = 1'b1;
        rx_valid_o   = 1'b1;
        if (rx_ready_i)
          if (cfg_parity_en_i) s_fsm_d = PARITY;
          else s_fsm_d = STOP_BIT;
      end
      PARITY: begin
        s_baudgen_en = 1'b1;
        if (s_bit_done) begin
          unique case (cfg_parity_sel_i)
            2'b00: if (reg_rx_sync[2] != ~s_parity_bit_q) s_set_error = 1'b1;
            2'b01: if (reg_rx_sync[2] != s_parity_bit_q) s_set_error = 1'b1;
            2'b10: if (reg_rx_sync[2] != 1'b0) s_set_error = 1'b1;
            2'b11: if (reg_rx_sync[2] != 1'b1) s_set_error = 1'b1;
          endcase
          s_fsm_d = STOP_BIT;
        end
      end
      STOP_BIT: begin
        s_baudgen_en = 1'b1;
        if (s_bit_done) begin
          s_fsm_d = IDLE;
        end
      end
      default: s_fsm_d = IDLE;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_n_i) begin
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

  assign s_rx_fall = ~reg_rx_sync[1] & reg_rx_sync[2];
  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (~rst_n_i) reg_rx_sync <= 3'b111;
    else begin
      if (cfg_en_i) reg_rx_sync <= {reg_rx_sync[1:0], rx_i};
      else reg_rx_sync <= 3'b111;
    end
  end

  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (~rst_n_i) begin
      s_baud_cnt <= 'h0;
      s_bit_done <= 1'b0;
    end else begin
      if (s_baudgen_en) begin
        if (!s_start_bit && (s_baud_cnt == cfg_div_i)) begin
          s_baud_cnt <= 'h0;
          s_bit_done <= 1'b1;
        end else if (s_start_bit && (s_baud_cnt == {1'b0, cfg_div_i[15:1]})) begin
          s_baud_cnt <= 'h0;
          s_bit_done <= 1'b1;
        end else begin
          s_baud_cnt <= s_baud_cnt + 1;
          s_bit_done <= 1'b0;
        end
      end else begin
        s_baud_cnt <= 'h0;
        s_bit_done <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_n_i) begin
    if (~rst_n_i) begin
      err_o <= 1'b0;
    end else begin
      if (err_clr_i) begin
        err_o <= 1'b0;
      end else begin
        if (s_set_error) err_o <= 1'b1;
      end
    end
  end

  assign rx_data_o = s_reg_data_q;

endmodule
