// Copyright (c) 2023 Beijing Institute of Open Source Chip
// uart is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`include "apb4_if.sv"
`include "uart_define.sv"

module apb4_uart_tb ();
  localparam CLK_PEROID = 10;
  logic rst_n_i, clk_i;
  bit [7:0] wr_val;

  initial begin
    clk_i = 1'b0;
    forever begin
      #(CLK_PEROID / 2) clk_i <= ~clk_i;
    end
  end

  task sim_reset(int delay);
    rst_n_i = 1'b0;
    repeat (delay) @(posedge clk_i);
    #1 rst_n_i = 1'b1;
  endtask

  initial begin
    sim_reset(40);
    #16741626;
    while (1) begin
      wr_val = 8'h41;  // 0100_0011 -> 1100_0010
      for (int i = 0; i < 10; i++) begin
        u_rs232.send(wr_val + i);
      end
    end
    #16741626;
    $finish;
  end

  apb4_if u_apb4_if (
      clk_i,
      rst_n_i
  );

  uart_if u_uart_if ();

  test_top u_test_top (.apb4(u_apb4_if.master));
  apb4_uart u_apb4_uart (
      .apb4(u_apb4_if.slave),
      .uart(u_uart_if.dut)
  );

  rs232 #(115200, 0) u_rs232 (
      .rs232_rx_i(u_uart_if.uart_tx_o),
      .rs232_tx_o(u_uart_if.uart_rx_i)
  );

endmodule
