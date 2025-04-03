`ifndef SEQ_ITEMS
`define SEQ_ITEMS
class mfifo_seq_item extends uvm_sequence_item;
  `uvm_object_utils(mfifo_seq_item)
  
  typedef enum {
    MFIFO_CONTROL, MFIFO_COMMAND, MFIFO_STATUS, MFIFO_COMMAND_STATUS
  } seq_item_type;
  
  seq_item_type kind;
  
  // i2c interface control signals
  bit i2c_send;
  bit [6:0] i2c_addr;
  bit [7:0] i2c_data_addr;
  bit i2c_data_addr_en;
  bit i2c_rw; // 1 means read
  bit [14:0] i2c_data_len;
  
  // fifo buffer signals
  bit rst;
  rand bit [7:0] data;
  bit rw; // 1 means read
  bit en;
  
  // status fields for response
  bit busy;
  bit [10:0] fail_code;
  bit write_buffer_full;
  bit write_buffer_empty;
  bit [7:0] write_buffer_cnt;
  bit read_buffer_full;
  bit read_buffer_empty;
  bit [7:0] read_buffer_cnt;
  
  function new(string name = "mfifo_seq_item");
    super.new(name);
  endfunction
  
  function string convert2string();
    case (kind)
      MFIFO_CONTROL: begin
        return $sformatf(
          "kind=%s; rst=%d; data=0x%2h; rw=%d; en=%d", 
          kind.name(), rst, data, rw, en
        );
      end
      MFIFO_COMMAND: begin
        return $sformatf(
          "kind=%s; addr=0x%2h; data_addr=0x%2h (%0d); i2c_rw=%d; len=%0d", 
          kind.name(), i2c_addr, i2c_data_addr, 
          i2c_data_addr_en, i2c_rw, i2c_data_len
        );
      end
      MFIFO_STATUS: begin
        return $sformatf(
          "kind=%s; busy=%d; fail=%2h; w_data_full=%d; r_data_empty=%d", 
          kind.name(), busy, fail_code, write_buffer_full, read_buffer_empty
        );
      end
      MFIFO_COMMAND_STATUS: begin
        return $sformatf(
          "kind=%s; busy=%d; fail=%2h; w_data_full=%d; r_data_empty=%d", 
          kind.name(), busy, fail_code, write_buffer_full, read_buffer_empty
        );
      end
    endcase
  endfunction
endclass

class i2c_seq_item extends uvm_sequence_item;
  `uvm_object_utils(i2c_seq_item)
  
  typedef enum {
    START, ADDR, DATA, ACK, NACK, STOP, IDLE
  } i2c_seq_item_type;
  
  typedef enum {
  	MASTER, SLAVE
  } i2c_seq_item_src;
  
  i2c_seq_item_src src;
  i2c_seq_item_type kind;
  
  bit [6:0] addr;
  rand bit [7:0] data;
  bit rw; // 1 means read
  
  function new(string name = "i2c_seq_item");
    super.new(name);
  endfunction: new
  
  function string convert2string();
    case (kind)
      IDLE: return $sformatf("kind: %s; src=%s", kind.name(), src.name());
      START: return $sformatf("kind: %s; src=%s", kind.name(), src.name());
      STOP: return $sformatf("kind: %s; src=%s", kind.name(), src.name());
      ACK: return $sformatf("kind: %s; src=%s", kind.name(), src.name());
      NACK: return $sformatf("kind: %s; src=%s", kind.name(), src.name());
      DATA: return $sformatf("kind: %s; src=%s; data=0x%2h", kind.name(), src.name(), data);
      ADDR: return $sformatf(
        "kind: %s; addr=0x%2h; rw=%d", 
        kind.name(), addr, rw
      );
    endcase
  endfunction
endclass

class mem_seq_item extends uvm_sequence_item;
  `uvm_object_utils(mem_seq_item)
  
  typedef enum {
    READ, WRITE, RESET
  } mem_seq_item_type;
  
  mem_seq_item_type kind;
  rand bit [7:0] addr;
  rand bit [7:0] data;
  
  function new(string name = "mem_seq_item");
    super.new(name);
  endfunction
      
  function string convert2string();
    return $sformatf(
      "kind=%s; addr=0x%2h; data=0x%2h", 
      kind.name(), addr, data
    );
  endfunction
endclass
`endif