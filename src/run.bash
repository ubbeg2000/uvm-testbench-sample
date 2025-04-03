# change these values to select which testbench to use and test to run
export TESTBENCH=testbench_integration.sv
export TESTNAME=integrated_rw_test

vlib work
vlog \
  +incdir+$RIVIERA_HOME/vlib/uvm-1.2/src \
  -l uvm_1_2 \
  -err VCP2947 W9 \
  -err VCP2974 W9 \
  -err VCP3003 W9 \
  -err VCP5417 W9 \
  -err VCP6120 W9 \
  -err VCP7862 W9 \
  -err VCP2129 W9 \
  -timescale 1ns/1ns \
  -pli /home/runner/tb.so \
  $TESTBENCH
  
vsim \
  +access+r +TESTNAME=$TESTNAME \
  +w_nets -interceptcoutput \
  -c -pli /home/runner/tb.so -do "run -all; exit"