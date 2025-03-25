# Testbench

## Evaluation

### I2C Master Evaluation

Functional correctness of the I2C master is evaluated based on the correctness of:
1. I2C data packtes sent out of the IP
2. The data inside the read FIFO after a read operation
3. The sequence of I2C control packets sent out of the IP (start, address, repeated, and stop packets)

### I2C Slave Evaluation

Functional correctness of the I2C slave memory is evaludated by comparing the actual state of the memory to the expected state of the memory. The expected state of memory is deducted based on the incoming memory and or I2C transactions that occurs prior the the evaluation call of the test.

## Functional Coverage

### MFIFO Interface Coverage

Points of interest for MFIFO coverage is as shown below:
1. Coverage of all control signals (reset, enable, FIFO read/write)
2. Coverage of all valid commands (burst write, burst read, burst read with address, variations of addresses and data lengths)
3. Coverage of status signals (fail code, full/empty read/write FIFO, busy flag)

### MEM Interface Coverage

Points of interest for MEM coverage is as shown below:
1. Coverage of memory read/write commands via the MEM Interface
2. Coverage of the busy flag

### I2C Interface Coverage

Points of interest for I2C coverage is as shown below:
1. Coverage of all types of I2C packets (start conditiion, repeated start condition, stop condition, address/mode packet, data packet, acknowledgement/not-acknowledgement)
2. Variations of slave addresses and data addresses