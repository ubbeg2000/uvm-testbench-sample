module fifo #(
  parameter DATA_WIDTH = 8,
  parameter MEMORY_DEPTH = 8
) (
  input clk,
  
  // control signals
  input rst,
  input r_en,
  input w_en,
  
  // data signals
  output [DATA_WIDTH-1:0] r_data,
  input [DATA_WIDTH-1:0] w_data,
  
  // status flags
  output empty,
  output full,
  output [7:0] count
);
  bit [DATA_WIDTH-1:0] mem [0:MEMORY_DEPTH-1];
  logic [$clog2(MEMORY_DEPTH)-1:0] r_ptr = 0, w_ptr = 0;
  logic [$clog2(MEMORY_DEPTH):0] cnt = 0, next_cnt = 0;
  
  int next_w_ptr, w_ptr_inc;
  int next_r_ptr, r_ptr_inc;
  logic is_empty, is_full;
  
  always_comb begin
    is_full = cnt == MEMORY_DEPTH;
    is_empty = cnt == 0;
    w_ptr_inc = (w_ptr + 1) % MEMORY_DEPTH;
    r_ptr_inc = (r_ptr + 1) % MEMORY_DEPTH;
    next_w_ptr = w_en ? w_ptr_inc : w_ptr;
    next_r_ptr = r_en ? r_ptr_inc : r_ptr;
    next_cnt = w_en & ~is_full ? cnt + 1 : r_en & cnt != 0 ? cnt - 1 : cnt;
  end
  
  always @(posedge clk) begin
    if (rst) begin
      r_ptr <= 0;
      w_ptr <= 0;
      cnt <= 0;
      for (integer i = 0; i < MEMORY_DEPTH; i++) begin
        mem[i] <= 0;
      end
    end
    else begin
      cnt <= next_cnt;
      w_ptr <= next_w_ptr;
      r_ptr <= next_r_ptr;
      if (w_en) mem[w_ptr] <= w_data;
    end
  end
  
  assign r_data = ~is_empty & r_en ? mem[r_ptr] : 0;
  assign empty = is_empty;
  assign full = is_full;
  assign count = cnt;
  
endmodule