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

class UARTTest extends APB4Master;
  string                 name;
  int                    wr_val;
  virtual apb4_if.master apb4;

  extern function new(string name = "uart_test", virtual apb4_if.master apb4);
  extern task automatic test_reset_reg();
  extern task automatic test_wr_rd_reg(input bit [31:0] run_times = 1000);
  extern task automatic test_send();
  extern task automatic test_recv();
  extern task automatic test_irq(input bit [31:0] run_times = 10);
endclass

function UARTTest::new(string name, virtual apb4_if.master apb4);
  super.new("apb4_master", apb4);
  this.name   = name;
  this.wr_val = 0;
  this.apb4   = apb4;
endfunction

task automatic UARTTest::test_reset_reg();
  super.test_reset_reg();
  // verilog_format: off
  this.rd_check(`UART_LCR_ADDR, "LCR REG", 32'b0 & {`UART_LCR_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`UART_DIV_ADDR, "DIV REG", 32'd2 & {`UART_DIV_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`UART_TRX_ADDR, "TRX REG", 32'b0 & {`UART_TRX_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`UART_LSR_ADDR, "LSR REG", 32'h0e0 & {`UART_LSR_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  // verilog_format: on
endtask

task automatic UARTTest::test_wr_rd_reg(input bit [31:0] run_times = 1000);
  super.test_wr_rd_reg();
  // verilog_format: off
  for (int i = 0; i < run_times; i++) begin
    this.wr_rd_check(`UART_LCR_ADDR, "LCR REG", $random & {`UART_LCR_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_val = $random;
    if(this.wr_val < 2) this.wr_val = 2;
    this.wr_rd_check(`UART_DIV_ADDR, "DIV REG", this.wr_val & {`UART_DIV_WIDTH{1'b1}}, Helper::EQUL);
  end
  // verilog_format: on
endtask

task automatic UARTTest::test_send();
  $display("=== [test test send] ===");
  this.write(`UART_LCR_ADDR, 32'b0 & {`UART_LCR_WIDTH{1'b1}});
  this.write(`UART_DIV_ADDR, 32'h363 & {`UART_DIV_WIDTH{1'b1}});  // 115200bps
  this.write(`UART_FCR_ADDR, 32'b1111 & {`UART_FCR_WIDTH{1'b1}});
  this.write(`UART_FCR_ADDR, 32'b1100 & {`UART_FCR_WIDTH{1'b1}});
  this.write(`UART_LCR_ADDR, 32'b00_0_0_11_111 & {`UART_LCR_WIDTH{1'b1}});

  repeat (1000) @(posedge this.apb4.pclk);
  this.wr_val = 32'h41;
  for (int i = 0; i < 48; i++) begin
    do begin
      this.read(`UART_LSR_ADDR);
    end while (super.rd_data[8] == 1'b1);

    this.write(`UART_TRX_ADDR, (this.wr_val + i) & {`UART_TRX_WIDTH{1'b1}});
    // $display("%c", this.wr_val + i);
    // repeat (5000 * 12) @(posedge this.apb4.pclk);
  end

  repeat (5000 * 12 * 26) @(posedge this.apb4.pclk);
  this.read(`UART_LSR_ADDR);
  $display("\n%t: [WR]LSR: %h TEMT BIT: %h", $time, super.rd_data, super.rd_data[6]);

endtask

task automatic UARTTest::test_recv();
  $display("=== [test test recv] ===");
  this.write(`UART_LCR_ADDR, 32'b0 & {`UART_LCR_WIDTH{1'b1}});
  this.write(`UART_DIV_ADDR, 32'h363 & {`UART_DIV_WIDTH{1'b1}});  // 115200bps
  // this.write(`UART_FCR_ADDR, 32'b1111 & {`UART_FCR_WIDTH{1'b1}});
  this.write(`UART_FCR_ADDR, 32'b1100 & {`UART_FCR_WIDTH{1'b1}});
  this.write(`UART_LCR_ADDR, 32'b00_0_0_11_111 & {`UART_LCR_WIDTH{1'b1}});
  repeat (1000) @(posedge this.apb4.pclk);

  while (1) begin
    this.read(`UART_LSR_ADDR);
    $display("\n%t: [RD]LSR: %h DR BIT: %h", $time, super.rd_data, super.rd_data[3]);
    if (super.rd_data[3] == 1'b0) begin
      break;
    end
    this.read(`UART_TRX_ADDR);
    $display("%t [RECV]: %c hex: %h", $time, super.rd_data, super.rd_data);
  end
endtask

task automatic UARTTest::test_irq(input bit [31:0] run_times = 10);
  super.test_irq();
endtask
