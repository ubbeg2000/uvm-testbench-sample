`include "fifo.sv"

module i2c_master_v2 #(
  parameter W_DATA_DEPTH = 8,
  parameter R_DATA_DEPTH = 8
) (
  // clock signals
  input clk, // must be 2x i2c freq
  
  // reset signal
  input rst,
  
  // ip command and status signal
  input i2c_send,
  input [31:0] command,
  output [31:0] status,
  
  // fifo buffer signals
  input w_en,
  input r_en,
  input [7:0] w_data,
  output [7:0] r_data,
  
  // i2c interface
  input sda_i,
  output sda_o,
  output scl_o,
  output sda_o_en
);
  localparam R_DATA_ADDR_LEN = $clog2(R_DATA_DEPTH);
  
  localparam S_IDLE = 0;
  localparam S_START = 1;
  localparam S_ADDRESSING = 2;
  localparam S_ADDR_ACK = 3;
  localparam S_WRITE_ADDR = 4;
  localparam S_WRITE_ADDR_ACK = 5;
  localparam S_REPEATED_START = 6;
  localparam S_WRITE = 7;
  localparam S_READ = 8;
  localparam S_WAIT_ACK = 9;
  localparam S_SEND_ACK = 10;
  localparam S_SEND_NACK = 11;
  localparam S_STOP = 12;
  
  // command/status regsiters
  logic [31:0] command_reg, status_reg;
  
  // fsm state register
  logic [4:0] state = S_IDLE, next_state = S_IDLE;
  logic [3:0] state_res_cnt = 0, next_state_res_cnt;
  logic [R_DATA_ADDR_LEN-1:0] r_data_cnt = 0, next_r_data_cnt = 0;
  
  // status registers
  logic got_ack = 0, next_got_ack = 0;
  logic [10:0] fail_code = 0, next_fail_code = 0;
  logic repeated_start = 0, next_repeated_start = 0;
  
  // output signal value register
  logic [15:0] sda_buf = 16'hffff, next_sda_buf = 16'hffff;
  logic state_res_odd, state_res_max;
  
  // write buffer signals
  logic write_buffer_w_en;
  logic write_buffer_r_en;
  logic write_buffer_full;
  logic write_buffer_empty;
  logic [7:0] write_buffer_count;
  logic [7:0] write_buffer_data;
  logic [15:0] expanded_write_buffer_data;
  
  // read buffer signals
  logic read_buffer_rst;
  logic read_buffer_w_en;
  logic read_buffer_full;
  logic read_buffer_empty;
  logic [7:0] read_buffer_count;
  logic [7:0] read_buffer_data;

  // command sample
  logic i2c_rw_samp;
  logic [6:0] i2c_addr_samp;
  logic i2c_data_addr_en_samp;
  logic [7:0] i2c_data_addr_samp;
  logic [14:0] i2c_data_len_samp;

  always_comb begin
    i2c_addr_samp = command_reg[31:25];
    i2c_data_addr_samp = command_reg[24:17];
    i2c_data_addr_en_samp = command_reg[16];
    i2c_rw_samp = command_reg[15];
    i2c_data_len_samp = command_reg[14:0];
  end
  
  // write buffer controls
  always_comb begin
    write_buffer_w_en = state == S_IDLE & w_en;
    write_buffer_r_en = (state == S_ADDR_ACK & ~i2c_rw_samp | state == S_WAIT_ACK) & state_res_cnt == 1;
  end

  // read buffer controls
  always_comb begin
    read_buffer_rst = state == S_ADDR_ACK & i2c_rw_samp ? 1'b1 : 1'b0;
    read_buffer_w_en = (state == S_SEND_ACK | state == S_SEND_NACK) & state_res_cnt == 0;
  end
  
  // i2c driver state machine and residency counter
  always_comb begin
    state_res_odd = state_res_cnt[0];
    state_res_max = state_res_cnt == 4'b1111;
    case (state)
      S_IDLE: next_state = i2c_send 
        ? S_START 
        : S_IDLE;
      
      S_START: next_state = state_res_odd 
        ? S_ADDRESSING 
        : S_START;
      
      S_ADDRESSING: next_state = state_res_max 
        ? S_ADDR_ACK 
        : S_ADDRESSING;
      
      S_ADDR_ACK: next_state = state_res_odd 
        ? got_ack | ~sda_i 
          ? i2c_rw_samp
            ? i2c_data_addr_en_samp & ~repeated_start ? S_WRITE_ADDR : S_READ
            : write_buffer_empty ? S_STOP : S_WRITE
          : S_STOP
        : S_ADDR_ACK;
      
      S_WRITE_ADDR: next_state = state_res_max 
        ? S_WRITE_ADDR_ACK 
        : S_WRITE_ADDR;
      
      S_WRITE_ADDR_ACK: next_state = state_res_odd 
        ? sda_i ? S_STOP : S_REPEATED_START
        : S_WRITE_ADDR_ACK;
      
      S_REPEATED_START: next_state = state_res_odd 
        ? S_ADDRESSING 
        : S_REPEATED_START;
      
      S_WRITE: next_state = state_res_max 
        ? S_WAIT_ACK 
        : S_WRITE;
      
      S_READ: next_state = state_res_max 
        ? (i2c_data_len_samp == r_data_cnt + 1 ? S_SEND_NACK : S_SEND_ACK) 
        : S_READ;
      
      S_WAIT_ACK: next_state = state_res_odd 
        ? got_ack | ~sda_i 
           ? write_buffer_empty ? S_STOP : S_WRITE
           : S_STOP 
        : S_WAIT_ACK;
      
      S_SEND_ACK: next_state = state_res_odd 
        ? S_READ 
        : S_SEND_ACK;
      
      S_SEND_NACK: next_state = state_res_odd 
        ? S_STOP 
        : S_SEND_NACK;
      
      S_STOP: next_state = state_res_cnt == 3 
        ? S_IDLE 
        : S_STOP;
      
      default: next_state = S_IDLE;
    endcase
    next_state_res_cnt = state == next_state ? state_res_cnt + 1 : 0;
  end
  always @(posedge clk) begin
    if (rst) begin
      state <= S_IDLE;
      state_res_cnt <= 0;
    end
    else begin
      state <= next_state;
      state_res_cnt <= next_state_res_cnt;
    end
  end
  
  // repeated start and ack detector
  always @(posedge clk) begin
    if (rst | state == S_STOP) begin
      repeated_start <= 0;
      got_ack <= 0;
    end
    else begin
      repeated_start <= state == S_REPEATED_START ? 1 : repeated_start;
      if (state == S_WAIT_ACK | state == S_ADDR_ACK) begin
        got_ack <= state_res_odd ? 0 : got_ack | ~sda_i;
      end
    end
  end
  
  // error detector
  always_comb begin
    case (state)
      // missing write ack
      S_WAIT_ACK: next_fail_code = state_res_odd 
        ? fail_code 
        : ~got_ack & sda_i ? 11'h001 : fail_code;
      
      // missing write addr ack
      S_WRITE_ADDR_ACK: next_fail_code = state_res_odd 
        ? fail_code 
        : ~got_ack & sda_i ? 11'h002 : fail_code;
      
      // missing slave ack
      S_ADDR_ACK: next_fail_code = state_res_odd 
        ? fail_code
        : ~got_ack & sda_i ? 11'h003 : fail_code;
      
      // reset error on start
      S_START: next_fail_code = 0;
      
      default: next_fail_code = fail_code;
    endcase
  end
  always @(posedge clk) begin
    if (rst) begin
      fail_code <= 0;
    end
    else begin
      fail_code <= next_fail_code;
    end
  end
  
  // sda intput sampler
  always @(posedge clk) begin
    if (rst) begin
      r_data_cnt <= 0;
    end
    else if (state == S_READ) begin
      if (state_res_max) begin
        r_data_cnt <= r_data_cnt + 1;
      end
      else begin
        read_buffer_data[7 - (state_res_cnt >> 1)] <= sda_i;
      end
    end
  end
  
  // sda output buffer loader-shifter
  always_comb begin
    if (state == next_state) begin
      next_sda_buf = next_state == S_IDLE ? 16'hffff : sda_buf << 1;
    end
    else begin
      case (next_state)
        S_IDLE: next_sda_buf = 16'hffff;
        S_START: next_sda_buf = 16'h8fff;
        S_REPEATED_START: next_sda_buf = 16'h8fff;
        S_WAIT_ACK: next_sda_buf = 16'hffff;
        S_WRITE_ADDR_ACK: next_sda_buf = 16'hffff;
        S_STOP: next_sda_buf = 16'h3fff;
        S_SEND_ACK: next_sda_buf = 16'h3fff;
        S_SEND_NACK: next_sda_buf = 16'hffff;
        S_ADDRESSING: next_sda_buf = {
          i2c_addr_samp[6],
          i2c_addr_samp[6], 
          i2c_addr_samp[5],
          i2c_addr_samp[5],
          i2c_addr_samp[4],
          i2c_addr_samp[4],
          i2c_addr_samp[3],
          i2c_addr_samp[3],
          i2c_addr_samp[2],
          i2c_addr_samp[2],
          i2c_addr_samp[1],
          i2c_addr_samp[1],
          i2c_addr_samp[0],
          i2c_addr_samp[0],
          i2c_data_addr_en_samp & ~repeated_start ? 1'b0 : i2c_rw_samp,
          i2c_data_addr_en_samp & ~repeated_start ? 1'b0 : i2c_rw_samp
        };
        S_WRITE_ADDR: next_sda_buf = {
          i2c_data_addr_samp[7],
          i2c_data_addr_samp[7],
          i2c_data_addr_samp[6],
          i2c_data_addr_samp[6],
          i2c_data_addr_samp[5],
          i2c_data_addr_samp[5],
          i2c_data_addr_samp[4],
          i2c_data_addr_samp[4],
          i2c_data_addr_samp[3],
          i2c_data_addr_samp[3],
          i2c_data_addr_samp[2],
          i2c_data_addr_samp[2],
          i2c_data_addr_samp[1],
          i2c_data_addr_samp[1],
          i2c_data_addr_samp[0],
          i2c_data_addr_samp[0]
        };
        S_WRITE: next_sda_buf = {
          write_buffer_data[7],
          write_buffer_data[7],
          write_buffer_data[6],
          write_buffer_data[6],
          write_buffer_data[5],
          write_buffer_data[5],
          write_buffer_data[4],
          write_buffer_data[4],
          write_buffer_data[3],
          write_buffer_data[3],
          write_buffer_data[2],
          write_buffer_data[2],
          write_buffer_data[1],
          write_buffer_data[1],
          write_buffer_data[0],
          write_buffer_data[0]
        };
      endcase
    end
  end
  always @(posedge clk) begin
    if (rst) begin
      sda_buf <= 16'hffff;
    end
    else begin
      sda_buf <= next_sda_buf;
    end
  end
  
  // command sampler
  always @(posedge clk) begin
    if (rst)
      command_reg <= 0;
    else if (i2c_send)
      command_reg <= command;
  end
  
  fifo #(
    .DATA_WIDTH(8),
    .MEMORY_DEPTH(W_DATA_DEPTH)
  ) 
  w_buffer (
    .clk(clk),
    .rst(rst),
    .r_en(write_buffer_r_en),
    .w_en(w_en),
    .r_data(write_buffer_data),
    .w_data(w_data),
    .empty(write_buffer_empty),
    .full(write_buffer_full),
    .count(write_buffer_count)
  );
  
  fifo #(
    .DATA_WIDTH(8),
    .MEMORY_DEPTH(R_DATA_DEPTH)
  ) 
  r_buffer (
    .clk(clk),
    .rst(read_buffer_rst),
    .r_en(r_en),
    .w_en(read_buffer_w_en),
    .r_data(r_data),
    .w_data(read_buffer_data),
    .empty(read_buffer_empty),
    .full(read_buffer_full),
    .count(read_buffer_count)
  );
  
  assign sda_o_en = 
    state == S_START |
    state == S_REPEATED_START |
    state == S_WRITE |
    state == S_ADDRESSING |
    state == S_WRITE_ADDR |
    state == S_SEND_ACK |
    state == S_SEND_NACK;
  
  assign scl_o =
    state_res_odd |
  	state == S_IDLE |
  	state == S_START |
  	state == S_REPEATED_START |
    state == S_STOP & state_res_cnt != 0;
  
  assign sda_o = sda_buf[15];

  assign status = {
    state != S_IDLE,
    fail_code,
    read_buffer_full,
    read_buffer_empty,
    write_buffer_full,
    write_buffer_empty,
    read_buffer_count,
    write_buffer_count
  };
  
endmodule