// Copyright (c) 2023-2024 Miao Yuchi <miaoyuchi@ict.ac.cn>
// uart is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_UART_DEF_SV
`define INC_UART_DEF_SV

/* register mapping
 * UART_LCR:
 * BITS:   | 31:9 | 8:7 | 6   | 5   | 4:3 | 2    | 1    | 0    |
 * FIELDS: | RES  | PS  | PEN | STB | WLS | PEIE | TXIE | RXIE |
 * PERMS:  | NONE | RW  | RW  | RW  | RW  | RW   | RW   | RW   |
  * --------------------------------------------------------------------------
 * UART_DIV:
 * BITS:   | 31:16 | 15:0 |
 * FIELDS: | RES   | DIV  |
 * PERMS:  | NONE  | RW   |
  * --------------------------------------------------------------------------
 * UART_TRX:
 * BITS:   | 31:8 | 7:0 || BITS:   | 31:8 | 7:0 |
 * FIELDS: | RES  | RX  || FIELDS: | RES  | TX  |
 * PERMS:  | NONE | RO  || PERMS:  | NONE | WO  |
  * --------------------------------------------------------------------------
 * UART_FCR:
 * BITS:   | 31:4 | 3:2         | 1      | 0      |
 * FIELDS: | RES  | RX_TRG_LEVL | TF_CLR | RF_CLR |
 * PERMS:  | NONE | WO          | WO     | WO     |
 * ---------------------------------------------------------------------------
 * UART_LSR:
 * BITS:   | 31:9 | 8    | 7    | 6    | 5    | 4  | 3  | 2    | 1    | 0    |
 * FIELDS: | RES  | FULL | EMPT | TEMT | THRE | PE | DR | PEIP | TXIP | RXIP |
 * PERMS:  | NONE | RO   | RO   | RO   | RO   | RO | RO | RO   | RO   | RO   |
 * ---------------------------------------------------------------------------
*/

// verilog_format: off
`define UART_LCR 4'b0000 // BASEADDR + 0x00
`define UART_DIV 4'b0001 // BASEADDR + 0x04
`define UART_TRX 4'b0010 // BASEADDR + 0x08
`define UART_FCR 4'b0011 // BASEADDR + 0x0C
`define UART_LSR 4'b0100 // BASEADDR + 0x10

`define UART_LCR_ADDR {26'b0, `UART_LCR, 2'b00}
`define UART_DIV_ADDR {26'b0, `UART_DIV, 2'b00}
`define UART_TRX_ADDR {26'b0, `UART_TRX, 2'b00}
`define UART_FCR_ADDR {26'b0, `UART_FCR, 2'b00}
`define UART_LSR_ADDR {26'b0, `UART_LSR, 2'b00}

`define UART_LCR_WIDTH 9
`define UART_DIV_WIDTH 16
`define UART_TRX_WIDTH 8
`define UART_FCR_WIDTH 4
`define UART_LSR_WIDTH 9

`define UART_DIV_MIN_VAL  {{(`UART_DIV_WIDTH-2){1'b0}}, 2'd2}
`define UART_LSR_RESET_VAL 9'h0E0
// verilog_format: on

`endif
