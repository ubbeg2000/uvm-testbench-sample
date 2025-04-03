`uvm_analysis_imp_decl(_mfifo)
`uvm_analysis_imp_decl(_mem)
`uvm_analysis_imp_decl(_i2c)

class mfifo_i2c_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(mfifo_i2c_scoreboard)
  
  uvm_analysis_imp_mfifo #(
    mfifo_seq_item, mfifo_i2c_scoreboard
  ) mfifo_exp;
  uvm_analysis_imp_i2c #(i2c_seq_item, mfifo_i2c_scoreboard) i2c_exp;
  
  // mode
  bit i2c_data_addr_en;
  
  // modelled state of the ip from observation
  bit i2c_rw, expected_i2c_rw;
  bit [6:0] i2c_addr, expected_i2c_addr;
  bit [7:0] i2c_data_addr, expected_i2c_data_addr;
  bit [7:0] w_data_content[$], expected_w_data_content[$];
  bit [7:0] r_data_content[$], expected_r_data_content[$];
  
  // scoreboard state and data
  bit has_stopped;
  integer read_count = 0, write_count = 0, read_addr_count = 0;
  
  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
    mfifo_exp = new("mfifo_exp", this);
    i2c_exp = new("i2c_exp", this);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info(
      get_type_name(),
      $sformatf(
        "observed %0d write, %0d read, and %0d read addr transcations",
        write_count, read_count, read_addr_count
      ),
      UVM_NONE
    )
  endfunction
  
  function void evaluate();
    int i = 0;
    
    if (~i2c_rw) write_count = write_count + 1;
    if (i2c_data_addr_en & i2c_rw) read_count = read_count + 1;
    if (~i2c_data_addr_en & i2c_rw) read_addr_count = read_addr_count + 1;
    
    if (i2c_data_addr_en) begin
      i2c_data_addr = w_data_content.pop_front();
      if (i2c_data_addr == expected_i2c_data_addr) begin
        `uvm_info(
          get_type_name(),
          $sformatf(
            "got correct i2c data address (act=0x%2h, exp=0x%2h)", 
            i2c_data_addr, expected_i2c_data_addr
          ),
          UVM_NONE
        )
      end
      else begin
        `uvm_error(
          get_type_name(),
          $sformatf(
            "got incorrect i2c data address (act=0x%2h, exp=0x%2h)", 
            i2c_data_addr, expected_i2c_data_addr
          )
        )
      end
    end
    
    if (i2c_addr == expected_i2c_addr) begin
      `uvm_info(
        get_type_name(),
        $sformatf(
          "got correct i2c slave address (act=0x%2h, exp=0x%2h)", 
          i2c_addr, expected_i2c_addr
        ),
        UVM_NONE
      )
    end
    else begin
      `uvm_error(
        get_type_name(),
        $sformatf(
          "got incorrect i2c slave address (act=0x%2h, exp=0x%2h)", 
          i2c_addr, expected_i2c_addr
        )
      )
    end
    
    if (i2c_rw == expected_i2c_rw) begin
      `uvm_info(
        get_type_name(),
        $sformatf(
          "got correct i2c operation (act=%0d, exp=%0d)", 
          i2c_rw, expected_i2c_rw
        ),
        UVM_NONE
      )
    end
    else begin
      `uvm_error(
        get_type_name(),
        $sformatf(
          "got correct i2c operation (act=0x%2h, exp=0x%2h)", 
          i2c_rw, expected_i2c_rw
        )
      )
    end
    
    if (~expected_i2c_rw) begin
      if (w_data_content.size() == expected_w_data_content.size()) begin
        `uvm_info(
          get_type_name(),
          $sformatf(
            "got correct number of data written (act=%0d, exp=%0d)", 
            w_data_content.size(), expected_w_data_content.size()
          ),
          UVM_NONE
        )
      end
      else begin
        `uvm_error(
          get_type_name(),
          $sformatf(
            "got incorrect number of data written (act=0x%2h, exp=0x%2h)", 
            w_data_content.size(), expected_w_data_content.size()
          )
        )
      end
    end
    else begin
      if (r_data_content.size() == expected_r_data_content.size()) begin
        `uvm_info(
          get_type_name(),
          $sformatf(
            "got correct number of data read (act=%0d, exp=%0d)", 
            r_data_content.size(), expected_r_data_content.size()
          ),
          UVM_NONE
        )
      end
      else begin
        `uvm_error(
          get_type_name(),
          $sformatf(
            "got incorrect number of data read (act=%0d, exp=%0d)", 
            r_data_content.size(), expected_r_data_content.size()
          )
        )
      end
    end
    
    if (~expected_i2c_rw) begin
      while (w_data_content.size() != 0) begin
        bit [7:0] act = w_data_content.pop_front();
        bit [7:0] exp = expected_w_data_content.pop_front();
        i = i + 1;
        if (act != exp) begin
          `uvm_error(
          get_type_name(),
          $sformatf(
            "got incorrect %0d-th written data (act=0x%2h, exp=0x%2h)", 
            i + 1, act, exp
          )
        )
        end
      end
    end
    else begin
      while (r_data_content.size() != 0) begin
        bit [7:0] act = r_data_content.pop_front();
        bit [7:0] exp = expected_r_data_content.pop_front();
        i = i + 1;
        if (act != exp) begin
          `uvm_error(
            get_type_name(),
            $sformatf(
              "got incorrect %0d-th read data (act=0x%2h, exp=0x%2h)", 
              i + 1, act, exp
            )
          )
        end
      end
    end
    
    i2c_rw = 0; expected_i2c_rw = 0;
    i2c_addr = 0; expected_i2c_addr = 0;
    w_data_content = {}; expected_w_data_content = {};
    r_data_content = {}; expected_r_data_content = {};
  endfunction
  
  function void write_mfifo(mfifo_seq_item t);
    if (t.kind == mfifo_seq_item::MFIFO_CONTROL) begin
      if (t.rst) begin
        expected_w_data_content = {};
        expected_r_data_content = {};
      end
      else if (t.en & ~t.rw) begin
        expected_w_data_content.push_back(t.data);
      end
      else if (t.en & t.rw) begin
        expected_r_data_content.push_back(t.data);
      end
    end
    else if (t.kind == mfifo_seq_item::MFIFO_COMMAND) begin
      expected_i2c_addr = t.i2c_addr;
      expected_i2c_rw = t.i2c_rw;
      expected_i2c_data_addr = t.i2c_data_addr;
      i2c_data_addr_en = t.i2c_data_addr_en;
    end
    else if (t.kind == mfifo_seq_item::MFIFO_STATUS) begin
      if (expected_i2c_rw & has_stopped & t.read_buffer_empty) begin
        has_stopped = 0;
      end
    end
  endfunction
  
  function void write_i2c(i2c_seq_item t);
    if (t.kind == i2c_seq_item::ADDR) begin
      i2c_addr = t.addr;
      i2c_rw = t.rw;
    end
    else if (t.kind == i2c_seq_item::DATA) begin
      has_stopped = 0;
      if (t.src == i2c_seq_item::SLAVE)
        r_data_content.push_back(t.data);
      else
        w_data_content.push_back(t.data);
    end
    else if (t.kind == i2c_seq_item::STOP) begin
      has_stopped = 1;
      if (~expected_i2c_rw) begin
        has_stopped = 0;
      end
    end
  endfunction
endclass

class i2c_mem_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(i2c_mem_scoreboard)
  
  // class dependencies
  uvm_analysis_imp_mem #(mem_seq_item, i2c_mem_scoreboard) mem_exp;
  uvm_analysis_imp_i2c #(i2c_seq_item, i2c_mem_scoreboard) i2c_exp;
  
  int state_check = 0, failed_state_check = 0;
  
  bit not_first_i2c_data_pkt = 0, has_seen_i2c_write = 0;
  bit i2c_rw;
  bit [7:0] written_data[bit[7:0]] = '{}, read_data[bit[7:0]] = '{};
  bit [7:0] read_data_addr[$] = '{};
  bit [7:0] i2c_mem_addr;
  bit [6:0] i2c_slave_addr, expected_i2c_slave_addr = 7'h69;
  
  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
    mem_exp = new("mem_exp", this);
    i2c_exp = new("i2c_exp", this);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info(
      get_type_name(),
      $sformatf(
        "observed %0d memory state discrepancy out of %0d checks",
        failed_state_check, state_check
      ),
      UVM_NONE
    )
  endfunction
  
  function void evaluate();
    bit [7:0] addr;
    while (read_data_addr.size() != 0) begin
      addr = read_data_addr.pop_front();
      state_check = state_check + 1;
      if (read_data[addr] != written_data[addr]) begin
         failed_state_check = failed_state_check + 1;
        `uvm_error(
          get_type_name(),
          $sformatf(
            "discrepant memory state (addr=0x%2h, re=0x%2h, wr=0x%2h)",
            addr, read_data[addr], written_data[addr]
          )
        )
      end
      else begin
        `uvm_info(
          get_type_name(),
          $sformatf(
            "expected memory state (addr=0x%2h, re=0x%2h, wr=0x%2h)",
            addr, read_data[addr], written_data[addr]
          ),
          UVM_NONE
        )
      end
    end
    
    // reset scoreboard state
    not_first_i2c_data_pkt = 0;
    written_data = '{};
    read_data = '{};
    read_data_addr = '{};
    i2c_mem_addr = 0;
    expected_i2c_slave_addr = 7'h69;
  endfunction
  
  function void write_mem(mem_seq_item t);
    case (t.kind)
      mem_seq_item::WRITE: begin
        written_data[t.addr] = t.data;
      end
      mem_seq_item::READ: begin
        read_data[t.addr] = t.data;
        read_data_addr.push_front(t.addr);
      end
      mem_seq_item::RESET: begin
        written_data = '{};
        read_data = '{};
        read_data_addr = '{};
      end
    endcase
  endfunction
  
  function void write_i2c(i2c_seq_item t);
    case (t.kind)
      i2c_seq_item::STOP: not_first_i2c_data_pkt = 0;
      i2c_seq_item::ADDR: begin
        i2c_slave_addr = t.addr;
        i2c_rw = t.rw;
      end
      i2c_seq_item::DATA: begin
        if (i2c_slave_addr != expected_i2c_slave_addr) begin
          $display("addr 0x%2h 0x%2h", i2c_slave_addr, expected_i2c_slave_addr);
          return;
        end
        
        if (not_first_i2c_data_pkt) begin
          if (i2c_rw) begin
            read_data[i2c_mem_addr] = t.data;
            read_data_addr.push_front(i2c_mem_addr);
          end
          else begin
            written_data[i2c_mem_addr] = t.data;
            if (i2c_mem_addr == 0) expected_i2c_slave_addr = t.data[6:0];
          end
          i2c_mem_addr = i2c_mem_addr + 1;
        end
        else begin
          not_first_i2c_data_pkt = 1;
          if (i2c_rw) begin
            read_data[0] = t.data;
            i2c_mem_addr = 1;
          end
          else begin
            i2c_mem_addr = t.data;
          end
        end
      end
    endcase
  endfunction
endclass

class mem_coverage extends uvm_subscriber#(mem_seq_item);
  `uvm_component_utils(mem_coverage);
  
  mem_seq_item item;
  
  covergroup write_cov;
    coverpoint item.addr == 8'h00;
    coverpoint item.addr[6];
    coverpoint item.addr[0];
    coverpoint item.data;
  endgroup
  
  covergroup read_cov;
    coverpoint item.addr == 8'h00;
    coverpoint item.addr[6];
    coverpoint item.addr[0];
    coverpoint item.data;
  endgroup
  
  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
    write_cov = new();
    read_cov = new();
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  function void write(mem_seq_item t);
    item = t;
    case(t.kind)
      mem_seq_item::READ: read_cov.sample();
      mem_seq_item::WRITE: write_cov.sample();
    endcase
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info(
      get_type_name(), 
      $sformatf("mem read coverage %.2f%%", read_cov.get_inst_coverage()), 
      UVM_NONE
    );
    `uvm_info(
      get_type_name(), 
      $sformatf("mem write coverage %.2f%%", write_cov.get_inst_coverage()), 
      UVM_NONE
    );
  endfunction
endclass

class i2c_coverage extends uvm_subscriber#(i2c_seq_item);
  `uvm_component_utils(i2c_coverage);
  
  i2c_seq_item item;
  
  covergroup addr_cov;
    coverpoint item.addr[6];
    coverpoint item.addr[0];
    coverpoint item.rw;
  endgroup
  
  covergroup data_cov;
    coverpoint item.data[7];
    coverpoint item.data[0];
  endgroup
  
  covergroup ack_cov;
    coverpoint item.kind {
      bins k[2] = {i2c_seq_item::ACK, i2c_seq_item::NACK};
    }
  endgroup
  
  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
    addr_cov = new();
    data_cov = new();
    ack_cov = new();
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  function void write(i2c_seq_item t);
    item = t;
    case (t.kind)
      i2c_seq_item::ACK: ack_cov.sample();
      i2c_seq_item::NACK: ack_cov.sample();
      i2c_seq_item::ADDR: addr_cov.sample();
      i2c_seq_item::DATA: data_cov.sample();
    endcase
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info(
      get_type_name(), 
      $sformatf("i2c addr coverage %.2f%%", addr_cov.get_inst_coverage()), 
      UVM_NONE
    );
    `uvm_info(
      get_type_name(), 
      $sformatf("i2c data coverage %.2f%%", data_cov.get_inst_coverage()), 
      UVM_NONE
    );
    `uvm_info(
      get_type_name(), 
      $sformatf("i2c ack coverage %.2f%%", ack_cov.get_inst_coverage()), 
      UVM_NONE
    );
  endfunction
endclass

class mfifo_coverage extends uvm_subscriber#(mfifo_seq_item);
  `uvm_component_utils(mfifo_coverage);
  
  mfifo_seq_item item;
  
  covergroup control_cov;
    coverpoint item.rst;
    coverpoint item.rw;
    coverpoint item.en;
  endgroup
  
  covergroup command_cov;
    coverpoint item.i2c_rw;
    coverpoint item.i2c_data_addr_en;
    coverpoint item.i2c_data_addr[7];
    coverpoint item.i2c_data_addr[0];
    coverpoint item.i2c_data_len;
  endgroup
  
  covergroup status_cov;
    coverpoint item.read_buffer_empty;
    coverpoint item.data;
  endgroup
  
  function new(string name = "", uvm_component parent = null);
    super.new(name, parent);
    control_cov = new();
    command_cov = new();
    status_cov = new();
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction
    
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction
  
  function void write(mfifo_seq_item t);
    item = t;
    case (t.kind)
      mfifo_seq_item::MFIFO_CONTROL: control_cov.sample();
      mfifo_seq_item::MFIFO_COMMAND: command_cov.sample();
      mfifo_seq_item::MFIFO_STATUS: status_cov.sample();
    endcase
  endfunction
  
  function void report_phase(uvm_phase phase);
    `uvm_info(
      get_type_name(), 
      $sformatf("mfifo control coverage %.2f%%", control_cov.get_inst_coverage()), 
      UVM_NONE
    );
    `uvm_info(
      get_type_name(), 
      $sformatf("mfifo command coverage %.2f%%", command_cov.get_inst_coverage()), 
      UVM_NONE
    );
    `uvm_info(
      get_type_name(), 
      $sformatf("mfifo status coverage %.2f%%", status_cov.get_inst_coverage()), 
      UVM_NONE
    );
  endfunction
endclass