# ECE 298A Microcontroller Documentation

## Inputs

| Input | Usage | Description |
| :---- | :---- | :---- |
| ui\_in\[7:0\] | Send 8-bit instructions and immediate values to the microcontroller | If the instruction needs an immediate value, an 8-bit immediate value is passed in at the next cycle. |
| clk | Clock to drive microcontroller | The microcontroller is tested using a frequency of 25MHz |
| rst\_n | Reset microcontroller | When rst\_n is low, the microcontroller goes to FETCH state for the next clock cycle. All registers are reset to 0\. The PC is reset to 0 at the cycle after that. The next instruction can be sent 1 cycle after resetting. |

## Outputs

Every instruction takes 5 cycles. The initialization takes 7 cycles. Resetting takes 2 cycles including the cycle where the reset signal is passed in. If an invalid instruction is sent, 1 cycle needs to pass before the next can be sent in.  
When the microcontroller runs at 25MHz, each instruction takes 200ns.

### Output pins (uo\_out\[7:0\])

If the instruction is invalid, the output is Z.

### Bidirectional pins (uio\_out\[7:0\])

| 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| Send instruction (1 indicates next instruction should be sent now, output is available in same cycle) | Status (0 indicates normal, 1 indicates error and output will be Z) | PC value (first instruction has value 1, initialization cycle has value 0\) | PC value | PC value | PC value | PC value | PC value |

## Instruction Set

### Format of instructions (8 bits)

| 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| Sources | Opcode | Opcode | Opcode | Opcode | Opcode | Opcode | Opcode |

### Sources for different types of instructions

| Instruction type | 7 | 6 | 5 | 4 |
| :---- | :---: | :---: | :---: | :---: |
| No op (N) | 0 | 0 | 0 | 0 |
| Regular (R) | Immediate (00), Reg B (10), or Accumulator (11) | Immediate (00), Reg A (01), or Reg B (10) | 0 | 1 |
| One source (O) | 0 | 0 | Immediate (00), Reg A (01), Reg B (10), or Accumulator (11) | Immediate (00), Reg A (01), or Reg B (10) |
| Load (L) | 0 | 0 | Reg A (01) or Reg B (10) | Reg A (01) or Reg B (10) |
|  | Immediate (00), Reg A (01), or Reg B (10) | Immediate (00), Reg A (01), or Reg B (10) | 1 | 1 |
| Jump (J) | 0 | 0 | 0 | 0 |
| Branch (B) | 0 | 0 | Reg A (01), Reg B (10), or Accumulator (11) | Reg A (01), Reg B (10), or Accumulator (11) |

### Instructions

| Category | Instruction | Instruction type | Opcode | Description | Output |
| :---- | :---- | ----- | ----- | :---- | ----- |
| Operation | NO OP | N | 0 |  | Z |
| Arithmetic | ADD | R | 1 |  | ALU result from Acc |
|  | SUB | R | 2 |  |  |
|  | SHL | O | 3 | Shift left by 1 bit |  |
|  | SHR | O | 4 | Shift right by 1 bit |  |
|  | AND | R | 5 |  |  |
|  | OR | R | 6 |  |  |
|  | XOR | R | 7 |  |  |
|  | NOT | O | 8 |  |  |
| Load | LOAD | L | A |  | Loaded value (should be same as immediate value inputted) |
| Comparison | LESS | R | B |  | 1 or 0 |
|  | EQUAL | R | C |  |  |
|  | GREATER | R | D |  |  |
| Branching | JUMP | J | 9 | Change PC value to immediate value | Z |
|  | BEZ | B | E | Change PC value to immediate value if register value is equal to 0 | 1 or 0 |
|  | BNEZ | B | F | Change PC value to immediate value if register value is not equal to 0 |  |

## Control Signals (16 bits)

Used to control all components of the microcontroller during each state. The LUT stores control signals of all valid instructions.

| Position | Control Signal | Usage |
| :---- | :---- | :---- |
| 15 | MemRead | Read from external memory (for future) |
| 14 | MemWrite | Write to external memory (for future) |
| 13 | RegDest\[1\] | 2 bit value for the destination register to write to |
| 12 | RegDest\[0\] |  |
| 11 | RegWrite | Write to destination register specified by RegDest\[1:0\] |
| 10 | InsLoad | Store instruction to Instruction Reg |
| 9 | ImmLoad | Store immediate value to Immediate Reg |
| 8 | PCLoad | Load immediate value to PC |
| 7 | Out | Output Acc to output pins |
| 6 | ALUOperand | For O-type instructions, ALU needs to select Reg A or ALUSrc to perform operation with, 0 to select Reg A, 1 to select output from multiplexer |
| 5 | ALUSrc\[1\] | 2 bit value for ALU source selection multiplexer |
| 4 | ALUSrc\[0\] |  |
| 3 | ALUOp\[3\] | 4 bit value for ALU operation  |
| 2 | ALUOp\[2\] |  |
| 1 | ALUOp\[1\] |  |
| 0 | ALUOp\[0\] |  |

### RegDest (2 bits)

| RegDest\[1:0\] | Destination register |
| :---- | :---- |
| 00 | None |
| 01 | Reg A |
| 10 | Reg B |
| 11 | Acc |

### ALUSrc (2 bits)

| ALUSrc\[1:0\] | Source register |
| :---- | :---- |
| 00 | Immediate Reg |
| 01 | Zero |
| 10 | Reg B |
| 11 | Acc |

### ALUOp (4 bits)

ALUOp is the same as Opcode for all instructions.

## States

| Clock cycle | FSM State | State \[1:0\] | Description |
| :---- | :---- | :---- | :---- |
| 1 | Fetch | 000 | Load instruction to instruction register |
| 2 | Decode | 001 | Load immediate value to immediate register if the instruction is I-type |
| 3 | Execute | 010 | Multiplexer selects second operand, values are loaded into ALU, ALU operation is selected |
| 4 | Writeback | 011 | ALU performs operation and writes result to accumulator |
| 5 | Output | 100 | Accumulator stores ALU result and result is present on output pins (on rising edge) |

