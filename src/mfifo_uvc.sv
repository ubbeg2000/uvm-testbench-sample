`include "seq_items.sv"

interface mfifo_interface #(parameter R_DATA_DEPTH = 8) (input logic clk);
  // reset signal
  logic rst;
  
  // i2c control signals
  logic i2c_send;
  logic [31:0] command;
//   logic i2c_rw;
//   logic [6:0] i2c_addr;
//   logic i2c_data_addr_en;
//   logic [7:0] i2c_data_addr;
//   logic [14:0] i2c_data_len;
  
  // buffer control signals
  logic w_en;
  logic r_en;
  
  // fifo buffer signals
  logic [7:0] w_data;
  logic [7:0] r_data;
  
  // status
  logic [31:0] status;
endinterface: mfifo_interface

class mfifo_agent_cfg extends uvm_object;
  `uvm_object_utils(mfifo_agent_cfg)
  
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  uvm_active_passive_enum mon_logs = UVM_ACTIVE;
  
  function new(
    string name = "mfifo_agent_cfg",
    uvm_active_passive_enum is_active = UVM_ACTIVE,
    uvm_active_passive_enum mon_logs = UVM_ACTIVE
  );
    super.new(name);
    this.mon_logs = mon_logs;
    this.is_active = is_active;
  endfunction: new
endclass: mfifo_agent_cfg

class mfifo_driver extends uvm_driver#(mfifo_seq_item);
  `uvm_component_utils(mfifo_driver)
  
  virtual mfifo_interface vif;
  
  mfifo_seq_item req;
  mfifo_seq_item rsp;
  
  function new(string name = "mfifo_driver", uvm_component parent);
    super.new(name, parent);
    
    if (!uvm_config_db#(virtual mfifo_interface)::get(
      this, "", "mfifo_interface", vif
    ))
      `uvm_fatal(get_type_name(), "failed to get mfifo_interface virtual interface");
    
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction: build_phase
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction: connect_phase
    
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    rsp = mfifo_seq_item::type_id::create("rsp");
    
    // drive sequence items from seq_item_port
    forever begin
      seq_item_port.get_next_item(req);

      vif.rst = req.rst;
      vif.i2c_send = req.i2c_send;
      vif.command[31:25] = req.i2c_addr;
      vif.command[24:17] = req.i2c_data_addr;
      vif.command[16] = req.i2c_data_addr_en;
      vif.command[15] = req.i2c_rw;
      vif.command[14:0] = req.i2c_data_len;
      vif.w_en = ~req.rw & req.en;
      vif.r_en = req.rw & req.en;
      if (~req.rw) vif.w_data = req.data;

      @(negedge vif.clk);
      rsp.busy = vif.status[31];
      rsp.fail_code = vif.status[30:20];
      rsp.read_buffer_full = vif.status[19];
      rsp.read_buffer_empty = vif.status[18];
      rsp.write_buffer_full = vif.status[17];
      rsp.write_buffer_empty = vif.status[16];
      rsp.read_buffer_cnt = vif.status[15:8];
      rsp.write_buffer_cnt = vif.status[7:0];
      rsp.set_id_info(req);
      
      seq_item_port.item_done(rsp);
    end
    
  endtask: run_phase
  
endclass

class mfifo_analysis_comp extends uvm_subscriber#(mfifo_seq_item);
  `uvm_component_utils(mfifo_analysis_comp);
  
  mfifo_seq_item item;
  
  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  function void write(mfifo_seq_item t);
    $display("MON: %s", t.convert2string());
  endfunction
  
endclass

class mfifo_monitor extends uvm_monitor;
  `uvm_component_utils(mfifo_monitor)
  
  virtual mfifo_interface vif;
  
  mfifo_seq_item req;
  mfifo_seq_item cmd;
  
  uvm_analysis_port #(mfifo_seq_item) ap;
  
  function new(string name = "mfifo_monitor", uvm_component parent);
    super.new(name, parent);
    
    if (!uvm_config_db#(virtual mfifo_interface)::get(
      this, "", "mfifo_interface", vif
    ))
      `uvm_fatal(get_type_name(), "failed to get mfifo_interface virtual interface");
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
    
    req = mfifo_seq_item::type_id::create("req");
    cmd = mfifo_seq_item::type_id::create("cmd");
    
    fork
      forever begin
        @(posedge vif.clk);
        req.kind = mfifo_seq_item::MFIFO_CONTROL;
        
        // reset signal
        req.rst = vif.rst;

        // fifo buffer signals
        req.data = vif.r_en ? vif.r_data : vif.w_data;
        req.en = vif.r_en | vif.w_en;
        req.rw = vif.r_en;

        if (req.rst | req.en) ap.write(req);

        @(negedge vif.clk);
        req.kind = mfifo_seq_item::MFIFO_STATUS;

        // status fields for response
        req.busy = vif.status[31];
        req.fail_code = vif.status[30:20];
        req.read_buffer_full = vif.status[19];
        req.read_buffer_empty = vif.status[18];
        req.write_buffer_full = vif.status[17];
        req.write_buffer_empty = vif.status[16];
        req.read_buffer_cnt = vif.status[15:8];
        req.write_buffer_cnt = vif.status[7:0];

        if (req.rst | req.en) ap.write(req);
      end
      forever begin
        @(posedge vif.i2c_send);
        cmd.kind = mfifo_seq_item::MFIFO_COMMAND;

        // i2c control signals
        cmd.i2c_send = vif.i2c_send;
        cmd.i2c_addr = vif.command[31:25];
        cmd.i2c_data_addr = vif.command[24:17];
        cmd.i2c_data_addr_en = vif.command[16];
        cmd.i2c_rw = vif.command[15];
        cmd.i2c_data_len = vif.command[14:0];
        
        ap.write(cmd);

        @(negedge vif.status[31]);
        cmd.kind = mfifo_seq_item::MFIFO_COMMAND_STATUS;

        // status fields for response
        cmd.busy = vif.status[31];
        cmd.fail_code = vif.status[30:20];
        cmd.read_buffer_full = vif.status[19];
        cmd.read_buffer_empty = vif.status[18];
        cmd.write_buffer_full = vif.status[17];
        cmd.write_buffer_empty = vif.status[16];
        cmd.read_buffer_cnt = vif.status[15:8];
        cmd.write_buffer_cnt = vif.status[7:0];
        
        ap.write(cmd);
        
      end
    join
    
  endtask: run_phase
  
endclass

class mfifo_sequencer extends uvm_sequencer#(mfifo_seq_item);
  `uvm_component_utils(mfifo_sequencer)
  
  function new(string name = "mfifo_sequencer", uvm_component parent);
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

class mfifo_agent extends uvm_agent;
  `uvm_component_utils(mfifo_agent)
  
  mfifo_agent_cfg cfg;
  mfifo_driver drv;
  mfifo_monitor mon;
  mfifo_sequencer sqr;
  mfifo_analysis_comp ac;
  
  function new(string name = "mfifo_agent", uvm_component parent);
    super.new(name, parent);
    
    // get agent config
    if (!uvm_config_db#(mfifo_agent_cfg)::get(
      this, "", "mfifo_agent_cfg", cfg
    ))
      cfg = mfifo_agent_cfg::type_id::create("cfg");
    
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // build monitor
    mon = mfifo_monitor::type_id::create("mon", this);
    if (cfg.mon_logs) ac = mfifo_analysis_comp::type_id::create("ac", this);
    
    // build driver and sequencer
    if (cfg.is_active) begin
      sqr = mfifo_sequencer::type_id::create("sqr", this);
      drv = mfifo_driver::type_id::create("drv", this);
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