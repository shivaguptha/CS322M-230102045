# RVX10 Test Program Encodings

This document details the 32-bit machine code for each instruction in the `TESTPLAN.md`.

### Encoding Formulae
- **I-Type:** `(imm[11:0] << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode`
- **S-Type:** `(imm[11:5] << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm[4:0] << 7) | opcode`
- **R-Type:** `(funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode`

### [cite_start]Worked Encoding Example (`andn x12, x5, x6`) [cite: 122]
- **`funct7`**: `0b0000000`
- **`rs2`**: `x6` = `6`
- **`rs1`**: `x5` = `5`
- **`funct3`**: `0b000`
- **`rd`**: `x12` = `12`
- **`opcode`**: `0b0001011` (0x0B)
- **Hex**: `(0x00 << 25) | (6 << 20) | (5 << 15) | (0 << 12) | (12 << 7) | 0x0B` = `0x0062860B`

### Instruction Encodings

| Addr | Assembly              | Encoding (Hex) |
|------|-----------------------|----------------|
| 0x00 | `addi x5, x0, -252`   | `F0400293`     |
| 0x04 | `ori x5, x5, 1445`    | `5A52E293`     |
| 0x08 | `addi x6, x0, 240`    | `0F000313`     |
| 0x0C | `ori x6, x6, 4095`    | `FFF36313`     |
| 0x10 | `andn x12, x5, x6`    | `0062860B`     |
| 0x14 | `addi x7, x0, -2`     | `FFE00393`     |
| 0x18 | `addi x8, x0, 1`      | `00100413`     |
| 0x1C | `minu x12, x7, x8`    | `0183A60B`     |
| 0x20 | `addi x9, x0, -2048`  | `80000493`     |
| 0x24 | `ori x9, x9, 1`       | `0014E493`     |
| 0x28 | `addi x10, x0, 3`     | `00300513`     |
| 0x2C | `rol x12, x9, x10`    | `02A4860B`     |
| 0x30 | `addi x11, x0, -128`  | `F8000593`     |
| 0x34 | `abs x12, x11, x0`    | `0605860B`     |
| 0x38 | `addi x29, x0, 25`    | `01900E93`     |
| 0x3C | `addi x30, x0, 100`   | `06400F13`     |
| 0x40 | `sw x29, 0(x30)`      | `01DE2023`     |