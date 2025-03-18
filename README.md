# UVM Testbench Sample: I2C Master and Slave Verification

This project showcases my expertise in digital systems design and design verification through the development of two IP cores: an I2C master with a FIFO interface and a memory unit featuring an I2C slave interface. Both IPs are rigorously verified using the Universal Verification Methodology (UVM), ensuring a robust and scalable verification environment.

A key highlight of this project is the testbench architecture, which leverages UVM to its fullest extent. It employs key UVM components such as sequences, agents, scoreboards, and functional coverage, promoting modularity and reusability. The testbench is designed to be adaptable, enabling seamless integration with future projects and facilitating efficient verification of similar protocols. This structured approach demonstrates best practices in UVM-based verification while reinforcing the importance of reusable and scalable verification methodologies.

## About the IPs

### I2C Master

The I2C Master IP is essentially a couple of FIFO buffers (write and read FIFO) that are attached to an I2C master interface. Data that will be written via I2C comes from a write FIFO while data that are read from the I2C interface will be stored into the read FIFO. This IP is intended to be used in conjuction with vendor specific IO buffers. The block diagram of the IP is shown in the figure below. features of the IP are:
1. 7-bit I2C slave addressing
2. Burst I2C write, will send I2C packets until write FIFO is empty
3. Burst I2C read, number of data to be read is configurable via the command value
4. Burst I2C read with address, number of data to be read and the starting address is configurable via the command value

![i2c master block diagram](https://github.com/ubbeg2000/uvm-testbench-sample/blob/main/images/i2c_master_block.png?raw=true)

| Port Name  | Direction | Dimension | Description                                   |
|------------|-----------|-----------|-----------------------------------------------|
| `command`  | `input`   | 32-bit    | Command to send or receive via the I2C intf.  |
| `status`   | `output`  | 32-bit    | Status of the I2C transaction and the IP      |
| `r_data`   | `output`  | 7-bit     | Read output from read FIFO                    |
| `w_data`   | `input`   | 7-bit     | Write input for write FIFO                    |
| `r_en`     | `input`   | 1-bit     | Enables reading from read FIFO                |
| `w_en`     | `input`   | 1-bit     | Enables writing to write FIFO                 |
| `clk`      | `input`   | 1-bit     | IP clock signal, **must be 2x I2C frequency** |
| `rstn`     | `input`   | 1-bit     | Synchronous reset                             |
| `sda_i`    | `input`   | 1-bit     | Receiving port for incoming SDA signal        |
| `sda_o`    | `output`  | 1-bit     | Driving port for outgoing SDA signal          |
| `scl_o`    | `output`  | 1-bit     | Driving port for SCL                          |
| `sda_o_en` | `output`  | 1-bit     | Enables driving to output buffer circuit      |


## I2C Slave

The I2C Slave IP is a 256-bytes memory element that is attached to an I2C slave interface, in other words, it is a memory element that can be interfaced by a traditional memory interface and by the I2C interface. Features of the IP are:
1. Single/burst write with memory address (required)
2. Single/burst read without memory address, reading will start from address 0x00 
3. Single/burst read with memory address, reading will start from the specified memory address
4. Configurable slave address with parameterized default slave address value, done by writing to memory address 0x00

![i2c slave block diagram](https://github.com/ubbeg2000/uvm-testbench-sample/blob/main/images/i2c_slave_block.png)

| Port Name  | Direction | Dimension | Description                                   |
|------------|-----------|-----------|-----------------------------------------------|
| `addr`     | `output`  | 7-bit     | Read output from read FIFO                    |
| `data_o`   | `input`   | 7-bit     | Write input for write FIFO                    |
| `data_i`   | `input`   | 1-bit     | Enables reading from read FIFO                |
| `rw_en`    | `input`   | 32-bit    | Command to send or receive via the I2C intf.  |
| `rw`       | `output`  | 32-bit    | Status of the I2C transaction and the IP      |
| `status`   | `input`   | 1-bit     | Enables writing to write FIFO                 |
| `clk`      | `output`  | 1-bit     | Driving port for outgoing SDA signal          |
| `rstn`     | `output`  | 1-bit     | Driving port for SCL                          |
| `sda_o`    | `input`   | 1-bit     | IP clock signal, **must be 2x I2C frequency** |
| `sda_i`    | `input`   | 1-bit     | Synchronous reset                             |
| `scl_i`    | `input`   | 1-bit     | Receiving port for incoming SDA signal        |
| `sda_o_en` | `output`  | 1-bit     | Enables driving to output buffer circuit      |

## Testbench Architecture

Verification of the aforementioned IPs are done using UVM to have reusability and better scalability of writing tests. There are three testbenches in total: one for the master, one for the slave, and one for integration test between the master and the slave. All three of those testbenches follow the dual top architecture described in Siemen's UVM Cookbook.

### Universial Verification Components

## Verification Runs

### I2C Master Block Test

### I2C Slave Block Test

### Integration Test

## Prototype on FPGA

### LCD Monitor Driver

### I2C Slave Communications with Microcontroller

## Appendix

### Source Code Structure

### Demo Page

## Links and References
- Demo on EDA Playground: [https://edaplayground.com/x/QBm9](https://edaplayground.com/x/QBm9)
- UVM Cookbook : [https://verificationacademy.com/cookbook/uvm-universal-verification-methodology/](https://verificationacademy.com/cookbook/uvm-universal-verification-methodology/)
- I2C Specification: [https://www.nxp.com/docs/en/user-guide/UM10204.pdf](https://www.nxp.com/docs/en/user-guide/UM10204.pdf)