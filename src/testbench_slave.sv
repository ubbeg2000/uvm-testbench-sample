`include "uvm_macros.svh"
import uvm_pkg::*;

`include "i2c_mem.sv"

`include "seq_items.sv"
`include "i2c_master_ral.sv"
`include "i2c_uvc.sv"
`include "mfifo_uvc.sv"
`include "mem_uvc.sv"
`include "sequences.sv"
`include "analysis_components.sv"
`include "envs.sv"
`include "vseq.sv"
`include "tests.sv"

module top_tb();
  localparam R_DATA_DEPTH = 8;
  localparam W_DATA_DEPTH = 8;
  
  string test_name = "slave_combined_test";
  logic clk = 0;
  
  i2c_interface i2c_intf (.clk(clk));
  mem_interface mem_intf(.clk(clk));
  
  i2c_mem uut(
    .clk(clk),
    .rst(mem_intf.rst),
    .busy(mem_intf.busy),

    .rw(mem_intf.rw), // 1 means read
    .rw_en(mem_intf.en),
    .addr(mem_intf.addr),
    .data_i(mem_intf.data_i),
    .data_o(mem_intf.data_o),

    .sda_i(i2c_intf.sda_o),
    .scl_i(i2c_intf.scl_o),
    .sda_o(i2c_intf.sda_i)
  );
  
  initial begin
    uvm_config_db #(virtual i2c_interface)::set(
      null, "*", "i2c_interface", i2c_intf
    );
    uvm_config_db #(virtual mem_interface)::set(
      null, "*", "mem_interface", mem_intf
    );
  end
  
  // clock generation
  initial forever #5 clk = ~clk;
  initial #100000 $finish;
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
  initial begin
    $value$plusargs ("+TESTNAME=%s", test_name);
    run_test(test_name);
  end
endmodule