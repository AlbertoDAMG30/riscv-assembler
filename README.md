# RISC-V Assembler

![RISC-V](https://img.shields.io/badge/RISC--V-RV32I-blue)
![Language](https://img.shields.io/badge/language-C-orange)
![Platform](https://img.shields.io/badge/platform-Linux-green)
![SDL2](https://img.shields.io/badge/GUI-SDL2-red)

## 📋 Description

A complete **RISC-V assembler** written in C with a graphical user interface built using SDL2. This assembler translates RISC-V assembly code into machine code (binary or hexadecimal format) that can be executed by the RISC-V RARS simulator.

The assembler implements the RV32I base instruction set and generates output identical to RARS, which can be verified using the `diff` command on Linux.

Developed as Project 3 for the EL-3310 Digital Systems Design course at Costa Rica Institute of Technology (TEC).

## 🎯 Key Features

### Core Functionality
- ✅ **Complete RV32I ISA support** - All base RISC-V instructions
- ✅ **Multi-format output** - Binary and hexadecimal machine code
- ✅ **Section processing** - Separate .text and .data sections
- ✅ **Symbol resolution** - Labels and symbolic references
- ✅ **Pseudoinstructions** - Expands common pseudo-ops
- ✅ **Two-pass assembly** - Label resolution and code generation
- ✅ **RARS compatibility** - Output identical to RARS simulator

### User Interface
- 🖥️ **Graphical interface** - Built with SDL2 and SDL_ttf
- 📂 **File browser** - Native file dialog for source selection
- 🎨 **Aesthetic design** - Clean and professional UI
- ⚙️ **Format selection** - Choose binary or hexadecimal output
- 📑 **Section selection** - Process .text or .data independently

### Developer Features
- 🔍 **Detailed console output** - Full instruction decode information
- 📍 **PC tracking** - Shows program counter for each instruction
- 🐛 **No bugs or glitches** - Stable and reliable operation
- 🚫 **No segmentation faults** - Robust memory management
- 📝 **Verbose logging** - Complete assembly process details

## 🛠️ Technologies Used

- **Language**: C (C11 standard)
- **GUI Library**: SDL2, SDL2_ttf
- **File Dialogs**: tinyfiledialogs
- **Threading**: POSIX threads (pthread)
- **Build System**: Make
- **Platform**: Linux (native, no VM)
- **Version Control**: Git/GitLab

## 📦 Requirements

### System Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install build-essential libsdl2-dev libsdl2-ttf-dev

# Fedora/RHEL
sudo dnf install gcc make SDL2-devel SDL2_ttf-devel

# Arch Linux
sudo pacman -S base-devel sdl2 sdl2_ttf
```

### Additional Requirements
- Linux native installation (virtual machines not supported)
- GCC 7.0 or higher
- Make
- Git

## 🚀 Compilation and Execution

### Clone the repository
```bash
git clone https://github.com/AlbertoDAMG30/riscv-assembler.git
cd riscv-assembler
```

### Compile the project
```bash
make
```

### Run the assembler
```bash
./riscv_assembler
```

### Clean build artifacts
```bash
make clean
```

## 📂 Project Structure

```
riscv-assembler/
├── Proyecto_3.c           # Main program with GUI
├── encoder.c              # Instruction encoding engine
├── encoder.h              # Encoder interface and definitions
├── tinyfiledialogs.c      # File dialog library
├── tinyfiledialogs.h      # File dialog header
├── Makefile               # Build configuration
├── README.md              # This file
├── Proyecto_3_digitales.pdf  # Project specifications (Spanish)
└── test_files/            # Test assembly files
    ├── riscv1.asm         # Sample RISC-V program
    └── proyecto2_FINAL_JGJB.asm  # Test program
```

## 🎮 How to Use

### 1. Launch the assembler
```bash
./riscv_assembler
```

### 2. Select input file
- Click on the file selection button
- Choose a `.s` file with RISC-V assembly code
- File must be compatible with RARS simulator

### 3. Choose output format
- **Binary**: Machine code in binary format (0s and 1s)
- **Hexadecimal**: Machine code in hex format (0x...)

### 4. Select section
- **.text**: Process code section (instructions)
- **.data**: Process data section (constants and variables)

### 5. View output
- Generated file saved in same directory as source
- Console shows detailed instruction decoding
- Verify with RARS output using `diff`

### Example Usage
```bash
# Assemble a file
./riscv_assembler
# Select: test_files/riscv1.asm
# Format: Hexadecimal
# Section: .text

# Verify output matches RARS
diff output.hex rars_output.hex
```

## 🧩 Supported Instructions

### R-Type Instructions
- Arithmetic: `add`, `sub`, `slt`, `sltu`
- Logical: `and`, `or`, `xor`
- Shift: `sll`, `srl`, `sra`
- Multiply/Divide: `mul`, `mulh`, `mulsu`, `mulu`, `div`, `divu`, `rem`, `remu`

### I-Type Instructions
- Arithmetic Immediate: `addi`, `slti`, `sltiu`
- Logical Immediate: `andi`, `ori`, `xori`
- Shift Immediate: `slli`, `srli`, `srai`
- Load: `lb`, `lh`, `lw`, `lbu`, `lhu`
- Jump: `jalr`

### S-Type Instructions
- Store: `sb`, `sh`, `sw`

### B-Type Instructions
- Branch: `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`

### U-Type Instructions
- Upper Immediate: `lui`, `auipc`

### J-Type Instructions
- Jump: `jal`

### System Instructions
- `ecall`, `ebreak`

### Pseudoinstructions
- `li` - Load immediate
- `la` - Load address
- `mv` - Move register
- `not` - Bitwise NOT
- `neg` - Negate
- `j` - Unconditional jump
- `jr` - Jump register
- `ret` - Return from subroutine
- And more...

## 🔧 Architecture Details

### Two-Pass Assembly

#### **First Pass**
1. Scan entire source file
2. Build symbol table (labels and addresses)
3. Track `.text` and `.data` sections
4. Resolve label addresses
5. Calculate program counter positions

#### **Second Pass**
1. Generate machine code for each instruction
2. Resolve symbolic references
3. Encode instructions based on type
4. Output formatted machine code
5. Write to output file

### Instruction Encoding

The assembler implements the RISC-V instruction formats:

```
R-Type: [funct7][rs2][rs1][funct3][rd][opcode]
I-Type: [imm[11:0]][rs1][funct3][rd][opcode]
S-Type: [imm[11:5]][rs2][rs1][funct3][imm[4:0]][opcode]
B-Type: [imm[12|10:5]][rs2][rs1][funct3][imm[4:1|11]][opcode]
U-Type: [imm[31:12]][rd][opcode]
J-Type: [imm[20|10:1|11|19:12]][rd][opcode]
```

### Memory Layout
- **Text section**: `0x00400000` - Code instructions
- **Data section**: `0x10010000` - Global variables and constants

## 📊 Console Output

The assembler provides detailed console output for debugging:

```
=== First Pass ===
Found label 'main' at address 0x00400000
Found label 'loop' at address 0x00400008

=== Second Pass ===
PC: 0x00400000 | ADDI x10, x0, 5
  Opcode: 0x13, rd: x10, funct3: 0x0, rs1: x0, imm: 5
  Machine code: 0x00500513

PC: 0x00400004 | ADD x11, x10, x10
  Opcode: 0x33, rd: x11, funct3: 0x0, rs1: x10, rs2: x10, funct7: 0x00
  Machine code: 0x00a505b3
```

## 🐛 Error Handling

The assembler includes comprehensive error checking:

- ✅ Invalid register names
- ✅ Undefined labels
- ✅ Malformed instructions
- ✅ Invalid immediate values
- ✅ Out-of-range offsets
- ✅ Missing operands
- ✅ Syntax errors

## 🧪 Testing

### Test Files Included

1. **riscv1.asm** - Basic instruction test
2. **proyecto2_FINAL_JGJB.asm** - Comprehensive test suite

### Verification Process

```bash
# 1. Assemble with RARS
# (Use RARS GUI to export machine code)

# 2. Assemble with this tool
./riscv_assembler
# Select file and options

# 3. Compare outputs
diff output.hex rars_output.hex
# Should show: (no output = identical files)
```

## 🏆 Project Requirements Compliance

### Mandatory Requirements ✅
- ✅ Native Linux installation (no VM)
- ✅ SDL2 library integration
- ✅ No segmentation faults
- ✅ Complete RV32I instruction set
- ✅ Binary and hexadecimal output
- ✅ .text and .data section support
- ✅ Clean, aesthetic GUI
- ✅ Detailed console logging
- ✅ RARS-identical output
- ✅ Makefile for compilation
- ✅ Git version control

### Code Quality ✅
- ✅ No bugs or glitches
- ✅ Robust error handling
- ✅ Memory leak prevention
- ✅ Clean code structure
- ✅ Comprehensive comments

## 👨‍💻 Author

**David Alberto Mirandda Gonzalez**
- Student ID: 2020207762
- Course: EL-3310 Digital Systems Design
- Institution: Costa Rica Institute of Technology (TEC)
- Professor: Ernesto Rivera Alvarado

**Valeria Santamaria Vargas**
- Student ID: 2022138144
- Course: EL-3310 Digital Systems Design
- Institution: Costa Rica Institute of Technology (TEC)
- Professor: Ernesto Rivera Alvarado

## 📄 License

This project was developed for educational purposes for the Digital Systems Design course at Costa Rica Institute of Technology.

## 🙏 Acknowledgments

- Professor Ernesto Rivera Alvarado for project specifications
- RISC-V Foundation for the ISA documentation
- RARS development team for the reference simulator
- SDL2 community for excellent documentation
- tinyfiledialogs for cross-platform file dialogs

## 📚 References

- [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
- [RARS Simulator](https://github.com/TheThirdOne/rars)
- [SDL2 Documentation](https://wiki.libsdl.org/)
- Patterson & Hennessy - Computer Organization and Design: RISC-V Edition

## 🔗 Related Projects

- [RISC-V Emulator](https://github.com/AlbertoDAMG30/riscv-emulator) - Project 2
- [Battle City NES](https://github.com/AlbertoDAMG30/battle-city-nes-replica) - Project 1

---

⭐ If you found this project helpful, give it a star on GitHub!
**Note**: This assembler is designed for educational purposes and implements the RV32I base instruction set. For production use, consider using official RISC-V toolchains.
