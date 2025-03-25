# UVM Testbench Sample: I2C Master and Slave Verification

This project showcases my expertise in digital systems design and design verification through the development of two IP cores: an I2C master with a FIFO interface and a memory unit featuring an I2C slave interface. Both IPs are rigorously verified using the Universal Verification Methodology (UVM), ensuring a robust and scalable verification environment.

A key highlight of this project is the testbench architecture, which leverages UVM to its fullest extent. It employs key UVM components such as sequences, agents, scoreboards, and functional coverage, promoting modularity and reusability. The testbench is designed to be adaptable, enabling seamless integration with future projects and facilitating efficient verification of similar protocols. This structured approach demonstrates best practices in UVM-based verification while reinforcing the importance of reusable and scalable verification methodologies.

## About the IPs

### I2C Master

The I2C Master IP is essentially a couple of FIFO buffers (write and read FIFO) that are attached to an I2C master interface. Data that will be written via I2C comes from a write FIFO while data that are read from the I2C interface will be stored into the read FIFO. This IP is intended to be used in conjuction with vendor specific IO buffers. The block diagram of the IP is shown in the figure below. features of the IP are:
1. Compliance with standard mode I2C specification
2. Implements 7-bit I2C slave addressing
3. Up to 256 bytes capacity for the read and write FIFO
4. Burst I2C write, will send I2C packets until write FIFO is empty
5. Burst I2C read, number of data to be read is configurable via the command value
6. Burst I2C read with address, number of data to be read and the starting address is configurable via the command value

<img src="https://github.com/ubbeg2000/uvm-testbench-sample/blob/chore/project-outline/images/i2c_master_block.png?raw=true" alt="i2c master block diagram" width="400"/>

| Port Name  | Direction | Dimension | Description                                   |
|------------|-----------|-----------|-----------------------------------------------|
| `command`  | `input`   | 32-bit    | Command to send or receive via the I2C intf.  |
| `status`   | `output`  | 32-bit    | Status of the I2C transaction and the IP      |
| `i2c_send` | `input`   | 1-bit     | Set to high on rising edge to execute command |
| `r_data`   | `output`  | 7-bit     | Read output from read FIFO                    |
| `w_data`   | `input`   | 7-bit     | Write input for write FIFO                    |
| `r_en`     | `input`   | 1-bit     | Enables reading from read FIFO                |
| `w_en`     | `input`   | 1-bit     | Enables writing to write FIFO                 |
| `clk`      | `input`   | 1-bit     | IP clock signal, **must be 2x I2C frequency** |
| `rstn`     | `input`   | 1-bit     | Active low synchronous reset                  |
| `sda_i`    | `input`   | 1-bit     | Receiving port for incoming SDA signal        |
| `sda_o`    | `output`  | 1-bit     | Driving port for outgoing SDA signal          |
| `scl_o`    | `output`  | 1-bit     | Driving port for SCL                          |
| `sda_o_en` | `output`  | 1-bit     | Enables driving to output buffer circuit      |

The format for the `command` and `status` signal is as shown below

```
Command

MSB                                                                     LSB
<------------------------------ 32 bits ---------------------------------->
| slave addr. | data addr. | data addr. en | i2c read/write | data length |
<-- 7 bits --> <- 8 bits -> <--- 1 bit ---> <--- 1 bit ----> <- 15 bits -->
```

| Field            | Description                                             |
|------------------|---------------------------------------------------------|
| `slave addr.`    | I2C slave address to communicate with                   |
| `data addr.`     | Data address for single/burst read with data address    |
| `data addr. en`  | Set high to do single/burst read with data address      |
| `i2c read/write` | Set to logic high for reading and logic low for writing |
| `data length `   | Length of data to read                                  |

The command signal will be sampled on a clock rising edge if the `i2c_send` signal is high. It will then be stored on an internal register until IP has finished executing the command.

```
Status

MSB                                                                      LSB
<------------------------------ 32 bits ----------------------------------->
| busy | failure | r fifo  | r fifo  | w.fifo  | w fifo  | r fifo | w fifo |
|      | code    | full    | empty   | full    | empty   | count  | count  |
<- 1 -> <- 11 --> <-- 1 --> <-- 1 --> <-- 1 --> <-- 1 --> <-- 8 -> <-- 8 -->
```

| Field          | Description                                            |
|----------------|--------------------------------------------------------|
| `busy`         | Shall be high during the duration of command execution |
| `failure code` | 11-bit code, valid until next command execution        |
| `r fifo full`  | Shall be high if read FIFO is full                     |
| `r fifo empty` | Shall be high if read FIFO is empty                    |
| `w fifo full`  | Shall be high if write FIFO is full                    |
| `w fifo empty` | Shall be high if write FIFO is empty                   |
| `r fifo count` | Number of data stored in read FIFO                     |
| `w fifo count` | Number of data stored in write FIFO                    |

The `status` signal will be updated on every rising edge of the clock. Error codes that are currently defined are:
1. **0x001**: No slave acknowledgement after addressing
2. **0x002**: Missing slave acknowledgement after writing read address
3. **0x003**: Missing slave acknowledgement after writing data

## I2C Slave

The I2C Slave IP is a 256-bytes memory element that is attached to an I2C slave interface, in other words, it is a memory element that can be interfaced by a traditional memory interface and by the I2C interface. Features of the IP are:
1. Compliance with I2C standard mode specification
2. Single/burst write with memory address (required)
3. Single/burst read without memory address, reading will start from address 0x00 
4. Single/burst read with memory address, reading will start from the specified memory address
5. Configurable slave address with parameterized default slave address value, done by writing to memory address 0x00

<img src="https://github.com/ubbeg2000/uvm-testbench-sample/blob/chore/project-outline/images/i2c_slave_block.png?raw=true" alt="i2c master block diagram" width="400"/>

| Port Name  | Direction | Dimension | Description                                    |
|------------|-----------|-----------|------------------------------------------------|
| `addr`     | `input`   | 8-bit     | Memory address to read from or write to        |
| `data_o`   | `output`  | 8-bit     | Result of memory read                          |
| `data_i`   | `input`   | 8-bit     | Data to write to memory                        |
| `rw_en`    | `input`   | 1-bit     | Enable signal for memory interface             |
| `rw`       | `input`   | 1-bit     | Logic high for reading, low for writing        |
| `busy`     | `output`  | 1-bit     | Will be high if during I2C operation           |
| `clk`      | `input`   | 1-bit     | Driving port for outgoing SDA signal           |
| `rstn`     | `input`   | 1-bit     | Driving port for SCL                           |
| `clk`      | `input`   | 1-bit     | IP clock signal, **at least 4x I2C frequency** |
| `rstn`     | `input`   | 1-bit     | Active low synchronous reset                   |
| `scl_i`    | `input`   | 1-bit     | Receiving port for incoming SDA signal         |
| `sda_o_en` | `output`  | 1-bit     | Enables driving to output buffer circuit       |

## About the Testbenches

### Architecture

Verification of the aforementioned IPs are done using UVM to have reusability and better scalability of writing tests. There are three testbenches in total: one for the master, one for the slave, and one for integration test between the master and the slave. All three of those testbenches follow the dual top architecture described in Siemen's UVM Cookbook. An illustration of the testbench architecture is as shown below.

<img src="https://github.com/ubbeg2000/uvm-testbench-sample/blob/chore/project-outline/images/dual_top_tb_arch.png?raw=true" alt="i2c master block diagram" width="600"/>

### Universial Verification Components

One of the point of UVM is reusability, this can be observed from the use of Universal Verification Components (UVC) which abstracts away low-level stimulus driving and signal analysis to a higher level of transaction. This project includes three UVC which consists of a UVM agent, an interface, and a sequence item to model transactions in the interface. Each UVC corresponds to one interface used in the project. There is the `mfifo_agent` for the master's FIFO interface, `mem_agent` for the slave's memory interface, and `i2c_agent` for the I2C interface.

All of the aforementioned UVCs are configurable to be either an active or passive agent and configurable to log observed sequence item. The `i2c_agent` is a bit different in that it has two modes, a master driver mode and a slave responder mode. The master driver mode is used to generate I2C master signal stimulus while the slave responder mode is used to responed to I2C master signals.

### Register Abstraction Layer

One Register Abstraction Layers (RALs) is included for the I2C master IP. It is added in to the testbench environment to streamline register read/write operations to the IP. In this sample project, only the command register is mapped to the RAL to ease testcases setup.

### Evaluation, Functional Coverage, and Metric Analysis

The DUT's compliance to specification is measured in three categories: functional correctness, functional coverage, and metric fit. Those three aspects are measured by evaluation with the scoreboard, functional coverage via collectors, and metric analysis. In this sample project, scoreboards are made to be test environment specific while coverage collectors are made for each kind of sequence item that are used by the UVCs. Metric analyzers are not implemented in this testbench.

### Test Content

Test content in this context means the sequences that generates stimulus for the Design Under Test (DUT). They are made in a way that covers all of the features mentioned in the IP's description as well as compliance to the interfaces specification. Test content that are included in this project are as listed below.
1. `master_write_test`
2. `master_read_test`
3. `master_read_addr_test`
4. `master_combined_test`
5. `slave_write_test`
6. `slave_read_test`
7. `slave_read_addr_test`
8. `slave_addr_test`
9. `slave_combined_test`
10. `integration_rw_test`

Details on each testcase will be made available on TESTCONTENT.md.

## Prototype on FPGA

Higher level of confidence in the design can be achieved by prototyping the design on an FPGA and validating the design by using it as it is meant to be.

### Driving an OLED Monitor

WIP

### I2C Slave Communications with Microcontroller

WIP

## Appendix

### Source Code Structure

The source code can be categorized into two: HDL and testbench source code. The structure is as the tree below.
```
project/
│
├── hdl/
│   ├── fifo.sv                    # Synchronous FIFO used in I2C master
│   ├── i2c_master_v2.sv           # RTL for the I2C Master IP
│   └── i2c_mem.sv                 # RTL for the I2C Slave IP
│
└── testbench/
    ├── testbench.sv               # Top of the top
    ├── testbench_master.sv        # Top level component for I2C Master block test
    ├── testbench_slave.sv         # Top level component for I2C Slave block test
    ├── testbench_integration.sv   # Top level component for integration test
    │
    ├── tests.sv                   # Test contents for all tests
    ├── envs.sv                    # Test environments for all tests
    ├── analysis_components.sv     # Analysis components for all tests
    │
    ├── mfifo_uvc.sv               # All components of the MFIFO UVC
    ├── mem_uvc.sv                 # All components of the MEM UVC
    ├── i2c_uvc.sv                 # All components of the I2C UVC
    │
    ├── i2c_master_ral.sv          # RAL for the I2C Master
    │
    ├── vseqs.sv                   # For sequences involcing multiple UVCs
    ├── sequences.sv               # Contains sequences for all UVCs
    └── sequence_items.sv          # Model of transactions for all UVCs
```

### Trying it Yourself

You can find the project on EDA Playground whose link is included in the Appendix section. The `testbench.sv` file is the entrypoint for all simulations, which simulation to run is determined by which testbench file is imported in the `testbench.sv` file. Contents of the file looks something like this.

```SystemVerilog
// `include "testbench_master.sv"
// `include "testbench_slave.sv"
`include "testbench_integration.sv"
```

If say you want to run tests for the I2C Master IP, simply comment all the other includes and uncomment the `testbench_master.sv` include. The simulation can be ran with the Aldec Riviera Pro 2024.04 simulator with UVM 1.2 included in the project.

### Links and References
- Demo on EDA Playground: [https://edaplayground.com/x/QBm9](https://edaplayground.com/x/QBm9)
- UVM Cookbook : [https://verificationacademy.com/cookbook/uvm-universal-verification-methodology/](https://verificationacademy.com/cookbook/uvm-universal-verification-methodology/)
- I2C Specification: [https://www.nxp.com/docs/en/user-guide/UM10204.pdf](https://www.nxp.com/docs/en/user-guide/UM10204.pdf)