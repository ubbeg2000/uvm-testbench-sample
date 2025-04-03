class master_write_test extends uvm_test;
  `uvm_component_utils(master_write_test)
 
  master_test_env env;
  master_write_vseq vseq;
  
  function new(string name = "master_write_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = master_test_env::type_id::create("env", this);
    vseq = master_write_vseq::type_id::create("vseq");
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vseq.mfifo_sqr = env.mfifo_agnt.sqr;
    vseq.i2c_sqr = env.i2c_agnt.sqr;
    vseq.i2c_master_reg_mod = env.i2c_master_reg_mod;
    
  endfunction: connect_phase
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    repeat (30) begin
      vseq.start(null);
      env.scbd.evaluate();
    end
    
    phase.drop_objection(this);
    
  endtask: run_phase
endclass

class master_read_test extends uvm_test;
  `uvm_component_utils(master_read_test)
 
  master_test_env env;
  master_read_vseq read_vseq;
  
  function new(string name = "master_read_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = master_test_env::type_id::create("env", this);
    read_vseq = master_read_vseq::type_id::create("master_read_vseq");
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    read_vseq.mfifo_sqr = env.mfifo_agnt.sqr;
    read_vseq.i2c_sqr = env.i2c_agnt.sqr;
    read_vseq.i2c_master_reg_mod = env.i2c_master_reg_mod;
    
  endfunction: connect_phase
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    repeat (30) begin
      read_vseq.start(null);
      env.scbd.evaluate();
    end
    
    phase.drop_objection(this);
    
  endtask: run_phase
endclass

class master_read_addr_test extends uvm_test;
  `uvm_component_utils(master_read_addr_test)
 
  master_test_env env;
  master_read_addr_vseq read_addr_vseq;
  
  function new(string name = "master_read_addr_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = master_test_env::type_id::create("env", this);
    read_addr_vseq = master_read_addr_vseq::type_id::create("read_addr_vseq");
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    read_addr_vseq.mfifo_sqr = env.mfifo_agnt.sqr;
    read_addr_vseq.i2c_sqr = env.i2c_agnt.sqr;
    read_addr_vseq.i2c_master_reg_mod = env.i2c_master_reg_mod;
    
  endfunction: connect_phase
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    repeat (30) begin
      read_addr_vseq.start(null);
      env.scbd.evaluate();
    end
   
    phase.drop_objection(this);
    
  endtask: run_phase
endclass

class master_combined_test extends uvm_test;
  `uvm_component_utils(master_combined_test)
 
  master_test_env env;
  master_write_vseq write_vseq;
  master_read_vseq read_vseq;
  master_read_addr_vseq read_addr_vseq;
  
  function new(string name = "master_combined_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = master_test_env::type_id::create("env", this);
    write_vseq = master_write_vseq::type_id::create("write_vseq");
    read_vseq = master_read_vseq::type_id::create("read_vseq");
    read_addr_vseq = master_read_addr_vseq::type_id::create(
      "read_addr_vseq"
    );
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    write_vseq.mfifo_sqr = env.mfifo_agnt.sqr;
    write_vseq.i2c_sqr = env.i2c_agnt.sqr;
    write_vseq.i2c_master_reg_mod = env.i2c_master_reg_mod;
    
    read_vseq.mfifo_sqr = env.mfifo_agnt.sqr;
    read_vseq.i2c_sqr = env.i2c_agnt.sqr;
    read_vseq.i2c_master_reg_mod = env.i2c_master_reg_mod;
    
    read_addr_vseq.mfifo_sqr = env.mfifo_agnt.sqr;
    read_addr_vseq.i2c_sqr = env.i2c_agnt.sqr;
    read_addr_vseq.i2c_master_reg_mod = env.i2c_master_reg_mod;
    
  endfunction: connect_phase
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
  task run_phase(uvm_phase phase);
    integer idx = 0;
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    repeat (30) begin
      idx = $urandom % 3;
      case (idx)
        0: write_vseq.start(null);
        1: read_vseq.start(null);
        2: read_addr_vseq.start(null);
      endcase
      env.scbd.evaluate();
    end
    
    phase.drop_objection(this);
    
  endtask: run_phase
endclass

class slave_write_test extends uvm_test;
  `uvm_component_utils(slave_write_test)
 
  slave_test_env env;
  slave_write_vseq write_vseq;
  
  function new(string name = "slave_write_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = slave_test_env::type_id::create("env", this);
    write_vseq = slave_write_vseq::type_id::create("write_vseq");
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    write_vseq.i2c_sqr = env.i2c_agnt.sqr;
    write_vseq.mem_sqr = env.mem_agnt.sqr;
    
  endfunction: connect_phase
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    repeat (30) begin
      write_vseq.start(null);
      env.scbd.evaluate();
    end
    
    phase.drop_objection(this);
    
  endtask: run_phase
endclass

class slave_read_test extends uvm_test;
  `uvm_component_utils(slave_read_test)
 
  slave_test_env env;
  slave_read_vseq read_vseq;
  
  function new(string name = "slave_read_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = slave_test_env::type_id::create("env", this);
    read_vseq = slave_read_vseq::type_id::create("read_vseq");
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    read_vseq.i2c_sqr = env.i2c_agnt.sqr;
    read_vseq.mem_sqr = env.mem_agnt.sqr;
    
  endfunction: connect_phase
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    repeat (30) begin
      read_vseq.start(null);
      env.scbd.evaluate();
    end
    
    phase.drop_objection(this);
    
  endtask: run_phase
endclass

class slave_read_addr_test extends uvm_test;
  `uvm_component_utils(slave_read_addr_test)
 
  slave_test_env env;
  slave_read_addr_vseq read_vseq;
  
  function new(string name = "slave_read_addr_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = slave_test_env::type_id::create("env", this);
    read_vseq = slave_read_addr_vseq::type_id::create("read_vseq");
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    read_vseq.i2c_sqr = env.i2c_agnt.sqr;
    read_vseq.mem_sqr = env.mem_agnt.sqr;
    
  endfunction: connect_phase
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    repeat (30) begin
      read_vseq.start(null);
      env.scbd.evaluate();
    end
    
    phase.drop_objection(this);
    
  endtask: run_phase
endclass

class slave_addr_test extends uvm_test;
  `uvm_component_utils(slave_addr_test)
 
  slave_test_env env;
  slave_addr_vseq addr_vseq;
  
  function new(string name = "slave_addr_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = slave_test_env::type_id::create("env", this);
    addr_vseq = slave_addr_vseq::type_id::create("addr_vseq");
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    addr_vseq.i2c_sqr = env.i2c_agnt.sqr;
    addr_vseq.mem_sqr = env.mem_agnt.sqr;
    
  endfunction: connect_phase
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    repeat (30) begin
      addr_vseq.start(null);
      env.scbd.evaluate();
    end
    
    phase.drop_objection(this);
    
  endtask: run_phase
endclass

class slave_combined_test extends uvm_test;
  `uvm_component_utils(slave_combined_test)
 
  slave_test_env env;
  slave_write_vseq write_vseq;
  slave_read_vseq read_vseq;
  slave_read_addr_vseq read_addr_vseq;
  slave_addr_vseq addr_vseq;
  
  function new(string name = "slave_combined_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = slave_test_env::type_id::create("env", this);
    write_vseq = slave_write_vseq::type_id::create("write_vseq");
    read_vseq = slave_read_vseq::type_id::create("read_vseq");
    read_addr_vseq = slave_read_addr_vseq::type_id::create("read_addr_vseq");
    addr_vseq = slave_addr_vseq::type_id::create("write_vseq");
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    write_vseq.i2c_sqr = env.i2c_agnt.sqr;
    write_vseq.mem_sqr = env.mem_agnt.sqr;
    
    read_vseq.i2c_sqr = env.i2c_agnt.sqr;
    read_vseq.mem_sqr = env.mem_agnt.sqr;
    
    read_addr_vseq.i2c_sqr = env.i2c_agnt.sqr;
    read_addr_vseq.mem_sqr = env.mem_agnt.sqr;
    
    addr_vseq.i2c_sqr = env.i2c_agnt.sqr;
    addr_vseq.mem_sqr = env.mem_agnt.sqr;
    
  endfunction: connect_phase
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
  task run_phase(uvm_phase phase);
    integer idx = 0;
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    repeat (30) begin
      idx = $urandom % 4;
      case (idx)
        0: write_vseq.start(null);
        1: read_vseq.start(null);
        2: read_addr_vseq.start(null);
        3: addr_vseq.start(null);
      endcase
      env.scbd.evaluate();
    end
    
    phase.drop_objection(this);
    
  endtask: run_phase
endclass
  
class integration_rw_test extends uvm_test;
  `uvm_component_utils(integration_rw_test)
 
  integration_test_env env;
  master_write_read_vseq wr_vseq;
  
  function new(string name = "integration_rw_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    env = integration_test_env::type_id::create("env", this);
    wr_vseq = master_write_read_vseq::type_id::create("wr_vseq");
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    wr_vseq.mfifo_sqr = env.mfifo_agnt.sqr;
    wr_vseq.mem_sqr = env.mem_agnt.sqr;
    wr_vseq.i2c_master_reg_mod = env.i2c_master_reg_mod;
    
  endfunction: connect_phase
  
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
  task run_phase(uvm_phase phase);
    integer idx = 0;
    super.run_phase(phase);
    
    phase.raise_objection(this);
    
    repeat (30) begin
      wr_vseq.start(null);
      env.mfifo_scbd.evaluate();
      env.mem_scbd.evaluate();
    end
    
    phase.drop_objection(this);
    
  endtask: run_phase
endclass