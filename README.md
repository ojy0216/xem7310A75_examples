# XEM7310A75 FPGA Examples

This repository contains a collection of example projects for the Opal Kelly XEM7310A75 FPGA development board. These examples demonstrate various features and capabilities of the board, from basic LED control to more complex operations like DRAM access, FIFO operations, and data transfer using different pipe interfaces.

## Project Structure

```
.
├── bitstream/         # Pre-compiled FPGA bitstream files
├── python/            # Python host software examples
│   ├── 01_led_example/
│   ├── 02_wire_example/
│   ├── 03_pipe_example/
│   ├── 04_block_pipe_example/
│   ├── 05_trigger_example/
│   ├── 06_fifo_example/
│   ├── 07_dram_example/
│   ├── 08_pipe_speedtest/
│   └── 09_btpipe_speedtest/
├── verilog/           # Verilog source code
│   ├── 01_led_example/
│   ├── 02_wire_example/
│   ├── 03_pipe_example/
│   ├── 04_block_pipe_example/
│   ├── 05_trigger_example/
│   ├── 06_fifo_example/
│   ├── 07_dram_example/
│   ├── 08_pipe_speedtest/
│   └── 09_btpipe_speedtest/
└── xdc/               # Xilinx Design Constraint files
    └── xem7310.xdc    # XDC file for the XEM7310 board
```

## Examples Overview

1. **LED Example**: Basic example demonstrating control of the onboard LEDs.
2. **Wire Example**: Shows how to use wire interfaces for simple data transfer.
3. **Pipe Example**: Demonstrates streaming data transfer using pipe interfaces.
4. **Block Pipe Example**: Shows block-based data transfer for larger datasets.
5. **Trigger Example**: Illustrates how to use triggers for synchronization.
6. **FIFO Example**: Demonstrates FIFO (First-In-First-Out) buffer operations.
7. **DRAM Example**: Shows how to access and utilize the onboard DDR3 memory.
8. **Pipe Speedtest**: Transaction speedtest for pipe operations.
9. **BTPipe Speedtest**: Transaction speedtest for block-throttled pipe opeations.

## Requirements

- Opal Kelly XEM7310 FPGA development board
- Python 3.7 or higher
- Opal Kelly FrontPanel SDK
- Xilinx Vivado (for rebuilding bitstreams)

## Getting Started

1. Clone this repository:
   ```
   git clone https://github.com/ojy0216/xem7310A75_examples.git
   cd xem7310A75_examples
   ```

2. Ensure you have the `mms_ok` Python module installed or available in your Python path.
    ```bash
    pip install mms_ok
    ```

3. Connect your XEM7310A75 board to your computer.

4. Run an example:
   ```
   cd python/01_led_example
   python led_example.py
   ```

## Building Bitstreams

Pre-compiled bitstreams are provided in the `bitstream/` directory. If you wish to modify and rebuild the Verilog designs, you'll need Xilinx Vivado:

1. Create a new Vivado project
2. Add the Verilog files from the corresponding example directory
3. Add the XDC constraint files
4. Run synthesis, implementation, and generate bitstream
5. Use the generated .bit file with the Python examples

## Contact
For questions or feedback, please contact: juyoung.oh@snu.ac.kr
