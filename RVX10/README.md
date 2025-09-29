# RISC-V Single-Cycle Processor with RVX10 Extension

This project implements a simple single-cycle RISC-V (RV32I) processor in SystemVerilog, extended with 10 custom instructions from the RVX10 set as per the assignment specification.

## Project Structure

- `src/riscvsingle.sv`: The complete, modified source code for the processor and testbench.
- `tests/rvx10.hex`: The hex machine code file for verifying the RVX10 "Worked Examples".
- `docs/TESTPLAN.md`: The test plan detailing the assembly program.
- `docs/ENCODINGS.md`: Hand-calculated machine code for the test plan.

## How to Build and Run

This project can be run with any standard SystemVerilog simulator (e.g., ModelSim/Questa, VCS, Icarus Verilog).

1.  **Ensure File Paths:**
    - The `riscvsingle.sv` file must be able to locate the instruction memory file. The `$readmemh` path inside `imem` module is set to `"tests/rvx10.hex"`.
    - Create a `tests` directory and place `rvx10.hex` inside it.

2.  **Simulation:**
    - Compile `src/riscvsingle.sv`.
    - Run the simulation, targeting the `testbench` module.
    - The simulation will run automatically and print a success or failure message to the console.

3.  **Success Condition:**
    - The testbench will print `"Simulation succeeded"` if the test program correctly executes and writes the value `25` to memory address `100`.