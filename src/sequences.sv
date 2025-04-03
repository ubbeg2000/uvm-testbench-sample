`ifndef SEQUENCES
`define SEQUENCES

class mfifo_reset_seq extends uvm_sequence#(mfifo_seq_item);
  `uvm_object_utils(mfifo_reset_seq)
  
  mfifo_seq_item req;
  mfifo_seq_item rsp;
  
  function new(string name = "mfifo_reset_seq");
    super.new(name);
  endfunction
  
  task body();
    req = mfifo_seq_item::type_id::create("req");
    rsp = mfifo_seq_item::type_id::create("rsp");
    
    start_item(req);
    req.kind = mfifo_seq_item::MFIFO_CONTROL;
    req.rst = 1;
    finish_item(req);
    get_response(rsp);
  endtask
endclass

class mfifo_read_seq extends uvm_sequence#(mfifo_seq_item);
  `uvm_object_utils(mfifo_read_seq)
  
  bit read_all = 0;
  int num = 1;
  
  mfifo_seq_item req;
  mfifo_seq_item rsp;
  
  function new(string name = "mfifo_read_seq");
    super.new(name);
  endfunction
  
  task body();
    req = mfifo_seq_item::type_id::create("req");
    rsp = mfifo_seq_item::type_id::create("rsp");
    
    if (~read_all) begin
      repeat (num) begin
        start_item(req);
        req.kind = mfifo_seq_item::MFIFO_CONTROL;
        req.rw = 1;
        req.en = 1;
        finish_item(req);
        get_response(rsp);
      end
    end
    else begin
      while (~rsp.read_buffer_empty) begin
        start_item(req);
        req.kind = mfifo_seq_item::MFIFO_CONTROL;
        req.rw = 1;
        req.en = 1;
        finish_item(req);
        get_response(rsp);
      end
    end
    
    start_item(req);
    req.en = 0;
    finish_item(req);
    
  endtask
endclass

class mfifo_write_seq extends uvm_sequence#(mfifo_seq_item);
  `uvm_object_utils(mfifo_write_seq)
  
  rand bit fill = 0;
  rand int num = 1;
  bit [7:0] write_data[$];
  
  constraint num_const { num > 0 & num < 9; }
  
  mfifo_seq_item req;
  mfifo_seq_item rsp;
  
  function new(string name = "mfifo_write_seq");
    super.new(name);
  endfunction
  
  task body();
    req = mfifo_seq_item::type_id::create("req");
    rsp = mfifo_seq_item::type_id::create("rsp");
    
    if (~fill) begin
      repeat (num) begin
        start_item(req);
        req.kind = mfifo_seq_item::MFIFO_CONTROL;
        assert(req.randomize());
        req.rw = 0;
        req.en = 1;
        finish_item(req);
        get_response(rsp);
        write_data.push_front(req.data);
      end
    end
    else begin
      while (~rsp.write_buffer_full) begin
        start_item(req);
        req.kind = mfifo_seq_item::MFIFO_CONTROL;
        assert(req.randomize());
        req.rw = 0;
        req.en = 1;
        finish_item(req);
        get_response(rsp);
        write_data.push_front(req.data);
        if (rsp.write_buffer_full) break;
      end
    end
    
    start_item(req);
    req.en = 0;
    finish_item(req);
  endtask
endclass

class mfifo_i2c_write_seq extends uvm_sequence#(mfifo_seq_item);
  `uvm_object_utils(mfifo_i2c_write_seq)
  
  rand bit [6:0] i2c_addr;
  
  i2c_master_reg_model i2c_master_reg_mod;
  uvm_status_e status;
  
  mfifo_seq_item req;
  mfifo_seq_item rsp;
  
  constraint i2c_addr_cons { i2c_addr != 0 & i2c_addr < (1 << 7); }
  
  function new(string name = "mfifo_i2c_write_seq");
    super.new(name);
  endfunction
  
  task body();
    req = mfifo_seq_item::type_id::create("req");
    rsp = mfifo_seq_item::type_id::create("rsp");
    
    i2c_master_reg_mod.i2c_master_reg.command_reg.write(
      status, {i2c_addr, 8'h00, 1'b0, 1'b0, 15'hff}
    );
    
    do begin
      start_item(req);
      finish_item(req);
      get_response(rsp);
    end while (rsp.busy);
  endtask
endclass

class mfifo_i2c_read_seq extends uvm_sequence#(mfifo_seq_item);
  `uvm_object_utils(mfifo_i2c_read_seq)
  
  rand bit [6:0] i2c_addr = 7'b1010101;
  rand bit [7:0] i2c_data_addr = 8'b11011011;
  bit i2c_data_addr_en = 1'b0;
  rand bit [14:0] i2c_data_len = 3;
  
  constraint i2c_addr_space { i2c_addr < (1 << 7) & i2c_addr != 0; }
  constraint i2c_data_addr_space { i2c_data_addr < (1 << 8);}
  constraint i2c_data_len_cons { i2c_data_len < 9 & i2c_data_len > 2;}
  
  mfifo_seq_item req;
  mfifo_seq_item rsp;
  
  i2c_master_reg_model i2c_master_reg_mod;
  uvm_status_e status;
  
  function new(string name = "mfifo_i2c_read_seq");
    super.new(name);
  endfunction
  
  task body();
    req = mfifo_seq_item::type_id::create("req");
    rsp = mfifo_seq_item::type_id::create("rsp");
    
    i2c_master_reg_mod.i2c_master_reg.command_reg.write(
      status, 
      {i2c_addr, i2c_data_addr, i2c_data_addr_en, 1'b1, i2c_data_len}
    );
    
    do begin
      start_item(req);
      finish_item(req);
      get_response(rsp);
    end while (rsp.busy);
  endtask
endclass

class i2c_slave_data_seq extends uvm_sequence#(i2c_seq_item);
  `uvm_object_utils(i2c_slave_data_seq)
  
  i2c_seq_item req;
  i2c_seq_item rsp;
  
  function new(string name = "i2c_slave_data_seq");
    super.new(name);
  endfunction
  
  task body();
    req = i2c_seq_item::type_id::create("req");
    rsp = i2c_seq_item::type_id::create("rsp");
    
    forever begin
      start_item(req);
      assert(req.randomize());
      req.kind = i2c_seq_item::DATA;
      finish_item(req);

      start_item(rsp);
      finish_item(rsp);
    end
  endtask
endclass

class i2c_slave_ack_seq extends uvm_sequence#(i2c_seq_item);
  `uvm_object_utils(i2c_slave_ack_seq)
  
  i2c_seq_item req;
  i2c_seq_item rsp;
  
  function new(string name = "i2c_slave_ack_seq");
    super.new(name);
  endfunction
  
  task body();
    req = i2c_seq_item::type_id::create("req");
    rsp = i2c_seq_item::type_id::create("rsp");
    
    forever begin
      start_item(req);
      req.kind = i2c_seq_item::ACK;
      finish_item(req);

      start_item(rsp);
      finish_item(rsp);
    end
  endtask
endclass

class i2c_mem_reset_seq extends uvm_sequence#(mem_seq_item);
  `uvm_object_utils(i2c_mem_reset_seq)
  
  mem_seq_item req;
  mem_seq_item rsp;
  
  function new(string name = "i2c_mem_reset_seq");
    super.new(name);
  endfunction
  
  task body();
    req = mem_seq_item::type_id::create("req");
    rsp = mem_seq_item::type_id::create("rsp");
    
    req.kind = mem_seq_item::RESET;
    start_item(req);
    finish_item(req);
    get_response(rsp);
  endtask
endclass

class mem_write_seq extends uvm_sequence#(mem_seq_item);
  `uvm_object_utils(mem_write_seq)
  
  mem_seq_item req;
  mem_seq_item rsp;
  
  rand int num = 10;
  rand bit [7:0] start_addr;
  bit in_order;
  bit [7:0] w_addr [$] = {};
  bit [7:0] w_data [$] = {};
  
  constraint no_write_addr { start_addr != 0; }
  constraint max_num { num < 10 & num > 0; }
  
  function new(string name = "mem_write_seq");
    super.new(name);
  endfunction
  
  task body();
    req = mem_seq_item::type_id::create("req");
    rsp = mem_seq_item::type_id::create("rsp");
    
    if (in_order) begin
      for (int i = 0; i < num; i = i + 1) begin
        assert(req.randomize());
        req.addr = start_addr + i;
        req.kind = mem_seq_item::WRITE;
        start_item(req);
        finish_item(req);
        get_response(rsp);
        w_addr.push_front(req.addr);
        w_data.push_front(req.data);
      end
    end
    else begin
      repeat (num) begin
        assert(req.randomize());
        req.kind = mem_seq_item::WRITE;
        start_item(req);
        finish_item(req);
        get_response(rsp);
        w_addr.push_front(req.addr);
        w_data.push_front(req.data);
      end
    end
  endtask
endclass

class mem_read_seq extends uvm_sequence#(mem_seq_item);
  `uvm_object_utils(mem_read_seq)
  
  mem_seq_item req;
  mem_seq_item rsp;
  
  bit [7:0] r_addr [$] = {};
  bit [7:0] addr;
  
  function new(string name = "mem_read_seq");
    super.new(name);
  endfunction
  
  task body();
    req = mem_seq_item::type_id::create("req");
    rsp = mem_seq_item::type_id::create("rsp");
    
    repeat (r_addr.size()) begin
      addr = r_addr.pop_back();
      req.kind = mem_seq_item::READ;
      req.addr = addr;
      start_item(req);
      finish_item(req);
      get_response(rsp);
    end
  endtask
endclass

class i2c_write_seq extends uvm_sequence#(i2c_seq_item);
  `uvm_object_utils(i2c_write_seq)
  
  rand bit [7:0] num = 3;
  rand bit [7:0] start_addr = 8'h77;
  bit [6:0] i2c_addr = 7'h69;
  bit [7:0] w_data[$] = '{};
  
  constraint no_write_addr { start_addr != 8'h00; }
  constraint num_limit { num < 10 & num > 0; }
  
  i2c_seq_item req;
  i2c_seq_item rsp;
  
  function new(string name = "i2c_write_seq");
    super.new(name);
  endfunction
  
  task body();
    req = i2c_seq_item::type_id::create("req");
    rsp = i2c_seq_item::type_id::create("rsp");
    
    req.kind = i2c_seq_item::START;
    send();
    
    req.kind = i2c_seq_item::ADDR;
    req.addr = i2c_addr;
    req.rw = 0;
    send();
    
    req.kind = i2c_seq_item::DATA;
    req.data = start_addr;
    send();
    
    repeat (num) begin
      assert(req.randomize());
      req.kind = i2c_seq_item::DATA;
      w_data.push_front(req.data);
      send();
    end
    
    req.kind = i2c_seq_item::STOP;
    send();
    
    req.kind = i2c_seq_item::IDLE;
    send();
  endtask
  
  task send();
    start_item(req);
    finish_item(req);
    get_response(rsp);
  endtask
endclass

class i2c_read_seq extends uvm_sequence#(i2c_seq_item);
  `uvm_object_utils(i2c_read_seq)
  
  rand bit [7:0] num = 3;
  rand bit [7:0] start_addr = 8'h77;
  bit [6:0] i2c_addr = 7'h69;
  rand bit mem_addr_en = 1;
  
  i2c_seq_item req;
  i2c_seq_item rsp;
  
  function new(string name = "i2c_read_seq");
    super.new(name);
  endfunction
  
  task body();
    req = i2c_seq_item::type_id::create("req");
    rsp = i2c_seq_item::type_id::create("rsp");
    
    if (mem_addr_en) begin
      req.kind = i2c_seq_item::START;
      send();

      req.kind = i2c_seq_item::ADDR;
      req.addr = i2c_addr;
      req.rw = 0;
      send();

      req.kind = i2c_seq_item::DATA;
      req.data = start_addr;
      send();
    end
    
    req.kind = i2c_seq_item::START;
    send();
    
    req.kind = i2c_seq_item::ADDR;
    req.addr = i2c_addr;
    req.rw = 1;
    send();
    
    repeat (num) begin
      req.kind = i2c_seq_item::ACK;
      send();
    end
    
    req.kind = i2c_seq_item::STOP;
    send();
    
    req.kind = i2c_seq_item::IDLE;
    send();
  endtask
  
  task send();
    start_item(req);
    finish_item(req);
    get_response(rsp);
  endtask
endclass

`endif