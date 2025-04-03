`include "seq_items.sv"

interface mem_interface (input logic clk);
  logic rw; // 1 means read
  logic en;
  logic rst;
  logic busy;
  logic [7:0] addr;
  logic [7:0] data_i;
  logic [7:0] data_o;
endinterface: mem_interface

class mem_agent_cfg extends uvm_object;
  `uvm_object_utils(mem_agent_cfg)
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  uvm_active_passive_enum mon_logs = UVM_PASSIVE;
  
  function new(
    string name = "mem_agent_cfg",
    uvm_active_passive_enum is_active = UVM_ACTIVE,
    uvm_active_passive_enum mon_logs = UVM_ACTIVE
  );
    super.new(name);
    this.mon_logs = mon_logs;
    this.is_active = is_active;
  endfunction: new
endclass: mem_agent_cfg

class mem_driver extends uvm_driver#(mem_seq_item);
  `uvm_component_utils(mem_driver)
  
  virtual mem_interface vif;
  
  mem_seq_item req;
  mem_seq_item rsp;
  
  function new(string name = "mem_driver", uvm_component parent);
    super.new(name, parent);
    
    if (!uvm_config_db#(virtual mem_interface)::get(
      this, "", "mem_interface", vif
    ))
      `uvm_fatal(get_type_name(), "failed to get mem_interface virtual interface");
    
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction: build_phase
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction: connect_phase
    
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    rsp = mem_seq_item::type_id::create("rsp");
    
    // drive sequence items from seq_item_port
    forever begin
      seq_item_port.get_next_item(req);
      
      if (req.kind == mem_seq_item::RESET) begin
        vif.rst = 1;
        @(negedge vif.clk);
        vif.rst = 0;
        rsp.set_id_info(req);
      end
      else begin
        vif.en = 1;
        vif.rw = req.kind == mem_seq_item::READ;
        vif.addr = req.addr;
        vif.data_i = req.kind == mem_seq_item::READ ? 8'h00 : req.data;

        @(posedge vif.clk);
        #1;

        rsp.kind = req.kind;
        rsp.addr = req.addr;
        rsp.data = vif.data_o;
        rsp.set_id_info(req);

        @(negedge vif.clk);
        vif.en = 0;
      end
      
      seq_item_port.item_done(rsp);
    end
    
  endtask: run_phase
  
endclass

class mem_analysis_comp extends uvm_subscriber#(mem_seq_item);
  `uvm_component_utils(mem_analysis_comp);
  
  mem_seq_item item;
  
  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  function void write(mem_seq_item t);
    $display("MON: %s", t.convert2string());
  endfunction
  
endclass

class mem_monitor extends uvm_monitor;
  `uvm_component_utils(mem_monitor)
  
  virtual mem_interface vif;
  
  mem_seq_item req;
  mem_seq_item cmd;
  
  uvm_analysis_port #(mem_seq_item) ap;
  
  function new(string name = "mem_monitor", uvm_component parent);
    super.new(name, parent);
    
    if (!uvm_config_db#(virtual mem_interface)::get(
      this, "", "mem_interface", vif
    ))
      `uvm_fatal(get_type_name(), "failed to get mem_interface virtual interface");
    ap = new("ap", this);
    
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction: build_phase
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction: connect_phase
    
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    req = mem_seq_item::type_id::create("req");
    cmd = mem_seq_item::type_id::create("cmd");

    forever begin
      @(posedge vif.clk);
      #1;

      req.kind = vif.rw ? mem_seq_item::READ : mem_seq_item::WRITE;
      req.addr = vif.addr;
      req.data = vif.rw ? vif.data_o : vif.data_i;

      if (vif.en) ap.write(req);
    end
    
  endtask: run_phase
  
endclass

class mem_sequencer extends uvm_sequencer#(mem_seq_item);
  `uvm_component_utils(mem_sequencer)
  
  function new(string name = "mem_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction: build_phase
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction: connect_phase
    
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask: run_phase
  
endclass

class mem_agent extends uvm_agent;
  `uvm_component_utils(mem_agent)
  
  mem_agent_cfg cfg;
  mem_driver drv;
  mem_monitor mon;
  mem_sequencer sqr;
  mem_analysis_comp ac;
  
  function new(string name = "mem_agent", uvm_component parent);
    super.new(name, parent);
    
    // get agent config
    if (!uvm_config_db#(mem_agent_cfg)::get(
      this, "", "mem_agent_cfg", cfg
    ))
      cfg = mem_agent_cfg::type_id::create("cfg");
    
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // build monitor
    mon = mem_monitor::type_id::create("mon", this);
    if (cfg.mon_logs) ac = mem_analysis_comp::type_id::create("ac", this);
    
    // build driver and sequencer
    if (cfg.is_active) begin
      sqr = mem_sequencer::type_id::create("sqr", this);
      drv = mem_driver::type_id::create("drv", this);
    end
    
  endfunction: build_phase
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
    if (cfg.mon_logs) mon.ap.connect(ac.analysis_export);
  endfunction: connect_phase
    
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask: run_phase
  
endclass