# Vending Machine FSM - Mealy Implementation

This repository contains a Verilog implementation of a vending machine finite state machine (FSM) using Mealy architecture. The machine accepts coins of denomination 5 and 10, dispenses a product when the total reaches or exceeds 20, and provides change when necessary.

## Design Specifications

### Requirements
- **Product Price**: 20 units
- **Accepted Coins**: 5 (coin=01) and 10 (coin=10)
- **Dispensing Logic**: When total ≥ 20, assert `dispense=1` for 1 cycle
- **Change Logic**: If total = 25, assert `chg5=1` for 1 cycle (return 5 units)
- **Reset Behavior**: Synchronous active-high reset
- **Coin Input**: Maximum one coin per clock cycle
- **Invalid Coins**: Ignore coin=11, treat coin=00 as idle

### State Diagram
```
States:
- idle (00):    Total = 0
- five (01):    Total = 5  
- ten (10):     Total = 10
- fifteen (11): Total = 15

Transitions with Mealy Outputs:
idle --01--> five --01--> ten --01--> fifteen --01/dispense--> idle
  |           |           |              |
  10          10          10             10
  |           |           |              |
  v           v           v              v
 ten -----> fifteen --> idle         idle
                      /dispense    /dispense,chg5

Self-loops on 00 (idle) for all states
```

### Module Interface
```verilog
module vending_mealy(
    input  wire clk,        // Clock signal
    input  wire rst,        // Synchronous active-high reset
    input  wire [1:0] coin, // Coin input: 01=5, 10=10, 00=idle
    output reg  dispense,   // Product dispensing pulse
    output reg  chg5        // Change (5 units) pulse
);
```

## Files Structure
- `vending_mealy.v` - Main FSM module implementation
- `tb_vending_mealy.v` - Comprehensive testbench
- `tb_vending_mealy.vcd` - Generated waveform file

## Compile/Run/Visualize Steps

### Prerequisites
- **iverilog** (Icarus Verilog compiler)
- **GTKWave** (for waveform visualization)

### Step 1: Compile
```bash
iverilog -o vending_sim vending_mealy.v tb_vending_mealy.v
```

### Step 2: Run Simulation
```bash
vvp vending_sim
```

### Step 3: Visualize Waveforms
```bash
gtkwave tb_vending_mealy.vcd
```

In GTKWave:
1. Add signals: `clk`, `rst`, `coin[1:0]`, `dispense`, `chg5`
2. Add internal signals: `state_present[1:0]`, `state_next[1:0]` for debugging
3. Set time scale and observe the transaction patterns

## Implementation Approach

### 1. Mealy Architecture Choice
- **Outputs depend on both current state and inputs**
- Faster response compared to Moore machines
- Output logic integrated with state transition logic
- Single-cycle pulse generation for dispense and change signals

### 2. State Encoding Strategy
```verilog
parameter idle=2'b00, five=2'b01, ten=2'b10, fifteen=2'b11;
```
- 2-bit encoding for 4 states
- Direct correspondence with accumulated coin values (0, 5, 10, 15)
- Efficient hardware implementation

### 3. Output Generation Logic
```verilog
// Mealy outputs in clocked always block
always @(posedge clk) begin
    dispense <= 0; // Default reset
    chg5 <= 0;     // Default reset
    
    if(state_present==ten && coin==2'b10)
        dispense <= 1; // 10+10=20: dispense
    else if(state_present==fifteen && coin==2'b01)
        dispense <= 1; // 15+5=20: dispense
    else if(state_present==fifteen && coin==2'b10) begin
        dispense <= 1; // 15+10=25: dispense
        chg5 <= 1;     // and give change
    end
end
```

### 4. State Transition Logic
- Combinational always block for next-state computation
- Default assignment prevents latches
- Comprehensive case coverage for all states and inputs

## Test Scenarios and Expected Behavior

### Exact Payment (Total = 20)
1. **5+5+10 = 20**: `dispense=1`, `chg5=0`
2. **5+10+5 = 20**: `dispense=1`, `chg5=0`
3. **10+5+5 = 20**: `dispense=1`, `chg5=0`
4. **10+10 = 20**: `dispense=1`, `chg5=0`

### Overpayment (Total = 25)
5. **15+10 = 25**: `dispense=1`, `chg5=1`

### Underpayment Scenarios
- **Single coin (5 or 10)**: No dispensing, FSM waits
- **Total < 20**: FSM accumulates coins

### Reset Behavior
- **Mid-transaction reset**: FSM returns to idle state
- **Accumulated total lost**: Fresh transaction starts

## Testbench Features

### Task-Based Stimulus Generation
```verilog
task insert_coin(input [1:0] c);
begin
    coin = c; #10;      // Assert coin for one cycle
    coin = 2'b00; #10;  // Return to idle state
end
endtask
```

### Comprehensive Test Coverage
- All valid coin combinations totaling 20
- Overpayment scenarios (total = 25)
- Underpayment scenarios
- Reset functionality during transactions
- Multiple consecutive transactions

### Waveform Analysis Points
From the provided waveforms, key observation points:

1. **Dispense Pulses**: Single-cycle assertions when total ≥ 20
2. **Change Signal**: Asserted only when total = 25
3. **State Transitions**: Clean transitions between coin accumulation states
4. **Reset Recovery**: Proper return to idle state on reset assertion

## Timing Specifications
- **Clock Frequency**: 100 MHz (10ns period)
- **Setup/Hold**: Standard FPGA requirements
- **Pulse Width**: Single clock cycle for both dispense and chg5
- **Coin Input Timing**: One coin per clock cycle maximum

## Verification Results

### Expected Pulse Indices
Based on testbench scenarios:
- **Dispense pulses**: Generated at completion of each valid transaction (total ≥ 20)
- **Change pulses**: Generated only for overpayment scenarios (total = 25)
- **State consistency**: FSM returns to idle after each successful transaction

### Debug Capabilities
- State tracking through `state_present` and `state_next` signals
- Coin input validation
- Output pulse verification
- Reset functionality validation

## Design Considerations

### Hardware Efficiency
- **Resource Usage**: 2 flip-flops for state, minimal combinational logic
- **Power Consumption**: Low switching activity in idle state
- **Area Optimization**: Compact state encoding

### Robustness Features
- **Invalid input handling**: Ignores undefined coin values (11)
- **Glitch immunity**: Synchronous design eliminates metastability
- **Reset reliability**: Guaranteed return to known state

### Scalability
- **Easy denomination changes**: Modify state encoding and transition logic
- **Price adjustment**: Simple parameter modification
- **Additional features**: Easy integration of timeout, inventory management

## Common Issues and Debugging

### Potential Problems
1. **Missing pulses**: Check Mealy output timing
2. **State stuck**: Verify transition conditions
3. **Multiple pulses**: Ensure single-cycle assertion logic

### Debugging Steps
1. Monitor state transitions in waveform
2. Verify coin input timing alignment
3. Check reset assertion and deassertion
4. Validate output pulse width and timing