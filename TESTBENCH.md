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

The general flow of how the scoreboard evaluate functional correctness is as shown on the flow below.

<img src="https://github.com/ubbeg2000/uvm-testbench-sample/blob/chore/project-outline/images/evaluation_flow.png?raw=true" alt="eval_flow" width="600"/>

As described by the flowchart, the scoreboard will make predictions and do evaluations purely based on captured sequence items. Evaluation is done on by comparing the actual observed output to the predicted output which is inferred from the input sequences that the scoreboard receives from its monitors. With that design, the prediction model will be IP specific, hence why there is a seperate scoreboard for the I2C master and the I2C slave.

## Functional Coverage

Functional coverage are calculated by sampling incoming sequence items every time the monitor sends it and is reported after the a test has ended. This metric is used to determine wether or not more cycles and or randomizations are needed. The following sections specifies points of interests for every coverage collectors in this project's testbenches.

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