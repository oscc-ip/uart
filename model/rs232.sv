// Copyright (c) 2023-2024 Miao Yuchi <miaoyuchi@ict.ac.cn>
// uart is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

module rs232 #(
    parameter int BAUD_RATE = 115200,
    parameter int LOOPBACK  = 0
) (
    input  logic rs232_rx_i,
    output logic rs232_tx_o
);

  // unit: ns
  localparam DELAY_TIME = (10_0000_0000 / BAUD_RATE);
  logic [7:0] data;

  initial begin
    rs232_tx_o = 1'b1;
  end
  always @(negedge rs232_rx_i) begin
    receive(data);
    $write("%c", data);
    if (LOOPBACK) send(data);
  end

  task automatic receive(output bit [7:0] value);
    begin
      value = '0;
      #(DELAY_TIME * 1.5);
      for (int i = 0; i < 8; i++) begin
        value[i] = rs232_rx_i;
        #(DELAY_TIME);
      end
    end
  endtask

  task automatic send(input bit [7:0] value);
    begin
      rs232_tx_o = 1'b0;
      #(DELAY_TIME);
      for (int i = 0; i < 8; i++) begin
        rs232_tx_o = value[i];
        #(DELAY_TIME);
      end
      rs232_tx_o = 1'b1;
      #(DELAY_TIME);
    end
  endtask
endmodule
