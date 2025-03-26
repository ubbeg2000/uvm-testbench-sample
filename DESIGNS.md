# IP Blocks Overview

## I2C Master: MFIFO-I2C

The I2C Master IP is essentially a couple of FIFO buffers (write and read FIFO) that are attached to an I2C master interface. Data that will be written via I2C comes from a write FIFO while data that are read from the I2C interface will be stored into the read FIFO. This IP is intended to be used in conjuction with vendor specific IO buffers. features of the IP are:
1. Compliance with standard mode I2C specification
2. Implements 7-bit I2C slave addressing
3. Up to 256 bytes capacity for the read and write FIFO
4. Burst I2C write, will send I2C packets until write FIFO is empty
5. Burst I2C read, number of data to be read is configurable via the command value
6. Burst I2C read with address, number of data to be read and the starting address is configurable via the command value

The only requirement to use this IP is to have the clock signal be 2x the I2C's SCL frequency (minimum 200kHz for standard mode I2C).

### Architecture

The block diagram of the IP is shown in the figure below.

<img src="https://github.com/ubbeg2000/uvm-testbench-sample/blob/chore/project-outline/images/i2c_master_block.png?raw=true" alt="i2c master block diagram" width="400"/>

The table below details the ports of the IP.

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

### Usage

Executing an I2C write shall be done in the following manner:
1. Load the write FIFO by pulling `w_en` high and set the value of `w_data` with the series of data to be sent via I2C in order
2. Send the appropriate `command` signal and pull `i2c_send` to high on a single clock cycle
3. Wait until the `status` signal's busy field is back to low
4. Optional, inspect the `fail_code` field on the `status` signal to detect any failure that happened during the I2C write transaction

Executing an I2C read and read with address shall be done in the following manner:
1. Send the appropriate `command` signal and pull `i2c_send` to high on a single clock cycle
3. Wait until the `status` signal's busy field is back to low
5. Pull `r_en` to high, the data that was read should be unloaded on every clock cycle until the read FIFO is empty
4. Optional, inspect the `fail_code` field on the `status` signal to detect any failure that happened during the I2C write transaction

## I2C Memory (I2C Slave)

The I2C Slave IP is a 256-bytes memory element that is attached to an I2C slave interface, in other words, it is a memory element that can be interfaced by a traditional memory interface and by the I2C interface. Features of the IP are:
1. Compliance with I2C standard mode specification
2. Single/burst write with memory address (required)
3. Single/burst read without memory address, reading will start from address 0x00 
4. Single/burst read with memory address, reading will start from the specified memory address
5. Configurable slave address with parameterized default slave address value, done by writing to memory address 0x00
6. Parameterized default I2C slave address, will current slave address on every reset

The only requirement to use this IP is to have the clock signal be 4x the I2C's SCL frequency (minimum 400kHz for standard mode I2C).

### Architecture

The block diagram of the IP is shown in the figure below.

<img src="https://github.com/ubbeg2000/uvm-testbench-sample/blob/chore/project-outline/images/i2c_slave_block.png?raw=true" alt="i2c master block diagram" width="400"/>

The table below details the ports of the IP.

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

### Usage

This IP is used just like any other memory element when the `busy` signal is low. Writing/reading data from/to the memory when the IP is busy is possible but may cause inconsistency. This is due to the fact that the IP's I2C interface is **always active**. Also note that writing to address 0x00 of the memory, be it from the memory interface or the I2C interface, will change the I2C slave address instantly.