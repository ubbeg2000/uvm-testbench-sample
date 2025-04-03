`include "uvm_macros.svh"
import uvm_pkg::*;

`include "i2c_master_v2.sv"

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
  
  logic clk = 0;
  string test_name = "master_combined_test";
  
  i2c_interface i2c_intf (.clk(clk));
  mfifo_interface mfifo_intf(.clk(clk));
  
  i2c_master_v2 #(
    .W_DATA_DEPTH(W_DATA_DEPTH),
    .R_DATA_DEPTH(R_DATA_DEPTH)
  ) 
  uut (
    // clock
    .clk(clk),
    
    // reset signal
    .rst(mfifo_intf.rst),
    
    // i2c control signal
    .i2c_send(mfifo_intf.i2c_send),
    .command(mfifo_intf.command),
    
    // read/write buffer signals
    .w_en(mfifo_intf.w_en),
    .r_en(mfifo_intf.r_en),
    .w_data(mfifo_intf.w_data),
    .r_data(mfifo_intf.r_data),

    // status flags
    .status(mfifo_intf.status),

    // i2c interface
    .sda_i(i2c_intf.sda_i),
    .sda_o(i2c_intf.sda_o),
    .scl_o(i2c_intf.scl_o),
    .sda_o_en(i2c_intf.sda_o_en)
  );
  
  initial begin
    uvm_config_db #(virtual i2c_interface)::set(
      null, "*", "i2c_interface", i2c_intf
    );
    uvm_config_db #(virtual mfifo_interface)::set(
      null, "*", "mfifo_interface", mfifo_intf
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