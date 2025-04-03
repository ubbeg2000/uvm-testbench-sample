class master_test_env extends uvm_env;
  `uvm_component_utils(master_test_env)
 
  // config instances
  i2c_agent_cfg i2c_agnt_cfg;
  
  // agents
  mfifo_agent mfifo_agnt;
  i2c_agent i2c_agnt;
  
  // register models and adapters
  i2c_master_reg_model i2c_master_reg_mod;
  i2c_master_reg_adapter i2c_master_reg_adp;
  
  // analysis components
  mfifo_i2c_scoreboard scbd;
  i2c_coverage i2c_cov;
  mfifo_coverage mfifo_cov;
  
  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
    
    i2c_agnt_cfg = i2c_agent_cfg::type_id::create("i2c_agnt_cfg");
    i2c_agnt_cfg.is_active = UVM_ACTIVE;
    i2c_agnt_cfg.is_master = UVM_PASSIVE;
    
    uvm_config_db #(i2c_agent_cfg)::set(
      null, "*", "i2c_agent_cfg", i2c_agnt_cfg
    );
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    mfifo_agnt = mfifo_agent::type_id::create("mfifo_agnt", this);
    i2c_agnt = i2c_agent::type_id::create("i2c_agnt", this);
    
    i2c_master_reg_mod = i2c_master_reg_model::type_id::create(
      "i2c_master_reg_mod", this
    );
    i2c_master_reg_mod.build();
    i2c_master_reg_mod.reset();
    i2c_master_reg_mod.lock_model();
    i2c_master_reg_mod.print();
    i2c_master_reg_adp = i2c_master_reg_adapter::type_id::create(
      "i2c_master_reg_adapter", this
    );
    
    scbd = mfifo_i2c_scoreboard::type_id::create("scbd", this);
    i2c_cov = i2c_coverage::type_id::create("i2c_cov", this);
    mfifo_cov = mfifo_coverage::type_id::create("mfifo_cov", this);
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    mfifo_agnt.mon.ap.connect(scbd.mfifo_exp);
    mfifo_agnt.mon.ap.connect(mfifo_cov.analysis_export);
    i2c_agnt.mon.ap.connect(scbd.i2c_exp);
    i2c_agnt.mon.ap.connect(i2c_cov.analysis_export);
    i2c_master_reg_mod.default_map.set_sequencer(
      .sequencer(mfifo_agnt.sqr), 
      .adapter(i2c_master_reg_adp)
    );
    i2c_master_reg_mod.default_map.set_base_addr('h0); 
  endfunction: connect_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask: run_phase
  
endclass

class slave_test_env extends uvm_test;
  `uvm_component_utils(slave_test_env)
 
  // config instances
  i2c_agent_cfg i2c_agnt_cfg;
  mem_agent_cfg mem_agnt_cfg;
  
  // agents
  mem_agent mem_agnt;
  i2c_agent i2c_agnt;
  
  // analysis components
  i2c_mem_scoreboard scbd;
  mem_coverage mem_cov;
  i2c_coverage i2c_cov;
  
  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
    
    i2c_agnt_cfg = i2c_agent_cfg::type_id::create("i2c_agnt_cfg");
    i2c_agnt_cfg.is_active = UVM_ACTIVE;
    i2c_agnt_cfg.is_master = UVM_ACTIVE;
    
    mem_agnt_cfg = mem_agent_cfg::type_id::create("mem_agnt_cfg");
    mem_agnt_cfg.is_active = UVM_ACTIVE;
    
    scbd = i2c_mem_scoreboard::type_id::create("scbd", this);
    
    uvm_config_db #(i2c_agent_cfg)::set(
      null, "*", "i2c_agent_cfg", i2c_agnt_cfg
    );
    uvm_config_db #(mem_agent_cfg)::set(
      null, "*", "mem_agent_cfg", mem_agnt_cfg
    );
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    mem_agnt = mem_agent::type_id::create("mem_agnt", this);
    i2c_agnt = i2c_agent::type_id::create("i2c_agnt", this);
    
    mem_cov = mem_coverage::type_id::create("mem_cov", this);
    i2c_cov = i2c_coverage::type_id::create("i2c_cov", this);
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    i2c_agnt.mon.ap.connect(scbd.i2c_exp);
    i2c_agnt.mon.ap.connect(i2c_cov.analysis_export);
    mem_agnt.mon.ap.connect(scbd.mem_exp);
    mem_agnt.mon.ap.connect(mem_cov.analysis_export);
  endfunction: connect_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask: run_phase
endclass

class integration_test_env extends uvm_test;
  `uvm_component_utils(integration_test_env)
 
  // config instances
  mfifo_agent_cfg mfifo_agnt_cfg;
  mem_agent_cfg mem_agnt_cfg;
  i2c_agent_cfg i2c_agnt_cfg;
  
  // agents
  mfifo_agent mfifo_agnt;
  mem_agent mem_agnt;
  i2c_agent i2c_agnt;
  
  // register models and adapters
  i2c_master_reg_model i2c_master_reg_mod;
  i2c_master_reg_adapter i2c_master_reg_adp;
  
  // analysis components
  mfifo_i2c_scoreboard mfifo_scbd;
  i2c_mem_scoreboard mem_scbd;
  i2c_coverage i2c_cov;
  mem_coverage mem_cov;
  mfifo_coverage mfifo_cov;
  
  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
    
    i2c_agnt_cfg = i2c_agent_cfg::type_id::create("i2c_agnt_cfg");
    i2c_agnt_cfg.is_active = UVM_PASSIVE;
    
    mem_agnt_cfg = mem_agent_cfg::type_id::create("mem_agnt_cfg");
    mem_agnt_cfg.is_active = UVM_ACTIVE;
    
    mfifo_agnt_cfg = mfifo_agent_cfg::type_id::create("mfifo_agnt_cfg");
    mfifo_agnt_cfg.is_active = UVM_ACTIVE;
    
    uvm_config_db #(i2c_agent_cfg)::set(
      null, "*", "i2c_agent_cfg", i2c_agnt_cfg
    );
    uvm_config_db #(mem_agent_cfg)::set(
      null, "*", "mem_agent_cfg", mem_agnt_cfg
    );
    uvm_config_db #(mfifo_agent_cfg)::set(
      null, "*", "mfifo_agent_cfg", mfifo_agnt_cfg
    );
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    mfifo_agnt = mfifo_agent::type_id::create("mfifo_agnt", this);
    mem_agnt = mem_agent::type_id::create("mem_agnt", this);
    i2c_agnt = i2c_agent::type_id::create("i2c_agnt", this);
    
    i2c_master_reg_mod = i2c_master_reg_model::type_id::create(
      "i2c_master_reg_mod", this
    );
    i2c_master_reg_mod.build();
    i2c_master_reg_mod.reset();
    i2c_master_reg_mod.lock_model();
    i2c_master_reg_mod.print();
    i2c_master_reg_adp = i2c_master_reg_adapter::type_id::create(
      "i2c_master_reg_adapter", this
    );
    
    mfifo_scbd = mfifo_i2c_scoreboard::type_id::create("mfifo_scbd", this);
    mem_scbd = i2c_mem_scoreboard::type_id::create("mem_scbd", this);
    
    mfifo_cov = mfifo_coverage::type_id::create("mfifo_cov", this);
    mem_cov = mem_coverage::type_id::create("mem_cov", this);
    i2c_cov = i2c_coverage::type_id::create("i2c_cov", this);
    
  endfunction: build_phase
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    i2c_master_reg_mod.default_map.set_sequencer(
      .sequencer(mfifo_agnt.sqr), 
      .adapter(i2c_master_reg_adp)
    );
    i2c_master_reg_mod.default_map.set_base_addr('h0); 
    
    mfifo_agnt.mon.ap.connect(mfifo_scbd.mfifo_exp);
    i2c_agnt.mon.ap.connect(mfifo_scbd.i2c_exp);
    mem_agnt.mon.ap.connect(mem_scbd.mem_exp);
    i2c_agnt.mon.ap.connect(mem_scbd.i2c_exp);
    
    mfifo_agnt.mon.ap.connect(mfifo_cov.analysis_export);
    mem_agnt.mon.ap.connect(mem_cov.analysis_export);
    i2c_agnt.mon.ap.connect(i2c_cov.analysis_export);
    
  endfunction: connect_phase
  
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask: run_phase
endclass