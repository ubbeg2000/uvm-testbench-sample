module i2c_mem(
  input clk, // at least 4x i2c freq
  input rst,
  
  input rw, // 1 means read
  input rw_en,
  input [7:0] addr,
  input [7:0] data_i,
  output [7:0] data_o,
  output busy,
  
  input sda_i,
  input scl_i,
  output sda_o,
  output sda_o_en
);
  localparam SLAVE_ADDR = 7'h69;
  localparam DEPTH = 256;
  
  localparam S_IDLE = 0;
  localparam S_RECV_ADDR = 1;
  localparam S_RECV_DATA_ADDR = 2;
  localparam S_RECV_DATA = 3;
  localparam S_SEND_DATA = 4;
  
  bit [7:0] data_mem [0:DEPTH-1];
  bit [7:0] data_out_reg;
  
  // i2c signal samples
  bit [1:0] sda_samp = 2'b11, scl_samp = 2'b11;
  bit sda_low, sda_high, sda_rising, sda_falling;
  bit scl_low, scl_high, scl_rising, scl_falling;
  bit start_cond, stop_cond;
  bit got_start_cond = 0, next_got_start_cond;
  
  // state registers
  bit [7:0] state = S_IDLE, next_state;
  bit [6:0] slave_addr = 0, next_slave_addr;
  bit [7:0] mem_addr = 0, next_mem_addr;
  bit i2c_rw = 0, next_i2c_rw;
  bit [3:0] state_res = 0, next_state_res;
  bit [3:0] scl_cnt = 0, next_scl_cnt;
  bit has_repeated_start = 0, next_has_repeated_start;
  
  // io buffers
  bit [7:0] sda_i_buf = 0, next_sda_i_buf;
  bit [7:0] sda_o_buf = 0, next_sda_o_buf;
  bit [7:0] r_data_buf;
  bit sda_o_reg = 1, next_sda_o_reg = 1;
  
  // main slave fsm
  always_comb begin
    case (state)
      S_IDLE: begin
        next_state = start_cond ? S_RECV_ADDR : S_IDLE;
        next_got_start_cond = start_cond;
        next_mem_addr = 0;
      end
      
      S_RECV_ADDR: begin
        if (scl_falling) begin
          next_state = scl_cnt == 8 ? (
            sda_i_buf[7:1] == data_mem[0][6:0] ? (
              i2c_rw ? S_SEND_DATA : S_RECV_DATA_ADDR
            ) : S_IDLE
          ) : state;
        end
        else if (scl_rising) begin
          next_sda_i_buf = scl_cnt != 8 
            ? (sda_i_buf << 1) | {7'h00, sda_samp[0]}
            : (sda_i_buf);
          next_slave_addr = scl_cnt == 6 ? next_sda_i_buf : slave_addr;
          next_i2c_rw = scl_cnt == 7 ? sda_samp[0] : i2c_rw;
        end
        else begin
          next_state = state;
          next_sda_i_buf = sda_i_buf;
        end
      end
      
      S_RECV_DATA_ADDR: begin
        if (scl_falling) begin
          next_state = scl_cnt == 8 ? S_RECV_DATA : state;
          next_mem_addr = scl_cnt == 8 ? sda_i_buf : mem_addr;
        end
        else begin
          next_state = state;
          next_sda_i_buf = sda_i_buf;
          next_mem_addr = mem_addr;
        end
      end
      
      S_RECV_DATA: begin
        if (scl_falling) begin
          next_state = scl_cnt == 8 ? S_RECV_DATA : state;
          next_sda_i_buf = scl_cnt != 8 
            ? (sda_i_buf << 1) | {7'h00, sda_samp[0]}
            : (sda_i_buf);
          next_mem_addr = scl_cnt == 8 ? mem_addr + 1 : mem_addr;
        end
        else begin
          next_state = state;
          next_sda_i_buf = sda_i_buf;
          next_mem_addr = mem_addr;
        end
      end
      
      S_SEND_DATA: begin
        if (scl_falling) begin
          next_state = scl_cnt == 8 ? (sda_i ? S_IDLE : S_SEND_DATA) : state;
          next_mem_addr = scl_cnt == 8 ? mem_addr + 1 : mem_addr;
        end
        else begin
          next_state = state;
          next_sda_i_buf = sda_i_buf;
          next_mem_addr = mem_addr;
        end
      end
      
      default: begin
//         next_sda_o_buf = sda_o_buf;
      end
    endcase
    
    if (stop_cond) begin
      next_state = S_IDLE;
      next_has_repeated_start = 0;
    end
    else if (start_cond) begin
      next_state = S_RECV_ADDR;
      next_has_repeated_start = 1;
    end
  end
  always @(posedge clk) begin
    if (rst) begin
      state <= S_IDLE;
      scl_cnt <= 0;
      sda_i_buf <= 0;
      mem_addr <= 0;
      slave_addr <= 0;
      i2c_rw <= 0;
      has_repeated_start <= 0;
      got_start_cond <= 0;
    end
    else begin
      state <= next_state;
      mem_addr <= next_mem_addr;
      slave_addr <= next_slave_addr;
      i2c_rw <= next_i2c_rw;
      has_repeated_start <= next_has_repeated_start;
      got_start_cond <= next_got_start_cond;
    end
  end
  
  // scl edge counter
  always_comb begin
    case (state)
      S_IDLE: next_scl_cnt = 4'hf;
      S_RECV_ADDR: next_scl_cnt = scl_cnt == 8 ? 0 : scl_cnt + 1;
      S_RECV_DATA_ADDR: next_scl_cnt = scl_cnt == 8 ? 0 : scl_cnt + 1;
      S_RECV_DATA: next_scl_cnt = scl_cnt == 8 ? 0 : scl_cnt + 1;
      S_SEND_DATA: next_scl_cnt = scl_cnt == 8 ? 0 : scl_cnt + 1;
    endcase
  end
  always @(posedge scl_falling or stop_cond or rst) begin
    if (rst | stop_cond)
      scl_cnt <= 4'hf;
    else
      scl_cnt <= next_scl_cnt;
  end
  
  // sda input sampler
  always @(posedge scl_rising) begin
    if (state != S_IDLE)
      sda_i_buf <= (sda_i_buf << 1) | {7'h00, sda_i};
  end
  
  // i2c line sampler
  always @(posedge clk) begin
    sda_samp <= (sda_samp << 1) | {0, sda_i};
    scl_samp <= (scl_samp << 1) | {0, scl_i};
  end
  always_comb begin
    sda_low = sda_samp == 2'b00;
    sda_high = sda_samp == 2'b11;
    sda_rising = sda_samp == 2'b01;
    sda_falling = sda_samp == 2'b10;
    
    scl_low = scl_samp == 2'b00;
    scl_high = scl_samp == 2'b11;
    scl_rising = scl_samp == 2'b01;
    scl_falling = scl_samp == 2'b10;
    
    start_cond = scl_high & sda_falling;
    stop_cond = scl_high & sda_rising;
  end
  
  // storing data via memory interface
  always @(posedge clk) begin
    // memory interface side
    if (rw_en) begin
      case (rw)
        0: data_mem[addr] <= data_i;
        1: data_out_reg <= data_mem[addr];
      endcase
    end
    // i2c interface side
    else if (scl_cnt == 8) begin
      case (state)
        S_RECV_DATA: begin
          if (scl_falling) data_mem[mem_addr] <= sda_i_buf;
        end
      endcase
    end
  end
  
  // reset and state update
  always @(posedge clk) begin
    if (rst) begin
      sda_samp = 2'b11;
      scl_samp = 2'b11;
      data_mem[0] = SLAVE_ADDR;
    end
  end
  
  always_comb begin
    case (next_state)
      S_IDLE: next_sda_o_buf = 8'hff;
      S_RECV_ADDR: next_sda_o_buf = 8'h00;
      S_RECV_DATA_ADDR: next_sda_o_buf = 8'h00;
      S_RECV_DATA: next_sda_o_buf = 8'h00;
      S_SEND_DATA: next_sda_o_buf = scl_cnt == 8 
        ? data_mem[mem_addr]
        : sda_o_buf << 1;
    endcase
  end
  always @(posedge scl_falling) begin
    if (rst)
      sda_o_buf <= 8'hff;
    else
      sda_o_buf <= next_sda_o_buf;
  end
  
  assign sda_o = sda_o_buf[7];
  assign data_o = data_out_reg;
  assign busy = state != S_IDLE;
  assign sda_o_en = state == S_SEND_DATA & scl_cnt != 8;
  
endmodule