# Testbench Architecture

## Overview

Verification of the aforementioned IPs are done using UVM to have reusability and better scalability of writing tests. There are three testbenches in total: one for the master, one for the slave, and one for integration test between the master and the slave. All three of those testbenches follow the dual top architecture described in Siemen's UVM Cookbook. An illustration of the testbench architecture is as shown below.

<img src="https://github.com/ubbeg2000/uvm-testbench-sample/blob/chore/project-outline/images/dual_top_tb_arch.png?raw=true" alt="i2c master block diagram" width="600"/>

Composition of the three testbenches are as shown below

<img src="https://github.com/ubbeg2000/uvm-testbench-sample/blob/chore/project-outline/images/master_tb_arch.png?raw=true" alt="master_tb_arch" width="600"/>

<img src="https://github.com/ubbeg2000/uvm-testbench-sample/blob/chore/project-outline/images/slave_tb_arch.png?raw=true" alt="slave_tb_arch" width="600"/>

<img src="https://github.com/ubbeg2000/uvm-testbench-sample/blob/chore/project-outline/images/integration_tb_arch.png?raw=true" alt="integration_tb_arch" width="800"/>

The DUT's compliance to specification is measured in three categories: functional correctness, functional coverage, and metric fit. Those three aspects are measured by evaluation with the scoreboard, functional coverage via collectors, and metric analysis. In this sample project, scoreboards are made to be test environment specific while coverage collectors are made for each kind of sequence item that are used by the UVCs. Metric analyzers are not implemented in this testbench.

## Universial Verification Components

<img src="https://github.com/ubbeg2000/uvm-testbench-sample/blob/chore/project-outline/images/uvc_package.png?raw=true" alt="uvc_package" width="600"/>

One of the point of UVM is reusability, this can be observed from the use of Universal Verification Components (UVC) which abstracts away low-level stimulus driving and signal analysis to a higher level of transaction. This project includes three UVC which consists of a UVM agent, an interface, and a sequence item to model transactions in the interface. Each UVC corresponds to one interface used in the project. There is the `mfifo_agent` for the master's FIFO interface, `mem_agent` for the slave's memory interface, and `i2c_agent` for the I2C interface.

All of the aforementioned UVCs are configurable to be either an active or passive agent and configurable to log observed sequence item. The `i2c_agent` is a bit different in that it has two modes, a master driver mode and a slave responder mode. The master driver mode is used to generate I2C master signal stimulus while the slave responder mode is used to responed to I2C master signals.

### Register Abstraction Layer

One Register Abstraction Layers (RALs) is included for the I2C master IP. It is added in to the testbench environment to streamline register read/write operations to the IP. In this sample project, only the command register is mapped to the RAL to ease testcases setup.

## Evaluation

### I2C Master Evaluation

Functional correctness of the I2C master is evaluated based on the correctness of:
1. I2C data packtes sent out of the IP
2. The data inside the read FIFO after a read operation
3. The sequence of I2C control packets sent out of the IP (start, address, repeated, and stop packets)

### I2C Slave Evaluation

Functional correctness of the I2C slave memory is evaludated by comparing the actual state of the memory to the expected state of the memory. The expected state of memory is deducted based on the incoming memory and or I2C transactions that occurs prior the the evaluation call of the test.

## Functional Coverage

### MFIFO Coverage

Points of interest for MFIFO coverage is as shown below:
1. Coverage of all control signals (reset, enable, FIFO read/write)
2. Coverage of all valid commands (burst write, burst read, burst read with address, variations of addresses and data lengths)
3. Coverage of status signals (fail code, full/empty read/write FIFO, busy flag)

### MEM Coverage

Points of interest for MEM coverage is as shown below:
1. Coverage of memory read/write commands via the MEM Interface
2. Coverage of the busy flag

### I2C Coverage

Points of interest for I2C coverage is as shown below:
1. Coverage of all types of I2C packets (start conditiion, repeated start condition, stop condition, address/mode packet, data packet, acknowledgement/not-acknowledgement)
2. Variations of slave addresses and data addresses