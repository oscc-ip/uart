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

// verilog_format: off
`define UART_LCR  4'b0000 //BASEADDR+0x00
`define UART_DIV  4'b0001 //BASEADDR+0x08
`define UART_TRX  4'b0010 //BASEADDR+0x04
`define UART_FCR  4'b0011 //BASEADDR+0x0C
`define UART_LSR  4'b0100 //BASEADDR+0x10
// verilog_format: on

/* register mapping
 * UART_LCR:
 * BITS:   | 31:9  | 8:7  | 6    | 5   | 4:3 | 2    | 1    | 0    |
 * FIELDS: | RES   | PS   | PEN  | STB | WLS | PEIE | TXIE | RXIE |
 * PERMS:  | NONE  | RW   | RW   | RW  | RW  | RW   | RW   | RW   |
 * ----------------------------------------------------------------
 * UART_DIV:
 * BITS:   | 31:16 | 15:0 |
 * FIELDS: | RES   | DIV  |
 * PERMS:  | NONE  | RW   |
 * ----------------------------------------------------------------
 * UART_FCR:
 * BITS:   | 31:4  | 3:2         | 1      | 0      |
 * FIELDS: | RES   | RX_TRG_LEVL | TF_CLR | RF_CLR |
 * PERMS:  | NONE  | W           | W      | W      |
 * ----------------------------------------------------------------
  * UART_TRX:
 * BITS:   | 31:8 | 7:0 || BITS:   | 31:8 | 7:0 |
 * FIELDS: | RES  | RX  || FIELDS: | RES  | TX  |
 * PERMS:  | NONE | R   || PERMS:  | NONE | W   |
 * ----------------------------------------------------------------
 * UART_LSR:
 * BITS:   | 31:7  | 6    | 5    | 4  | 3  | 2    | 1    | 0    |
 * FIELDS: | RES   | TEMT | THRE | PE | DR | PEIP | TXIP | RXIP |
 * PERMS:  | NONE  | R    | R    | R  | R  | R    | R    | R    |
 * ----------------------------------------------------------------
*/
module apb4_uart #(
    parameter int FIFO_DEPTH     = 16,
    parameter int LOG_FIFO_DEPTH = $clog2(FIFO_DEPTH)
) (
    // verilog_format: off
    apb4_if.slave apb4,
    // verilog_format: on
    input logic   uart_rx_i,
    output logic  uart_tx_o,
    output logic  irq_o
);

  logic [3:0] s_apb4_addr;
  logic [31:0] s_uart_lcr_d, s_uart_lcr_q;
  logic [31:0] s_uart_trx_d, s_uart_trx_q;
  logic [31:0] s_uart_div_d, s_uart_div_q;
  logic [31:0] s_uart_fcr_d, s_uart_fcr_q;
  logic [31:0] s_uart_lsr_d, s_uart_lsr_q;
  logic s_clr_int, s_parity_err;
  logic s_tx_push_valid, s_tx_push_ready, s_tx_pop_valid, s_tx_pop_ready;
  logic s_rx_pop_valid, s_rx_pop_ready;
  logic [2:0] s_lsr_ip;
  logic [7:0] s_tx_push_data, s_tx_pop_data;
  logic [8:0] s_rx_pop_data;
  logic [LOG_FIFO_DEPTH:0] s_tx_elem, s_rx_elem;

  assign s_apb4_addr = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready = 1'b1;
  assign apb4.pslverr = 1'b0;

  assign s_uart_lcr_d = (s_apb4_wr_hdshk && s_apb4_addr == `UART_LCR) ? apb4.pwdata : s_uart_lcr_q;
  dffr #(32) u_uart_lcr_dffr (
      apb4.pclk,
      apb4.presetn,
      s_uart_lcr_d,
      s_uart_lcr_q
  );

  assign s_uart_div_d = (s_apb4_wr_hdshk && s_apb4_addr == `UART_DIV) ? apb4.pwdata : s_uart_div_q;
  dffr #(32) u_uart_div_dffr (
      apb4.pclk,
      apb4.presetn,
      s_uart_div_d,
      s_uart_div_q
  );

  assign s_uart_fcr_d = (s_apb4_wr_hdshk && s_apb4_addr == `UART_FCR) ? apb4.pwdata : s_uart_fcr_q;
  dffr #(32) u_uart_fcr_dffr (
      apb4.pclk,
      apb4.presetn,
      s_uart_fcr_d,
      s_uart_fcr_q
  );

  always_comb begin
    s_tx_push_valid = 1'b0;
    if (s_apb4_wr_hdshk && s_apb4_addr == `UART_TRX) begin
      s_tx_push_valid = 1'b1;
      s_tx_push_data  = apb4.pwdata[7:0];
    end
  end

  always_comb begin
    s_uart_lsr_d      = s_uart_lsr_q;
    s_uart_lsr_d[2:0] = s_lsr_ip;
    s_uart_lsr_d[3]   = s_rx_pop_valid;
    s_uart_lsr_d[4]   = s_rx_pop_data[8];
    s_uart_lsr_d[5]   = ~(|s_tx_elem);
    s_uart_lsr_d[6]   = s_tx_pop_ready & ~(|s_tx_elem);
  end
  dffr #(32) u_uart_lsr_dffr (
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
        `UART_LCR: apb4.prdata = s_uart_lcr_q;
        `UART_DIV: apb4.prdata = s_uart_div_q;
        `UART_TRX: begin
          s_rx_pop_ready = 1'b1;
          apb4.prdata    = {24'b0, s_rx_pop_data[7:0]};
        end
        `UART_LSR: begin
          s_clr_int   = 1'b1;
          apb4.prdata = s_uart_lsr_q;
        end
      endcase
    end
  end

  fifo #(
      .DATA_WIDTH  (8),
      .BUFFER_DEPTH(FIFO_DEPTH)
  ) u_tx_fifo (
      .clk_i  (apb4.pclk),
      .rst_n_i(apb4.presetn),
      .flush_i(s_uart_fcr_q[1]),
      .cnt_o  (s_tx_elem),
      .push_i (s_tx_push_valid),
      .full_o (),
      .dat_i  (s_tx_push_data),
      .pop_i  (s_tx_pop_ready),
      .empty_o(s_tx_pop_valid),
      .dat_o  (s_tx_pop_data)
  );

  uart_tx u_uart_tx (
      .clk_i          (apb4.pclk),
      .rst_n_i        (apb4.presetn),
      .tx_o           (uart_tx_o),
      .busy_o         (),
      .cfg_en_i       (1'b1),
      .cfg_div_i      (s_uart_div_q[15:0]),
      .cfg_parity_en_i(s_uart_lcr_q[6]),
      .cfg_bits_i     (s_uart_lcr_q[4:3]),
      .cfg_stop_bits_i(s_uart_lcr_q[5]),
      .tx_data_i      (s_tx_pop_data),
      .tx_valid_i     (s_tx_pop_valid),
      .tx_ready_o     (s_tx_pop_ready)
  );

  fifo #(
      .DATA_WIDTH  (9),
      .BUFFER_DEPTH(FIFO_DEPTH)
  ) u_rx_fifo (
      .clk_i  (apb4.pclk),
      .rst_n_i(apb4.presetn),
      .flush_i(s_uart_fcr_q[0]),
      .cnt_o  (s_rx_elem),
      .push_i (s_rx_push_valid),
      .full_o (s_rx_push_ready),
      .dat_i  ({s_parity_err, s_rx_push_data}),
      .pop_i  (s_rx_pop_ready),
      .empty_o(s_rx_pop_valid),
      .dat_o  (s_rx_pop_data)
  );

  uart_rx u_uart_rx (
      .clk_i          (apb4.pclk),
      .rst_n_i        (apb4.presetn),
      .rx_i           (uart_rx_i),
      .busy_o         (),
      .cfg_div_i      (s_uart_div_q[15:0]),
      .cfg_parity_en_i(s_uart_lcr_q[6]),
      .cfg_bits_i     (s_uart_lcr_q[4:3]),
      .cfg_stop_bits_i(s_uart_lcr_q[5]),
      .err_o          (s_parity_err),
      .err_clr_i      (1'b1),
      .rx_data_o      (s_rx_push_data),
      .rx_valid_o     (s_rx_push_valid),
      .rx_ready_i     (s_rx_push_ready)
  );

  uart_irq #(
      .FIFO_DEPTH(FIFO_DEPTH)
  ) u_uart_irq (
      .clk_i      (apb4.pclk),
      .rst_n_i    (apb4.presetn),
      .clr_int_i  (s_clr_int),
      .irq_en_i   (s_uart_lcr_q[2:0]),
      .thre_i     (s_uart_lsr_q[5]),
      .cti_i      (1'b0),
      .pe_i       (s_uart_lsr_q[4]),
      .rx_elem_i  (s_rx_elem),
      .tx_elem_i  (s_tx_elem),
      .trg_level_i(s_uart_fcr_q[3:2]),
      .ip_o       (s_lsr_ip),
      .irq_o      (irq_o)
  );
endmodule

