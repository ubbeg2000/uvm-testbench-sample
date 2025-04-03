# Test Content

- [Test Content](#test-content)
  - [I2C Master Testcases](#i2c-master-testcases)
    - [`master_write_test`](#master_write_test)
    - [`master_read_test`](#master_read_test)
    - [`master_read_addr_test`](#master_read_addr_test)
    - [`master_combined_test`](#master_combined_test)
  - [I2C Slave Testcases](#i2c-slave-testcases)
    - [`slave_write_test`](#slave_write_test)
    - [`slave_read_test`](#slave_read_test)
    - [`slave_read_addr_test`](#slave_read_addr_test)
    - [`slave_addr_test`](#slave_addr_test)
    - [`slave_combined_test`](#slave_combined_test)
  - [Integration Test Testcases](#integration-test-testcases)
    - [`integration_rw_test`](#integration_rw_test)
  - [Verdict](#verdict)


## I2C Master Testcases

### `master_write_test`

The `master_write_test` is done to test the I2C master's capability of executing I2C write transactions to the slave. It is done by loading the write FIFO with n bytes of data (n is randomized) and sending a write command to the I2C master. The test result is as shown below.


| Metric              |  Value  | Pass/Not Pass |
|---------------------|---------|:-------------:|
| Iterations          | 30      | ✅            |
| Failure count       | 0       | ✅            |
| Control signal cov. | 83.33%  | ✅            |
| Command signal cov. | 40.31%  | ✅            |
| Status signal cov.  | 74.22%  | N/A           |

### `master_read_test`

| Metric              |  Value | Pass/Not Pass |
|---------------------|--------|:-------------:|
| Iterations          | 30     | ✅            |
| Failure count       | 0      | ✅            |
| Control signal cov. | 100%   | ✅            |
| Command signal cov. | 40.31% | ✅            |
| Status signal cov.  | 83.59% | N/A           |

### `master_read_addr_test`

| Metric              |  Value | Pass/Not Pass |
|---------------------|--------|:-------------:|
| Iterations          | 30     | ✅            |
| Failure count       | 0      | ✅            |
| Control signal cov. | 100%   | ✅            |
| Command signal cov. | 60.94% | ✅            |
| Status signal cov.  | 91.41% | N/A           |

### `master_combined_test`

| Metric              |  Value | Pass/Not Pass |
|---------------------|--------|:-------------:|
| Iterations          | 30     | ✅            |
| Failure count       | 0      | ✅            |
| Control signal cov. | 100%   | ✅            |
| Command signal cov. | 80.94% | ✅            |
| Status signal cov.  | 89.86% | N/A           |

## I2C Slave Testcases

### `slave_write_test`

| Metric              |  Value | Pass/Not Pass |
|---------------------|--------|:-------------:|
| Iterations          | 30     | ✅            |
| Memory discrepancy  | 0      | ✅            |
| Memory read cov.    | 84.77% | ✅            |
| Memory write cov.   | 0%     | ✅            |
| I2C address cov.    | 50%    | ✅            |
| I2C data cov.       | 100%   | ✅            |
| I2C ack cov.        | 50%    | ✅            |

### `slave_read_test`

| Metric              |  Value | Pass/Not Pass |
|---------------------|--------|:-------------:|
| Iterations          | 30     | ✅            |
| Memory discrepancy  | 0      | ✅            |
| Memory read cov.    | 0%     | ✅            |
| Memory write cov.   | 73.05% | ✅            |
| I2C address cov.    | 50%    | ✅            |
| I2C data cov.       | 100%   | ✅            |
| I2C ack cov.        | 50%    | ✅            |

### `slave_read_addr_test`

| Metric              |  Value | Pass/Not Pass |
|---------------------|--------|:-------------:|
| Iterations          | 30     | ✅            |
| Memory discrepancy  | 0      | ✅            |
| Memory read cov.    | 0%     | ✅            |
| Memory write cov.   | 85.55% | ✅            |
| I2C address cov.    | 66.67% | ✅            |
| I2C data cov.       | 100%   | ✅            |
| I2C ack cov.        | 50%    | ✅            |

### `slave_addr_test`

| Metric              |  Value | Pass/Not Pass |
|---------------------|--------|:-------------:|
| Iterations          | 30     | ✅            |
| Memory discrepancy  | 0      | ✅            |
| Memory read cov.    | 0%     | ✅            |
| Memory write cov.   | 0%     | ✅            |
| I2C address cov.    | 100%   | ✅            |
| I2C data cov.       | 100%   | ✅            |
| I2C ack cov.        | 50%    | ✅            |

### `slave_combined_test`

| Metric              |  Value | Pass/Not Pass |
|---------------------|--------|:-------------:|
| Iterations          | 30     | ✅            |
| Memory discrepancy  | 0      | ✅            |
| Memory read cov.    | 75.00% | ✅            |
| Memory write cov.   | 80.08% | ✅            |
| I2C address cov.    | 100%   | ✅            |
| I2C data cov.       | 100%   | ✅            |
| I2C ack cov.        | 50%    | ✅            |

## Integration Test Testcases

### `integration_rw_test`

| Metric              |  Value | Pass/Not Pass |
|---------------------|--------|:-------------:|
| Iterations          | 30     | ✅            |
| Memory discrepancy  | 0      | ✅            |
| Failure count       | 0      | ✅            |
| Control signal cov. | 100%   | ✅            |
| Command signal cov. | 70.62% | ✅            |
| Status signal cov.  | 92.97% | N/A           |
| Memory read cov.    | 80.47% | ✅            |
| Memory write cov.   | 0%     | ✅            |
| I2C address cov.    | 66.67% | ✅            |
| I2C data cov.       | 100%   | ✅            |
| I2C ack cov.        | 100%   | ✅            |

## Verdict

Based on all of the test results above, it can be concluded that **all of the IPs developed in this project has passed all positive testcases**.