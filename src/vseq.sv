class master_write_vseq extends uvm_sequence;
  `uvm_object_utils(master_write_vseq)
  
  mfifo_sequencer mfifo_sqr;
  i2c_sequencer i2c_sqr;
  
  i2c_master_reg_model i2c_master_reg_mod;
  
  mfifo_reset_seq reset_seq;
  mfifo_write_seq write_seq;
  mfifo_i2c_write_seq i2c_write_seq;
  i2c_slave_ack_seq slave_ack_seq;
  
  bit [6:0] addr;
  
  function new(string name = "master_write_vseq");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    reset_seq = mfifo_reset_seq::type_id::create("reset_seq");
    write_seq = mfifo_write_seq::type_id::create("write_seq");
    i2c_write_seq = mfifo_i2c_write_seq::type_id::create("i2c_write_seq");
    slave_ack_seq = i2c_slave_ack_seq::type_id::create("slave_ack_seq");
    
    i2c_write_seq.i2c_master_reg_mod = i2c_master_reg_mod;
    
    assert(write_seq.randomize());
    assert(i2c_write_seq.randomize());
  endtask
  
  virtual task body();
    fork
      // master sequences
      begin
        // reset and fill write buffer
        reset_seq.start(mfifo_sqr);
        write_seq.start(mfifo_sqr);
        
        // send command to execute i2c transfer
        i2c_write_seq.start(mfifo_sqr);
      end
      
      // slave sequences
      begin
         slave_ack_seq.start(i2c_sqr);
      end
    join_any
  endtask
endclass

class master_read_vseq extends uvm_sequence;
  `uvm_object_utils(master_read_vseq)
  
  mfifo_sequencer mfifo_sqr;
  i2c_sequencer i2c_sqr;
  
  i2c_master_reg_model i2c_master_reg_mod;
  
  mfifo_reset_seq reset_seq;
  mfifo_i2c_read_seq i2c_read_seq;
  mfifo_read_seq read_seq;
  i2c_slave_data_seq slave_data_seq;
  i2c_slave_ack_seq slave_ack_seq;
  
  function new(string name = "master_read_vseq");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    reset_seq = mfifo_reset_seq::type_id::create("reset_seq");
    i2c_read_seq = mfifo_i2c_read_seq::type_id::create("i2c_read_seq");
    slave_data_seq = i2c_slave_data_seq::type_id::create("slave_data_seq");
    slave_ack_seq = i2c_slave_ack_seq::type_id::create("slave_ack_seq");
    read_seq = mfifo_read_seq::type_id::create("read_seq");
    
    i2c_read_seq.i2c_master_reg_mod = i2c_master_reg_mod;
    read_seq.read_all = 1;
  endtask
  
  virtual task body();
    fork
      // master sequences
      begin
        reset_seq.start(mfifo_sqr);
        i2c_read_seq.start(mfifo_sqr);
        
        read_seq.start(mfifo_sqr);
      end
      
      // slave sequences
      begin
        slave_data_seq.start(i2c_sqr);
      end
    join_any
  endtask
endclass

class master_read_addr_vseq extends uvm_sequence;
  `uvm_object_utils(master_read_addr_vseq)
  
  mfifo_sequencer mfifo_sqr;
  i2c_sequencer i2c_sqr;
  
  i2c_master_reg_model i2c_master_reg_mod;
  
  mfifo_reset_seq reset_seq;
  mfifo_i2c_read_seq i2c_read_seq;
  mfifo_read_seq read_seq;
  i2c_slave_ack_seq slave_ack_seq;
  i2c_slave_data_seq slave_data_seq;
  
  function new(string name = "master_read_addr_vseq");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    reset_seq = mfifo_reset_seq::type_id::create("reset_seq");
    i2c_read_seq = mfifo_i2c_read_seq::type_id::create("i2c_read_seq");
    slave_ack_seq = i2c_slave_ack_seq::type_id::create("slave_ack_seq");
    slave_data_seq = i2c_slave_data_seq::type_id::create("slave_data_seq");
    read_seq = mfifo_read_seq::type_id::create("read_seq");
    
    i2c_read_seq.i2c_master_reg_mod = i2c_master_reg_mod;
    assert(i2c_read_seq.randomize());
    i2c_read_seq.i2c_data_addr_en = 1;
    
    read_seq.read_all = 1;
  endtask
  
  virtual task body();
    fork
      // master sequences
      begin
        reset_seq.start(mfifo_sqr);
        i2c_read_seq.start(mfifo_sqr);
        read_seq.start(mfifo_sqr);
      end
      
      // slave sequences
      begin
        slave_data_seq.start(i2c_sqr);
      end
    join_any
  endtask
endclass

class slave_write_vseq extends uvm_sequence;
  `uvm_object_utils(slave_write_vseq)
  
  mem_sequencer mem_sqr;
  i2c_sequencer i2c_sqr;
  
  i2c_write_seq write_via_i2c;
  mem_read_seq read_via_mem;
  i2c_mem_reset_seq reset_seq;
  
  function new(string name = "slave_write_vseq");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    write_via_i2c = i2c_write_seq::type_id::create("write_via_i2c");
    read_via_mem = mem_read_seq::type_id::create("read_via_mem");
    reset_seq = i2c_mem_reset_seq::type_id::create("reset_seq");
    
    assert(write_via_i2c.randomize());
  endtask
  
  virtual task body();
    reset_seq.start(mem_sqr);
    write_via_i2c.start(i2c_sqr);
    
    for (int i = 0; i < write_via_i2c.num; i++) begin
      read_via_mem.r_addr.push_front(write_via_i2c.start_addr + i);
    end
    read_via_mem.start(mem_sqr);
  endtask
endclass

class slave_read_vseq extends uvm_sequence;
  `uvm_object_utils(slave_read_vseq)
  
  rand bit read_src;
  
  mem_sequencer mem_sqr;
  i2c_sequencer i2c_sqr;
  
  i2c_mem_reset_seq reset_seq;
  i2c_read_seq read_via_i2c;
  mem_write_seq write_via_mem;
  
  function new(string name = "slave_read_vseq");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    write_via_mem = mem_write_seq::type_id::create("write_via_mem");
    read_via_i2c = i2c_read_seq::type_id::create("read_via_i2c");
    reset_seq = i2c_mem_reset_seq::type_id::create("reset_seq");
    
    assert(write_via_mem.randomize());
    write_via_mem.start_addr = 1;
    write_via_mem.in_order = 1;
  endtask
  
  virtual task body();
    reset_seq.start(mem_sqr);
    write_via_mem.start(mem_sqr);
    
    read_via_i2c.num = write_via_mem.num + 1;
    read_via_i2c.mem_addr_en = 0;
    read_via_i2c.start(i2c_sqr);
  endtask
endclass

class slave_read_addr_vseq extends uvm_sequence;
  `uvm_object_utils(slave_read_addr_vseq)
  
  rand bit read_src;
  
  mem_sequencer mem_sqr;
  i2c_sequencer i2c_sqr;
  
  i2c_mem_reset_seq reset_seq;
  i2c_read_seq read_via_i2c;
  mem_write_seq write_via_mem;
  
  function new(string name = "slave_read_addr_vseq");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    write_via_mem = mem_write_seq::type_id::create("write_via_mem");
    read_via_i2c = i2c_read_seq::type_id::create("read_via_i2c");
    reset_seq = i2c_mem_reset_seq::type_id::create("reset_seq");
    
    assert(write_via_mem.randomize());
    write_via_mem.in_order = 1;
  endtask
  
  virtual task body();
    reset_seq.start(mem_sqr);
    write_via_mem.start(mem_sqr);
    
    read_via_i2c.num = write_via_mem.num;
    read_via_i2c.start_addr = write_via_mem.start_addr;
    read_via_i2c.start(i2c_sqr);
  endtask
endclass

class slave_addr_vseq extends uvm_sequence;
  `uvm_object_utils(slave_addr_vseq)
  
  mem_sequencer mem_sqr;
  i2c_sequencer i2c_sqr;
  
  i2c_write_seq write_via_i2c;
  i2c_write_seq addr_via_i2c;
  i2c_read_seq read_via_i2c;
  i2c_mem_reset_seq reset_seq;
  
  function new(string name = "slave_addr_vseq");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    addr_via_i2c = i2c_write_seq::type_id::create("addr_via_i2c");
    write_via_i2c = i2c_write_seq::type_id::create("write_via_i2c");
    read_via_i2c = i2c_read_seq::type_id::create("read_via_i2c");
    reset_seq = i2c_mem_reset_seq::type_id::create("reset_seq");
    
    assert(addr_via_i2c.randomize());
    addr_via_i2c.start_addr = 0;
    addr_via_i2c.num = 1;
    
    assert(write_via_i2c.randomize());
    
    read_via_i2c.num = write_via_i2c.num;
    read_via_i2c.start_addr = write_via_i2c.start_addr;
    read_via_i2c.mem_addr_en = 1;
  endtask
  
  virtual task body();
    bit [6:0] new_i2c_addr;
    
    reset_seq.start(mem_sqr);
    addr_via_i2c.start(i2c_sqr);
    
    new_i2c_addr = addr_via_i2c.w_data.pop_front();
    
    write_via_i2c.i2c_addr = new_i2c_addr;
    write_via_i2c.start(i2c_sqr);
    
    read_via_i2c.i2c_addr = new_i2c_addr;
    read_via_i2c.start(i2c_sqr);
  endtask
endclass

class master_write_read_vseq extends uvm_sequence;
  `uvm_object_utils(master_write_read_vseq)
  
  mem_sequencer mem_sqr;
  mfifo_sequencer mfifo_sqr;
  
  i2c_master_reg_model i2c_master_reg_mod;
  
  mfifo_i2c_write_seq write_seq;
  mfifo_write_seq preload_seq;
  mem_read_seq read_seq;
  mfifo_i2c_read_seq second_read_seq;
  mfifo_read_seq third_read_seq;
  i2c_mem_reset_seq reset_seq;
  mfifo_reset_seq reset_seq_2;
  
  function new(string name = "master_write_read_vseq");
    super.new(name);
  endfunction
  
  virtual task pre_body();
    write_seq = mfifo_i2c_write_seq::type_id::create("write_seq");
    preload_seq = mfifo_write_seq::type_id::create("preload_seq");
    read_seq = mem_read_seq::type_id::create("read_seq");
    second_read_seq = mfifo_i2c_read_seq::type_id::create("second_read_seq");
    third_read_seq = mfifo_read_seq::type_id::create("third_read_seq");
    reset_seq = i2c_mem_reset_seq::type_id::create("reset_seq");
    reset_seq_2 = mfifo_reset_seq::type_id::create("reset_seq_2");
    
    write_seq.i2c_master_reg_mod = i2c_master_reg_mod;
    second_read_seq.i2c_master_reg_mod = i2c_master_reg_mod;
    third_read_seq.read_all = 1;
    
    preload_seq.fill = 0;
    preload_seq.num = 3;
    write_seq.i2c_addr = 7'h69;
    second_read_seq.i2c_addr = 7'h69;
  endtask
  
  virtual task body();
    bit [7:0] base_addr;
    
    fork
      reset_seq.start(mem_sqr);
      reset_seq_2.start(mfifo_sqr);
    join
    
    preload_seq.start(mfifo_sqr);
    write_seq.start(mfifo_sqr);
    
    base_addr = preload_seq.write_data.pop_back();
    for (int i = 0; i < preload_seq.write_data.size(); i = i + 1) begin
      read_seq.r_addr.push_front(base_addr + i);
    end
    read_seq.start(mem_sqr);
    
    second_read_seq.i2c_data_addr = base_addr;
    second_read_seq.i2c_data_addr_en = 1;
    second_read_seq.i2c_data_len = preload_seq.write_data.size();
    second_read_seq.start(mfifo_sqr);
    
    third_read_seq.start(mfifo_sqr);
  endtask
endclass