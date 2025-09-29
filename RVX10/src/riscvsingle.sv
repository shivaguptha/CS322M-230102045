// riscvsingle.sv

// RISC-V single-cycle processor
// From Section 7.6 of Digital Design & Computer Architecture
// 27 April 2020
// David_Harris@hmc.edu 
// Sarah.Harris@unlv.edu

// MODIFIED TO INCLUDE RVX10 INSTRUCTIONS FOR ASSIGNMENT

// run 210
// Expect simulator to print "Simulation succeeded"
// when the value 25 (0x19) is written to address 100 (0x64)

// Single-cycle implementation of RISC-V (RV32I)
// User-level Instruction Set Architecture V2.2 (May 7, 2017)
// Implements a subset of the base integer instructions:
//    lw, sw
//    add, sub, and, or, slt, 
//    addi, andi, ori, slti
//    beq
//    jal
// Implements the RVX10 custom instruction set extension:
//    ANDN, ORN, XNOR, MIN, MAX, MINU, MAXU, ROL, ROR, ABS
// Exceptions, traps, and interrupts not implemented
// little-endian memory

// 31 32-bit registers x1-x31, x0 hardwired to 0
// R-Type instructions
//   add, sub, and, or, slt
//   INSTR rd, rs1, rs2
//   Instr[31:25] = funct7 (funct7b5 & opb5 = 1 for sub, 0 for others)
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode
// I-Type Instructions
//   lw, I-type ALU (addi, andi, ori, slti)
//   lw:         INSTR rd, imm(rs1)
//   I-type ALU: INSTR rd, rs1, imm (12-bit signed)
//   Instr[31:20] = imm[11:0]
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode
// S-Type Instruction
//   sw rs2, imm(rs1) (store rs2 into address specified by rs1 + immm)
//   Instr[31:25] = imm[11:5] (offset[11:5])
//   Instr[24:20] = rs2 (src)
//   Instr[19:15] = rs1 (base)
//   Instr[14:12] = funct3
//   Instr[11:7]  = imm[4:0]  (offset[4:0])
//   Instr[6:0]   = opcode
// B-Type Instruction
//   beq rs1, rs2, imm (PCTarget = PC + (signed imm x 2))
//   Instr[31:25] = imm[12], imm[10:5]
//   Instr[24:20] = rs2
//   Instr[19:15] = rs1
//   Instr[14:12] = funct3
//   Instr[11:7]  = imm[4:1], imm[11]
//   Instr[6:0]   = opcode
// J-Type Instruction
//   jal rd, imm  (signed imm is multiplied by 2 and added to PC, rd = PC+4)
//   Instr[31:12] = imm[20], imm[10:1], imm[11], imm[19:12]
//   Instr[11:7]  = rd
//   Instr[6:0]   = opcode

//   Instruction  opcode    funct3    funct7
//   add          0110011   000       0000000
//   sub          0110011   000       0100000
//   and          0110011   111       0000000
//   or           0110011   110       0000000
//   slt          0110011   010       0000000
//   addi         0010011   000       immediate
//   andi         0010011   111       immediate
//   ori          0010011   110       immediate
//   slti         0010011   010       immediate
//   beq          1100011   000       immediate
//   lw	          0000011   010       immediate
//   sw           0100011   010       immediate
//   jal          1101111   immediate immediate

module testbench();
  logic        clk;
  logic        reset;
  logic [31:0] WriteData, DataAdr;
  logic        MemWrite;

  // instantiate device to be tested
  top dut(clk, reset, WriteData, DataAdr, MemWrite);

  // initialize test
  initial
    begin
      reset <= 1; # 22; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check results
  always @(negedge clk)
    begin
      if(MemWrite) begin
        if(DataAdr === 100 & WriteData === 25) begin
          $display("Simulation succeeded");
          $stop;
        end else if (DataAdr !== 96) begin
          $display("Simulation failed");
          $stop;
        end
      end
    end
endmodule

module top(input  logic        clk, reset, 
           output logic [31:0] WriteData, DataAdr, 
           output logic        MemWrite);

  logic [31:0] PC, Instr, ReadData;
  
  // instantiate processor and memories
  riscvsingle rvsingle(clk, reset, PC, Instr, MemWrite, DataAdr, 
                       WriteData, ReadData);
  imem imem(PC, Instr);
  dmem dmem(clk, MemWrite, DataAdr, WriteData, ReadData);
endmodule

module riscvsingle(input  logic        clk, reset,
                   output logic [31:0] PC,
                   input  logic [31:0] Instr,
                   output logic        MemWrite,
                   output logic [31:0] ALUResult, WriteData,
                   input  logic [31:0] ReadData);

  logic       PCSrc, ALUSrc, RegWrite, Jump, Zero;
  logic [1:0] ResultSrc, ImmSrc;
  logic [3:0] ALUControl; // **MODIFIED**: Widened ALUControl from 3 to 4 bits for RVX10 ops

  // **MODIFIED**: Pass full funct7 (Instr[31:25]) to controller for RVX10 decoding
  controller c(Instr[6:0], Instr[14:12], Instr[31:25], Zero,
               ResultSrc, MemWrite, PCSrc,
               ALUSrc, RegWrite, Jump,
               ImmSrc, ALUControl);
  
  datapath dp(clk, reset, ResultSrc, PCSrc,
              ALUSrc, RegWrite,
              ImmSrc, ALUControl,
              Zero, PC, Instr,
              ALUResult, WriteData, ReadData);
endmodule

module controller(input  logic [6:0] op,
                  input  logic [2:0] funct3,
                  input  logic [6:0] funct7, // **MODIFIED**: Input full funct7, not just one bit
                  input  logic       Zero,
                  output logic [1:0] ResultSrc,
                  output logic       MemWrite,
                  output logic       PCSrc, ALUSrc,
                  output logic       RegWrite, Jump,
                  output logic [1:0] ImmSrc,
                  output logic [3:0] ALUControl); // **MODIFIED**: Widened ALUControl to 4 bits

  logic [1:0] ALUOp;
  logic       Branch;

  maindec md(op, ResultSrc, MemWrite, Branch,
             ALUSrc, RegWrite, Jump, ImmSrc, ALUOp);
             
  aludec  ad(op[5], funct3, funct7, ALUOp, ALUControl); // **MODIFIED**: Pass full funct7 to aludec

  assign PCSrc = Branch & Zero | Jump;
endmodule

module maindec(input  logic [6:0] op,
               output logic [1:0] ResultSrc,
               output logic       MemWrite,
               output logic       Branch, ALUSrc,
               output logic       RegWrite, Jump,
               output logic [1:0] ImmSrc,
               output logic [1:0] ALUOp);

  logic [10:0] controls;

  // The control signals are:
  // {RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp, Jump}
  assign {RegWrite, ImmSrc, ALUSrc, MemWrite,
          ResultSrc, Branch, ALUOp, Jump} = controls;

  always_comb
    case(op)
      7'b0000011: controls = 11'b1_00_1_0_01_0_00_0; // lw
      7'b0100011: controls = 11'b0_01_1_1_00_0_00_0; // sw
      7'b0110011: controls = 11'b1_xx_0_0_00_0_10_0; // R-type 
      7'b1100011: controls = 11'b0_10_0_0_00_1_01_0; // beq
      7'b0010011: controls = 11'b1_00_1_0_00_0_10_0; // I-type ALU
      7'b1101111: controls = 11'b1_11_0_0_10_0_00_1; // jal
      // **ADDED**: Case for RVX10 custom instructions [cite: 98]
      7'b0001011: controls = 11'b1_xx_0_0_00_0_11_0; // RVX10: RegWrite=1, ALUSrc=0, ResultSrc=ALU, ALUOp=3
      default:    controls = 11'bx_xx_x_x_xx_x_xx_x; // non-implemented instruction
    endcase
endmodule

module aludec(input  logic       opb5,
              input  logic [2:0] funct3,
              input  logic [6:0] funct7,       // **MODIFIED**: Input full funct7
              input  logic [1:0] ALUOp,
              output logic [3:0] ALUControl); // **MODIFIED**: Widened ALUControl to 4 bits

  logic RtypeSub;
  assign RtypeSub = funct7[5] & opb5;  // TRUE for R-type subtract instruction

  always_comb
    case(ALUOp)
      2'b00: ALUControl = 4'b0000; // addition (for lw/sw)
      2'b01: ALUControl = 4'b0001; // subtraction (for beq)
      2'b10: // R-type or I-type ALU
        case(funct3)
          3'b000: if (RtypeSub) ALUControl = 4'b0001; // sub
                  else          ALUControl = 4'b0000; // add, addi
          3'b010: ALUControl = 4'b0101; // slt, slti
          3'b110: ALUControl = 4'b0011; // or, ori
          3'b111: ALUControl = 4'b0010; // and, andi
          default: ALUControl = 4'bxxxx;
        endcase
      // **ADDED**: Case for RVX10 instructions, decoding based on funct7 and funct3 [cite: 102]
      2'b11: // RVX10 Instructions
        case(funct7)
          7'b0000000: // ANDN, ORN, XNOR
            case(funct3)
              3'b000: ALUControl = 4'b1000; // ANDN
              3'b001: ALUControl = 4'b1001; // ORN
              3'b010: ALUControl = 4'b1010; // XNOR
              default: ALUControl = 4'bxxxx;
            endcase
          7'b0000001: // MIN, MAX, MINU, MAXU
            case(funct3)
              3'b000: ALUControl = 4'b1011; // MIN
              3'b001: ALUControl = 4'b1100; // MAX
              3'b010: ALUControl = 4'b1101; // MINU
              3'b011: ALUControl = 4'b1110; // MAXU
              default: ALUControl = 4'bxxxx;
            endcase
          7'b0000010: // ROL, ROR
            case(funct3)
              3'b000: ALUControl = 4'b1111; // ROL
              3'b001: ALUControl = 4'b0110; // ROR
              default: ALUControl = 4'bxxxx;
            endcase
          7'b0000011: // ABS
            case(funct3)
              3'b000: ALUControl = 4'b0111; // ABS
              default: ALUControl = 4'bxxxx;
            endcase
          default: ALUControl = 4'bxxxx;
        endcase
      default: ALUControl = 4'bxxxx;
    endcase
endmodule

module datapath(input  logic        clk, reset,
                input  logic [1:0]  ResultSrc, 
                input  logic        PCSrc, ALUSrc,
                input  logic        RegWrite,
                input  logic [1:0]  ImmSrc,
                input  logic [3:0]  ALUControl, // **MODIFIED**: Widened ALUControl to 4 bits
                output logic        Zero,
                output logic [31:0] PC,
                input  logic [31:0] Instr,
                output logic [31:0] ALUResult, WriteData,
                input  logic [31:0] ReadData);

  logic [31:0] PCNext, PCPlus4, PCTarget;
  logic [31:0] ImmExt;
  logic [31:0] SrcA, SrcB;
  logic [31:0] Result;

  // next PC logic
  flopr #(32) pcreg(clk, reset, PCNext, PC);
  adder       pcadd4(PC, 32'd4, PCPlus4);
  adder       pcaddbranch(PC, ImmExt, PCTarget);
  mux2 #(32)  pcmux(PCPlus4, PCTarget, PCSrc, PCNext);
 
  // register file logic
  regfile     rf(clk, RegWrite, Instr[19:15], Instr[24:20], 
                 Instr[11:7], Result, SrcA, WriteData);
  extend      ext(Instr[31:7], ImmSrc, ImmExt);

  // ALU logic
  mux2 #(32)  srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
  alu         alu(SrcA, SrcB, ALUControl, ALUResult, Zero);
  mux3 #(32)  resultmux(ALUResult, ReadData, PCPlus4, ResultSrc, Result);
endmodule

module regfile(input  logic        clk, 
               input  logic        we3, 
               input  logic [ 4:0] a1, a2, a3, 
               input  logic [31:0] wd3, 
               output logic [31:0] rd1, rd2);

  logic [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally (A1/RD1, A2/RD2)
  // write third port on rising edge of clock (A3/WD3/WE3)
  // register 0 hardwired to 0
  always_ff @(posedge clk)
    if (we3 & (a3 != 0)) rf[a3] <= wd3; // **MODIFIED**: Ensure writes to x0 are ignored [cite: 107]

  assign rd1 = (a1 != 0) ? rf[a1] : 0;
  assign rd2 = (a2 != 0) ? rf[a2] : 0;
endmodule

module adder(input  [31:0] a, b,
             output [31:0] y);
  assign y = a + b;
endmodule

module extend(input  logic [31:7] instr,
              input  logic [1:0]  immsrc,
              output logic [31:0] immext);

  assign immext = (immsrc == 2'b00) ? {{20{instr[31]}}, instr[31:20]} :  // I-type
                  (immsrc == 2'b01) ? {{20{instr[31]}}, instr[31:25], instr[11:7]} :  // S-type
                  (immsrc == 2'b10) ? {{19{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0} :  // B-type (note: 19 sign bits since LSB is 0)
                  (immsrc == 2'b11) ? {{11{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0} :  // J-type (note: 11 sign bits)
                  32'bx;  // default
endmodule

module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q);
  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             s, 
              output logic [WIDTH-1:0] y);
  assign y = s ? d1 : d0; 
endmodule

module mux3 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, d2,
              input  logic [1:0]       s, 
              output logic [WIDTH-1:0] y);
  assign y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule

module imem(input  logic [31:0] a,
            output logic [31:0] rd);
  logic [31:0] RAM[255:0];

  initial
      $readmemh("tests/rvx10.hex", RAM); // **MODIFIED**: Point to the correct test file

  assign rd = RAM[a[31:2]]; // word aligned
endmodule

module dmem(input  logic        clk, we,
            input  logic [31:0] a, wd,
            output logic [31:0] rd);
  logic [31:0] RAM[255:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;
endmodule

module alu(input  logic [31:0] a, b,
           input  logic [3:0]  alucontrol, // **MODIFIED**: Widened alucontrol to 4 bits
           output logic [31:0] result,
           output logic        zero);
           
  logic [4:0] shamt = b[4:0]; // Shift amount for rotate instructions

always_comb
  case (alucontrol)
    // Original ALU Operations
    4'b0000: result = a + b;            // add
    4'b0001: result = a - b;            // subtract
    4'b0010: result = a & b;            // and
    4'b0011: result = a | b;            // or
    4'b0101: result = $signed(a) < $signed(b); // slt
    
    // **ADDED**: Logic for all 10 RVX10 instructions
    4'b1000: result = a & ~b;           // ANDN
    4'b1001: result = a | ~b;           // ORN
    4'b1010: result = ~(a ^ b);         // XNOR
    4'b1011: result = ($signed(a) < $signed(b)) ? a : b; // MIN (signed)
    4'b1100: result = ($signed(a) > $signed(b)) ? a : b; // MAX (signed)
    4'b1101: result = (a < b) ? a : b;  // MINU (unsigned)
    4'b1110: result = (a > b) ? a : b;  // MAXU (unsigned)
    4'b1111: result = (shamt == 0) ? a : (a << shamt) | (a >> (32 - shamt)); // ROL
    4'b0110: result = (shamt == 0) ? a : (a >> shamt) | (a << (32 - shamt)); // ROR
    4'b0111: result = ($signed(a) >= 0) ? a : -$signed(a);   // ABS
    
    default: result = 32'bx;
  endcase

  assign zero = (result == 32'b0);
endmodule