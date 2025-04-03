`include "seq_items.sv"

class ral_command_reg extends uvm_reg;
  `uvm_object_utils(ral_command_reg)
  
  rand uvm_reg_field i2c_addr;
  rand uvm_reg_field i2c_data_addr;
  rand uvm_reg_field i2c_rw;
  rand uvm_reg_field i2c_data_addr_en;
  rand uvm_reg_field i2c_data_len;
  
  function new(string name = "ral_command_reg");
    super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
  endfunction
  
  virtual function void build();
    i2c_addr = uvm_reg_field::type_id::create("i2c_addr");
    i2c_rw = uvm_reg_field::type_id::create("i2c_rw");
    i2c_data_addr = uvm_reg_field::type_id::create("i2c_data_addr");
    i2c_data_addr_en = uvm_reg_field::type_id::create("i2c_data_addr_en");
    i2c_data_len = uvm_reg_field::type_id::create("i2c_data_len");
    
    i2c_addr.configure(this, 7, 25, "RW", 0, 7'h0, 1, 1, 0);
    i2c_data_addr.configure(this, 8, 17, "RW", 0, 8'h0, 1, 1, 0);
    i2c_data_addr_en.configure(this, 1, 16, "RW", 0, 1'b0, 1, 1, 0);
    i2c_rw.configure(this, 1, 15, "RW", 0, 1'b0, 1, 1, 0);
    i2c_data_len.configure(this, 15, 0, "RW", 0, 15'h00, 1, 1, 0);
  endfunction
endclass

class ral_status_reg extends uvm_reg;
  `uvm_object_utils(ral_status_reg)
  
  rand uvm_reg_field busy;
  rand uvm_reg_field fail_code;
  rand uvm_reg_field read_buffer_full;
  rand uvm_reg_field read_buffer_empty;
  rand uvm_reg_field write_buffer_full;
  rand uvm_reg_field write_buffer_empty;
  rand uvm_reg_field read_buffer_cnt;
  rand uvm_reg_field write_buffer_cnt;
  
  function new(string name = "ral_status_reg");
    super.new(name, 32, build_coverage(UVM_NO_COVERAGE));
  endfunction
  
  virtual function void build();
    busy = uvm_reg_field::type_id::create("busy");
    fail_code = uvm_reg_field::type_id::create("fail_code");
    read_buffer_full = uvm_reg_field::type_id::create("read_buffer_full");
    read_buffer_empty = uvm_reg_field::type_id::create("read_buffer_empty");
    write_buffer_full = uvm_reg_field::type_id::create("write_buffer_full");
    write_buffer_empty = uvm_reg_field::type_id::create("write_buffer_empty");
    read_buffer_cnt = uvm_reg_field::type_id::create("read_buffer_cnt");
    write_buffer_cnt = uvm_reg_field::type_id::create("write_buffer_cnt");

    busy.configure(this, 1, 31, "RO", 0, 1'b0, 1, 1, 0);
    fail_code.configure(this, 11, 20, "RO", 0, 11'h00, 1, 1, 0);
    read_buffer_full.configure(this, 1, 19, "RO", 0, 1'b0, 1, 1, 0);
    read_buffer_empty.configure(this, 1, 18, "RO", 0, 1'b0, 1, 1, 0);
    write_buffer_full.configure(this, 1, 17, "RO", 0, 1'b0, 1, 1, 0);
    write_buffer_empty.configure(this, 1, 16, "RO", 0, 1'b0, 1, 1, 0);
    read_buffer_cnt.configure(this, 8, 8, "RO", 0, 1'b0, 1, 1, 0);
    write_buffer_cnt.configure(this, 8, 0, "RO", 0, 1'b0, 1, 1, 0);
  endfunction
endclass

class ral_i2c_master_reg extends uvm_reg_block;
  `uvm_object_utils(ral_i2c_master_reg)
  
  rand ral_command_reg command_reg;
  rand ral_status_reg status_reg;
  
  function new(string name = "ral_i2c_master_reg");
    super.new(name);
  endfunction
  
  virtual function void build();
    command_reg = ral_command_reg::type_id::create("command_reg");
    command_reg.configure(this, null);
    command_reg.build();
    
    status_reg = ral_status_reg::type_id::create("status_reg");
    status_reg.configure(this, null);
    status_reg.build();
    
    default_map = create_map("", `UVM_REG_ADDR_WIDTH'h0, 4, UVM_LITTLE_ENDIAN, 1);
    
    this.default_map.add_reg(command_reg, `UVM_REG_ADDR_WIDTH'h0, "RW");
    this.default_map.add_reg(status_reg, `UVM_REG_ADDR_WIDTH'h4, "RO");
  endfunction
endclass

class i2c_master_reg_model extends uvm_reg_block;
  `uvm_object_utils(i2c_master_reg_model)
  
  rand ral_i2c_master_reg i2c_master_reg;
  
  uvm_reg_map i2c_master_reg_map;
  
  function new(string name = "i2c_master_reg_model");
    super.new(name, .has_coverage(UVM_NO_COVERAGE));
  endfunction
  
  virtual function void build();
    default_map = create_map("i2c_master_reg_map", 'h0, 4, UVM_LITTLE_ENDIAN, 0);
   
    i2c_master_reg = ral_i2c_master_reg::type_id::create("i2c_master_reg");
    i2c_master_reg.configure(this);
    i2c_master_reg.build();
    default_map.add_submap(this.i2c_master_reg.default_map, 0);
  endfunction
endclass

class i2c_master_reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(i2c_master_reg_adapter)
  
  function new(string name = "i2c_master_reg_adapter");
    super.new(name);
  endfunction
  
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    mfifo_seq_item rsp = mfifo_seq_item::type_id::create("rsp");
    
    if (rw.kind == UVM_WRITE) begin
      rsp.kind = mfifo_seq_item::MFIFO_COMMAND;
      rsp.i2c_send = rw.data != 32'h00000000;
      rsp.i2c_addr = rw.data[31:25];
      rsp.i2c_data_addr = rw.data[24:17];
      rsp.i2c_data_addr_en = rw.data[16];
      rsp.i2c_rw = rw.data[15];
      rsp.i2c_data_len = rw.data[14:0];
    end
    return rsp;
  endfunction
  
  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    mfifo_seq_item req;
    assert($cast(req, bus_item));
    
    rw.addr = 4;
    rw.data = {   
      req.busy,
      req.fail_code,
      req.read_buffer_full,
      req.read_buffer_empty,
      req.write_buffer_full,
      req.write_buffer_empty,
      req.read_buffer_cnt,
      req.write_buffer_cnt
    };
    rw.kind = UVM_WRITE;
  endfunction
endclass