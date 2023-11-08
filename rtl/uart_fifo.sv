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

module uart_fifo #(
    parameter int DATA_WIDTH       = 8,
    parameter int BUFFER_DEPTH     = 16,
    parameter int LOG_BUFFER_DEPTH = $clog2(BUFFER_DEPTH)
) (
    input  logic                      clk_i,
    input  logic                      rst_n_i,
    input  logic                      clr_i,
    output logic [LOG_BUFFER_DEPTH:0] elements_o,
    input  logic                      push_valid_i,
    output logic                      push_ready_o,
    input  logic [  DATA_WIDTH-1 : 0] push_data_i,
    output logic                      pop_valid_o,
    input  logic                      pop_ready_i,
    output logic [  DATA_WIDTH-1 : 0] pop_data_o
);

  logic s_full;
  logic [LOG_BUFFER_DEPTH-1:0] r_push_point, r_pop_point, r_elements;
  logic [DATA_WIDTH-1:0] r_buffer[BUFFER_DEPTH - 1 : 0];

  assign s_full     = (r_elements == BUFFER_DEPTH);
  assign elements_o = r_elements;
  always_ff @(posedge clk_i, negedge rst_n_i) begin
    if (~rst_n_i || clr_i) begin
      r_elements <= '0;
    end else begin
      if (pop_ready_i && pop_valid_o && (!push_valid_i || !push_ready_o)) begin
        r_elements <= r_elements - 1;
      end else if ((!pop_valid_o || !pop_ready_i) && push_valid_i && push_ready_o) begin
        r_elements <= r_elements + 1;
      end
    end
  end

  always_ff @(posedge clk_i, negedge rst_n_i) begin
    if (~rst_n_i) begin
      for (int i = 0; i < BUFFER_DEPTH; i++) begin
        r_buffer[i] <= '0;
      end
    end else begin
      if (push_valid_i && push_ready_o) begin
        r_buffer[r_push_point] <= push_data_i;
      end
    end
  end

  always_ff @(posedge clk_i, negedge rst_n_i) begin
    if (~rst_n_i || clr_i) begin
      r_pop_point  <= '0;
      r_push_point <= '0;
    end else begin
      if (push_valid_i && push_ready_o) begin
        if (r_push_point == $unsigned(BUFFER_DEPTH - 1)) begin
          r_push_point <= '0;
        end else begin
          r_push_point <= r_push_point + 1'b1;
        end
      end
      if (pop_ready_i && pop_valid_o) begin
        if (r_pop_point == $unsigned(BUFFER_DEPTH - 1)) begin
          r_pop_point <= '0;
        end else begin
          r_pop_point <= r_pop_point + 1'b1;
        end
      end
    end
  end

  assign pop_data_o   = r_buffer[r_pop_point];
  assign pop_valid_o  = (r_elements != '0);
  assign push_ready_o = ~s_full;

endmodule
