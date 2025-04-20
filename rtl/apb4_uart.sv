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
// Copyright (c) 2023-2024 Miao Yuchi <miaoyuchi@ict.ac.cn>
// uart is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`include "uart_define.svh"

module apb4_uart #(
    parameter int FIFO_DEPTH     = 32,
    parameter int LOG_FIFO_DEPTH = $clog2(FIFO_DEPTH)
) (
    apb4_if.slave apb4,
    uart_if.dut   uart
);

  logic [3:0] s_apb4_addr;
  logic s_apb4_wr_hdshk, s_apb4_rd_hdshk;
  logic [`UART_LCR_WIDTH-1:0] s_uart_lcr_d, s_uart_lcr_q;
  logic s_uart_lcr_en;
  logic [`UART_DIV_WIDTH-1:0] s_uart_div_d, s_uart_div_q;
  logic s_uart_div_en;
  logic [`UART_FCR_WIDTH-1:0] s_uart_fcr_d, s_uart_fcr_q;
  logic s_uart_fcr_en;
  logic [`UART_LSR_WIDTH-1:0] s_uart_lsr_d, s_uart_lsr_q;
  logic s_bit_stb, s_bit_pen, s_bit_rf_clr, s_bit_tf_clr;
  logic s_bit_pe, s_bit_thre;
  logic [1:0] s_bit_wls, s_bit_ps, s_bit_rx_trg_levl;
  logic [2:0] s_bit_ie;
  logic s_clr_int, s_parity_err;
  logic s_tx_push_valid, s_tx_push_ready, s_tx_empty, s_tx_full;
  logic s_tx_pop_valid, s_tx_pop_ready;
  logic s_rx_push_valid, s_rx_push_ready, s_rx_empty, s_rx_full;
  logic s_rx_pop_valid, s_rx_pop_ready;
  logic [2:0] s_lsr_ip;
  logic [7:0] s_tx_push_data, s_tx_pop_data, s_rx_push_data;
  logic [8:0] s_rx_pop_data;
  logic [LOG_FIFO_DEPTH:0] s_tx_elem, s_rx_elem;

  assign s_apb4_addr       = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk   = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk   = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready       = 1'b1;
  assign apb4.pslverr      = 1'b0;

  assign s_bit_ie          = s_uart_lcr_q[2:0];
  assign s_bit_wls         = s_uart_lcr_q[4:3];
  assign s_bit_stb         = s_uart_lcr_q[5];
  assign s_bit_pen         = s_uart_lcr_q[6];
  assign s_bit_ps          = s_uart_lcr_q[8:7];

  assign s_bit_rf_clr      = s_uart_fcr_q[0];
  assign s_bit_tf_clr      = s_uart_fcr_q[1];
  assign s_bit_rx_trg_levl = s_uart_fcr_q[3:2];

  assign s_bit_pe          = s_uart_lsr_q[4];
  assign s_bit_thre        = s_uart_lsr_q[5];

  assign s_uart_lcr_en     = s_apb4_wr_hdshk && s_apb4_addr == `UART_LCR;
  assign s_uart_lcr_d      = apb4.pwdata[`UART_LCR_WIDTH-1:0];
  dffer #(`UART_LCR_WIDTH) u_uart_lcr_dffer (
      apb4.pclk,
      apb4.presetn,
      s_uart_lcr_en,
      s_uart_lcr_d,
      s_uart_lcr_q
  );

  assign s_uart_div_en = s_apb4_wr_hdshk && s_apb4_addr == `UART_DIV;
  assign s_uart_div_d  = apb4.pwdata[`UART_DIV_WIDTH-1:0];
  dfferc #(`UART_DIV_WIDTH, `UART_DIV_MIN_VAL) u_uart_div_dfferc (
      apb4.pclk,
      apb4.presetn,
      s_uart_div_en,
      s_uart_div_d,
      s_uart_div_q
  );

  always_comb begin
    s_tx_push_valid = 1'b0;
    s_tx_push_data  = '0;
    if (s_apb4_wr_hdshk && s_apb4_addr == `UART_TRX) begin
      s_tx_push_valid = 1'b1;
      s_tx_push_data  = apb4.pwdata[`UART_TRX_WIDTH-1:0];
    end
  end

  assign s_uart_fcr_en = s_apb4_wr_hdshk && s_apb4_addr == `UART_FCR;
  assign s_uart_fcr_d  = apb4.pwdata[`UART_FCR_WIDTH-1:0];
  dffer #(`UART_FCR_WIDTH) u_uart_fcr_dffer (
      apb4.pclk,
      apb4.presetn,
      s_uart_fcr_en,
      s_uart_fcr_d,
      s_uart_fcr_q
  );

  always_comb begin
    s_uart_lsr_d[2:0] = s_lsr_ip;
    s_uart_lsr_d[3]   = s_rx_pop_valid;
    s_uart_lsr_d[4]   = s_rx_pop_data[8];
    s_uart_lsr_d[5]   = ~(|s_tx_elem);
    s_uart_lsr_d[6]   = s_tx_pop_ready & ~(|s_tx_elem);
    s_uart_lsr_d[7]   = s_rx_empty;
    s_uart_lsr_d[8]   = s_tx_full;
  end
  dffrc #(`UART_LSR_WIDTH, `UART_LSR_RESET_VAL) u_uart_lsr_dffrc (
      apb4.pclk,
      apb4.presetn,
      s_uart_lsr_d,
      s_uart_lsr_q
  );

  always_comb begin
    apb4.prdata    = '0;
    s_rx_pop_ready = 1'b0;
    s_clr_int      = 1'b0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb4_addr)
        `UART_LCR: apb4.prdata[`UART_LCR_WIDTH-1:0] = s_uart_lcr_q;
        `UART_DIV: apb4.prdata[`UART_DIV_WIDTH-1:0] = s_uart_div_q;
        `UART_TRX: begin
          s_rx_pop_ready                   = 1'b1;
          apb4.prdata[`UART_TRX_WIDTH-1:0] = s_rx_pop_data[7:0];
        end
        `UART_LSR: begin
          s_clr_int                        = 1'b1;
          apb4.prdata[`UART_LSR_WIDTH-1:0] = s_uart_lsr_q;
        end
        default:   apb4.prdata = '0;
      endcase
    end
  end

  assign s_tx_push_ready = ~s_tx_full;
  assign s_tx_pop_valid  = ~s_tx_empty;
  fifo #(
      .DATA_WIDTH  (8),
      .BUFFER_DEPTH(FIFO_DEPTH)
  ) u_tx_fifo (
      .clk_i  (apb4.pclk),
      .rst_n_i(apb4.presetn),
      .flush_i(s_bit_tf_clr),
      .cnt_o  (s_tx_elem),
      .push_i (s_tx_push_valid),
      .full_o (s_tx_full),
      .dat_i  (s_tx_push_data),
      .pop_i  (s_tx_pop_ready),
      .empty_o(s_tx_empty),
      .dat_o  (s_tx_pop_data)
  );

  uart_tx u_uart_tx (
      .clk_i           (apb4.pclk),
      .rst_n_i         (apb4.presetn),
      .tx_o            (uart.uart_tx_o),
      .busy_o          (),
      .cfg_en_i        (1'b1),
      .cfg_div_i       (s_uart_div_q[`UART_DIV_WIDTH-1:0]),
      .cfg_parity_en_i (s_bit_pen),
      .cfg_parity_sel_i(s_bit_ps),
      .cfg_bits_i      (s_bit_wls),
      .cfg_stop_bits_i (s_bit_stb),
      .tx_data_i       (s_tx_pop_data),
      .tx_valid_i      (s_tx_pop_valid),
      .tx_ready_o      (s_tx_pop_ready)
  );

  assign s_rx_push_ready = ~s_rx_full;
  assign s_rx_pop_valid  = ~s_rx_empty;
  fifo #(
      .DATA_WIDTH  (9),
      .BUFFER_DEPTH(FIFO_DEPTH)
  ) u_rx_fifo (
      .clk_i  (apb4.pclk),
      .rst_n_i(apb4.presetn),
      .flush_i(s_bit_rf_clr),
      .cnt_o  (s_rx_elem),
      .push_i (s_rx_push_valid),
      .full_o (s_rx_full),
      .dat_i  ({s_parity_err, s_rx_push_data}),
      .pop_i  (s_rx_pop_ready),
      .empty_o(s_rx_empty),
      .dat_o  (s_rx_pop_data)
  );

  uart_rx u_uart_rx (
      .clk_i           (apb4.pclk),
      .rst_n_i         (apb4.presetn),
      .rx_i            (uart.uart_rx_i),
      .busy_o          (),
      .cfg_en_i        (1'b1),
      .cfg_div_i       (s_uart_div_q[`UART_DIV_WIDTH-1:0]),
      .cfg_parity_en_i (s_bit_pen),
      .cfg_parity_sel_i(s_bit_ps),
      .cfg_bits_i      (s_bit_wls),
      .err_o           (s_parity_err),
      .err_clr_i       (1'b1),
      .rx_data_o       (s_rx_push_data),
      .rx_valid_o      (s_rx_push_valid),
      .rx_ready_i      (s_rx_push_ready)
  );

  uart_irq #(
      .FIFO_DEPTH(FIFO_DEPTH)
  ) u_uart_irq (
      .clk_i      (apb4.pclk),
      .rst_n_i    (apb4.presetn),
      .clr_int_i  (s_clr_int),
      .irq_en_i   (s_bit_ie),
      .thre_i     (s_bit_thre),
      .cti_i      (1'b0),
      .pe_i       (s_bit_pe),
      .rx_elem_i  (s_rx_elem),
      .tx_elem_i  (s_tx_elem),
      .trg_level_i(s_bit_rx_trg_levl),
      .ip_o       (s_lsr_ip),
      .irq_o      (uart.irq_o)
  );
endmodule

