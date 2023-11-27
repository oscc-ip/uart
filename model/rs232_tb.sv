// Copyright (c) 2023 Beijing Institute of Open Source Chip
// uart is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

module rs232_tb ();
  localparam BAUD_RATE = 115200;
  localparam DELAY_TIME = (10_0000_0000 / BAUD_RATE);

  string wave_name = "default.fsdb";
  logic rs232_tx, rs232_rx;
  logic [7:0] data;
  bit   [7:0] wr_val;

  task sim_config();
    $timeformat(-9, 1, "ns", 10);
    if ($test$plusargs("WAVE_ON")) begin
      $value$plusargs("WAVE_NAME=%s", wave_name);
      $fsdbDumpfile(wave_name);
      $fsdbDumpvars("+all");
    end
  endtask

  task automatic send(input bit [7:0] value);
    begin
      rs232_tx = 1'b0;
      #(DELAY_TIME);
      for (int i = 0; i < 8; i++) begin
        rs232_tx = value[i];
        #(DELAY_TIME);
      end
      rs232_tx = 1'b1;
      #(DELAY_TIME);
    end
  endtask

  task automatic receive(output bit [7:0] value);
    begin
      value = '0;
      #(DELAY_TIME * 1.5);
      for (int i = 0; i < 8; i++) begin
        value[i] = rs232_rx;
        #(DELAY_TIME);
      end
    end
  endtask

  always @(negedge rs232_rx) begin
    receive(data);
    $write("[REC]: %c", data);
  end


  task automatic test_rx();
    wr_val = 8'h41;
    for (int i = 0; i < 6; i++) begin
      for (int j = 0; j < 25; j++) begin
        send(wr_val + j);
        #200;
      end
      send(8'h0A);
    end
  endtask

  task automatic test_tx();
    u_rs232.send(8'h42);
  endtask

  initial begin
    sim_config();
    test_rx();
    test_tx();
    #2000000 $finish;
  end

  rs232 #(115200, 0) u_rs232 (
      .rs232_rx_i(rs232_tx),
      .rs232_tx_o(rs232_rx)
  );


endmodule
