`include "seq_items.sv"

interface i2c_interface(input logic clk);
  logic sda_i;
  logic sda_o;
  logic scl_i;
  logic scl_o;
  logic sda_o_en;
endinterface: i2c_interface

class i2c_agent_cfg extends uvm_object;
  `uvm_object_utils(i2c_agent_cfg)
  
  uvm_active_passive_enum is_active;
  uvm_active_passive_enum is_master;
  uvm_active_passive_enum mon_logs;
  
  function new(
    string name = "i2c_agent_cfg",
    uvm_active_passive_enum is_active = UVM_ACTIVE,
    uvm_active_passive_enum is_master = UVM_ACTIVE,
    uvm_active_passive_enum mon_logs = UVM_ACTIVE
  );
    super.new(name);
    this.mon_logs = mon_logs;
    this.is_active = is_active;
    this.is_master = is_master;
  endfunction: new
endclass

class i2c_master_driver extends uvm_driver#(i2c_seq_item);
  `uvm_component_utils(i2c_master_driver)
  
  i2c_seq_item req;
  i2c_seq_item rsp;
  
  virtual i2c_interface vif;
  
  function new(string name = "i2c_master_driver", uvm_component parent);
    super.new(name, parent);
    
    if (!uvm_config_db#(virtual i2c_interface)::get(
      this, "", "i2c_interface", vif
    ))
      `uvm_fatal(get_type_name(), "failed to get i2c_interface virtual interface");
    
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction: build_phase
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction: connect_phase
    
  task run_phase(uvm_phase phase);
    int idx = 0;
    
    super.run_phase(phase);
    
    vif.sda_o = 1;
    vif.scl_o = 1;
    vif.sda_o_en = 1;
    rsp = i2c_seq_item::type_id::create("rsp");
    forever begin
      seq_item_port.get_next_item(req);
      
      vif.sda_o_en = 1;
      case (req.kind)
        i2c_seq_item::IDLE: begin
          for (int i = 0; i < 2; i = i + 1) begin
            vif.scl_o = 1;
            vif.sda_o = 1;
            @(negedge vif.clk);
          end
        end
        i2c_seq_item::START: begin
          for (int i = 0; i < 2; i = i + 1) begin
            vif.scl_o = 1;
            vif.sda_o = ~i;
            @(negedge vif.clk);
          end
        end
        i2c_seq_item::ADDR: begin
          for (int i = 0; i < 14; i = i + 1) begin
            idx = i >> 1;
            vif.sda_o = req.addr[6 - idx];
            vif.scl_o = i[0];
            @(negedge vif.clk);
          end
          for (int i = 0; i < 2; i = i + 1) begin
            vif.sda_o = req.rw;
            vif.scl_o = i[0];
            @(negedge vif.clk);
          end
          for (int i = 0; i < 2; i = i + 1) begin
            vif.scl_o = i[0];
            vif.sda_o_en = 0;
            rsp.kind = vif.sda_i ? i2c_seq_item::NACK : i2c_seq_item::ACK;
            @(negedge vif.clk);
          end
        end
        i2c_seq_item::DATA: begin
          for (int i = 0; i < 16; i = i + 1) begin
            idx = i >> 1;
            vif.sda_o = req.data[7 - idx];
            vif.scl_o = i[0];
            @(negedge vif.clk);
          end
          for (int i = 0; i < 2; i = i + 1) begin
            vif.scl_o = i[0];
            vif.sda_o_en = 0;
            vif.sda_o = 1;
            rsp.kind = vif.sda_i ? i2c_seq_item::NACK : i2c_seq_item::ACK;
            @(negedge vif.clk);
          end
        end
        i2c_seq_item::ACK: begin
          for (int i = 0; i < 16; i = i + 1) begin
            vif.sda_o_en = 0;
            vif.scl_o = i[0];
            @(negedge vif.clk);
          end
          for (int i = 0; i < 2; i = i + 1) begin
            vif.sda_o = 0;
            vif.sda_o_en = 1;
            vif.scl_o = i[0];
            @(negedge vif.clk);
          end
        end
        i2c_seq_item::NACK: begin
          for (int i = 0; i < 16; i = i + 1) begin
            vif.sda_o_en = 0;
            vif.scl_o = i[0];
            @(negedge vif.clk);
          end
          for (int i = 0; i < 2; i = i + 1) begin
            vif.sda_o = 1;
            vif.sda_o_en = 1;
            vif.scl_o = i[0];
            @(negedge vif.clk);
          end
        end
        i2c_seq_item::STOP: begin
          for (integer i = 0; i < 2; i = i + 1) begin
            vif.scl_o = 1;
            vif.sda_o = i;
            @(negedge vif.clk);
          end
        end
      endcase
      
      rsp.set_id_info(req);
      seq_item_port.item_done(rsp);
    end
    
  endtask: run_phase
  
endclass

class i2c_slave_driver extends uvm_driver#(i2c_seq_item);
  `uvm_component_utils(i2c_slave_driver)
  
  i2c_seq_item req;
  i2c_seq_item rsp;
  int state_res_cnt = 0;
  bit got_nack = 0;
  
  bit [1:0] scl_sample, sda_sample;
  bit sda_rising_edge, sda_falling_edge, sda_high, sda_low;
  bit scl_rising_edge, scl_falling_edge, scl_high, scl_low;
  
  virtual i2c_interface vif;
  
  function new(string name = "i2c_slave_driver", uvm_component parent);
    super.new(name, parent);
    
    if (!uvm_config_db#(virtual i2c_interface)::get(
      this, "", "i2c_interface", vif
    ))
      `uvm_fatal(get_type_name(), "failed to get i2c_interface virtual interface");
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction: build_phase
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction: connect_phase
    
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    fork
      forever begin
        @(posedge vif.clk);
        #1;
        scl_sample[1] <= scl_sample[0];
        scl_sample[0] <= vif.scl_o;
        sda_sample[1] <= sda_sample[0];
        sda_sample[0] <= vif.sda_o;
        
        sda_rising_edge <= {sda_sample[0], vif.sda_o} == 2'b01;
        sda_falling_edge <= {sda_sample[0], vif.sda_o} == 2'b10;
        sda_high <= {sda_sample[0], vif.sda_o} == 2'b11;
        sda_low <= {sda_sample[0], vif.sda_o} == 2'b00;
        
        scl_rising_edge <= {scl_sample[0], vif.scl_o} == 2'b01;
        scl_falling_edge <= {scl_sample[0], vif.scl_o} == 2'b10;
        scl_high <= {scl_sample[0], vif.scl_o} == 2'b11;
        scl_low <= {scl_sample[0], vif.scl_o} == 2'b00;
      end
      
      // data parsing
      forever begin
        integer data_index = 0;
        bit got_stop = 0;
        
        // wait for start condition
        vif.sda_i = 1;
        state_res_cnt = 0;
        wait (scl_high & sda_falling_edge);
        
        forever begin
          //wait for scl falling edge before driving any signals
          while (~scl_falling_edge) begin
            #1;
            if (scl_high & sda_rising_edge) begin
              got_stop = 1;
              state_res_cnt = 0;
              break;
            end
          end
          if (got_stop) begin
            got_stop = 0;
            break;
          end
          
          // drive sda_i signal
          if (state_res_cnt == 0) begin
            seq_item_port.get_next_item(req);
            seq_item_port.item_done();
          end
          
          case (req.kind)
            i2c_seq_item::DATA: begin
              data_index = 7-state_res_cnt;
              if (state_res_cnt < 8) vif.sda_i = req.data[data_index];
              else vif.sda_i = 0;
            end
            i2c_seq_item::ACK: begin
              vif.sda_i = state_res_cnt == 8 ? 0 : 1;
            end
            i2c_seq_item::NACK: begin
              vif.sda_i = 1;
            end
            default: begin
              vif.sda_i = state_res_cnt == 8 ? 0 : 1;
            end
          endcase
          state_res_cnt = (state_res_cnt + 1) % 9;
          
          if (state_res_cnt == 8) begin
            seq_item_port.get_next_item(rsp);
            seq_item_port.item_done();
          end
          
          @(posedge vif.clk);
          // break on stop condition
          if (scl_high & sda_rising_edge) break;
          
          // do nothing on repeated start
          if (scl_high & sda_falling_edge) continue;
          
          // if got stop condition, break out of loop
          while (~scl_rising_edge) begin
            @(posedge vif.clk);
            if (scl_high & sda_rising_edge) begin
              got_stop = 1;
              state_res_cnt = 0;
              break;
            end
          end
          if (got_stop) begin
            got_stop = 0;
            break;
          end
        end
      end
    join
  endtask: run_phase
  
endclass

class i2c_analysis_comp extends uvm_subscriber#(i2c_seq_item);
  `uvm_component_utils(i2c_analysis_comp);
  
  i2c_seq_item item;
  
  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  function void write(i2c_seq_item t);
    $display("MON: %s", t.convert2string());
  endfunction
  
endclass

class i2c_monitor extends uvm_monitor;
  `uvm_component_utils(i2c_monitor)
  
  virtual i2c_interface vif;
  
  i2c_seq_item req, start, stop;
  
  bit prev_sda_samp = 1, sda_samp = 1;
  bit prev_scl_samp = 1, scl_samp = 1;
  bit sda_rising_edge, sda_falling_edge, sda_high = 1, sda_low;
  bit scl_rising_edge, scl_falling_edge, scl_high = 1, scl_low;
  
  bit detected_start = 0;
  bit detected_repeated_start = 0;
  bit detected_stop = 0;
  
  uvm_analysis_port #(i2c_seq_item) ap;
    
  integer state_res_cnt = 0;
  
  function new(string name = "i2c_monitor", uvm_component parent);
    super.new(name, parent);
    
    if (!uvm_config_db#(virtual i2c_interface)::get(
      this, "", "i2c_interface", vif
    ))
      `uvm_fatal(get_type_name(), "failed to get i2c_interface virtual interface");
    
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    req = i2c_seq_item::type_id::create("req");
    stop = i2c_seq_item::type_id::create("stop");
    start = i2c_seq_item::type_id::create("start");
    ap = new("ap", this);
  endfunction: build_phase
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction: connect_phase
    
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    fork
      // start, repeated start, and stop condition detector
      forever begin
        @(posedge vif.clk);
        prev_sda_samp = sda_samp;
        prev_scl_samp = scl_samp;
        sda_samp = vif.sda_o;
        scl_samp = vif.scl_o;
        
        sda_rising_edge = ~prev_sda_samp & sda_samp;
        sda_falling_edge = prev_sda_samp & ~sda_samp;
        sda_high = prev_sda_samp & sda_samp; 
        sda_low = ~prev_sda_samp & ~sda_samp;
        
        scl_rising_edge = ~prev_scl_samp & scl_samp;
        scl_falling_edge = prev_scl_samp & ~scl_samp;
        scl_high = prev_scl_samp & scl_samp; 
        scl_low = ~prev_scl_samp & ~scl_samp;
        
        if (scl_high & sda_falling_edge) begin
          detected_start = 1;
          start.kind = i2c_seq_item::START;
          ap.write(start);
        end
        
        if (scl_high & sda_rising_edge) begin
          stop.kind = i2c_seq_item::STOP;
          ap.write(stop);
        end
      end
      
      forever begin
        integer state_res = 0;
        integer data_index = 0;
        
        // wait for start condition
        wait (scl_high & sda_falling_edge);
        
        forever begin
          @(posedge vif.clk);
          // break on stop condition
          if (scl_high & sda_rising_edge) begin
            state_res_cnt = 0;
            break;
          end
          
          // do nothing on repeated start
          if (scl_high & sda_falling_edge) begin
            state_res_cnt = 0;
            continue;
          end
          
          if (~scl_rising_edge) continue;
          
          if (state_res_cnt != 8) begin
            req.data[7-state_res_cnt] = 
            vif.sda_o_en 
              ? vif.sda_o 
              : vif.sda_i;
            if (state_res_cnt == 7) begin
              req.kind = detected_start 
              	? i2c_seq_item::ADDR 
              	: i2c_seq_item::DATA;
              req.src = vif.sda_o_en 
                ? i2c_seq_item::MASTER 
                : i2c_seq_item::SLAVE;
              req.addr = detected_start ? req.data[7:1] : 6'b000000;
              req.rw = detected_start ? req.data[0] : 1'b0;
              detected_start = 0;
              ap.write(req);
            end
          end
          else begin
            req.src = vif.sda_o_en 
              ? i2c_seq_item::MASTER 
              : i2c_seq_item::SLAVE;
            req.kind = (vif.sda_o_en ? vif.sda_o : vif.sda_i) 
              ? i2c_seq_item::NACK 
              : i2c_seq_item::ACK;
            ap.write(req);
          end

          state_res_cnt = (state_res_cnt + 1) % 9;
        end
      end
    join
    
  endtask: run_phase
  
endclass

class i2c_sequencer extends uvm_sequencer#(i2c_seq_item);
  `uvm_component_utils(i2c_sequencer)
  
  function new(string name = "i2c_sequencer", uvm_component parent);
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

class i2c_agent extends uvm_agent;
  `uvm_component_utils(i2c_agent)
  
  i2c_agent_cfg cfg;
  i2c_master_driver m_drv;
  i2c_slave_driver s_drv;
  i2c_monitor mon;
  i2c_sequencer sqr;
  i2c_analysis_comp ac;
  
  function new(string name = "i2c_agent", uvm_component parent);
    super.new(name, parent);
    
    // get agent config
    if (!uvm_config_db#(i2c_agent_cfg)::get(
      this, "", "i2c_agent_cfg", cfg
    ))
      cfg = i2c_agent_cfg::type_id::create("cfg");
    
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // build monitor
    mon = i2c_monitor::type_id::create("mon", this);
    if (cfg.mon_logs) ac = i2c_analysis_comp::type_id::create("ac", this);
    
    // build driver and sequencer
    if (cfg.is_active) begin
      sqr = i2c_sequencer::type_id::create("sqr", this);
      if (cfg.is_master)
        m_drv = i2c_master_driver::type_id::create("m_drv", this);
      else
        s_drv = i2c_slave_driver::type_id::create("s_drv", this);
    end
    
  endfunction: build_phase
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (cfg.mon_logs) mon.ap.connect(ac.analysis_export);
    if (cfg.is_active) begin
      if (cfg.is_master)
        m_drv.seq_item_port.connect(sqr.seq_item_export);
      else
        s_drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction: connect_phase
    
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
  endtask: run_phase
  
endclass