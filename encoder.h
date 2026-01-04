#ifndef ENCODER_H
#define ENCODER_H

#include <stdint.h>
#include <stdio.h>


#define MAX_SYMBOLS 1000
#define MAX_SYMBOL_NAME 128  // Usando el valor más grande


// Tipos de instrucciones RISC-V
typedef enum {
    INSTR_TYPE_R,
    INSTR_TYPE_I,
    INSTR_TYPE_S,
    INSTR_TYPE_B,
    INSTR_TYPE_U,
    INSTR_TYPE_J,
    INSTR_TYPE_UNKNOWN
} instruction_type_t;

// Tipos de sección
typedef enum {
    SECTION_TEXT = 0,
    SECTION_DATA = 1,
    SECTION_UNKNOWN = -1
} section_type_t;

// Estructura para simbolos/etiquetas
typedef struct {
    char name[MAX_SYMBOL_NAME];
    uint32_t address;
    section_type_t section;
    int defined;  // 1 si está definido, 0 si solo referenciado
    int32_t value;  // Valor adicional de encoder_text.h
} symbol_t;

// Tabla de símbolos global
typedef struct {
    symbol_t symbols[MAX_SYMBOLS];
    int count;
    uint32_t text_address;  // Dirección actual en .text
    uint32_t data_address;  // Dirección actual en .data
} symbol_table_t;

// Estructura para instrucción tipo R
typedef struct {
    uint8_t opcode;
    uint8_t rd;
    uint8_t funct3;
    uint8_t rs1;
    uint8_t rs2;
    uint8_t funct7;
} r_type_t;

// Estructura para instrucción tipo I
typedef struct {
    uint8_t opcode;
    uint8_t rd;
    uint8_t funct3;
    uint8_t rs1;
    int16_t imm;  // 12 bits con signo
} i_type_t;

// Estructura para instrucción tipo S
typedef struct {
    uint8_t opcode;
    uint8_t funct3;
    uint8_t rs1;
    uint8_t rs2;
    int16_t imm;  // 12 bits con signo
} s_type_t;

// Estructura para instrucción tipo B
typedef struct {
    uint8_t opcode;
    uint8_t funct3;
    uint8_t rs1;
    uint8_t rs2;
    int16_t imm;  // 13 bits con signo (múltiplo de 2)
} b_type_t;

// Estructura para instrucción tipo U
typedef struct {
    uint8_t opcode;
    uint8_t rd;
    int32_t imm;  // 20 bits superiores
} u_type_t;

// Estructura para instrucción tipo J
typedef struct {
    uint8_t opcode;
    uint8_t rd;
    int32_t imm;  // 21 bits con signo (múltiplo de 2)
} j_type_t;

// Estructura para información de instrucción
typedef struct {
    char mnemonic[16];
    instruction_type_t type;
    uint8_t opcode;
    uint8_t funct3;
    uint8_t funct7;
} instruction_info_t;

// Estructura para manejar palabras de datos en .data
typedef struct {
    uint8_t bytes[4];
    int byte_count;
    uint32_t address;
    char comment[256];  // Para almacenar el comentario
    int has_comment;    // Flag para saber si hay comentario
} data_word_t;

// Opcodes principales RISC-V
#define OPCODE_LUI      0x37
#define OPCODE_AUIPC    0x17
#define OPCODE_JAL      0x6F
#define OPCODE_JALR     0x67
#define OPCODE_BRANCH   0x63
#define OPCODE_LOAD     0x03
#define OPCODE_STORE    0x23
#define OPCODE_OP_IMM   0x13
#define OPCODE_OP       0x33
#define OPCODE_SYSTEM   0x73

// Funct3 para operaciones aritméticas
#define FUNCT3_ADD_SUB  0x0
#define FUNCT3_SLL      0x1
#define FUNCT3_SLT      0x2
#define FUNCT3_SLTU     0x3
#define FUNCT3_XOR      0x4
#define FUNCT3_SRL_SRA  0x5
#define FUNCT3_OR       0x6
#define FUNCT3_AND      0x7

// Funct3 para operaciones multiply extension
#define FUNCT3_MUL      0x0
#define FUNCT3_MULH     0x1 
#define FUNCT3_MULSU    0x2
#define FUNCT3_MULU     0x3
#define FUNCT3_DIV      0x4     
#define FUNCT3_DIVU     0x5
#define FUNCT3_REM      0x6
#define FUNCT3_REMU     0x7

// Funct3 para branches
#define FUNCT3_BEQ      0x0
#define FUNCT3_BNE      0x1
#define FUNCT3_BLT      0x4
#define FUNCT3_BGE      0x5
#define FUNCT3_BLTU     0x6
#define FUNCT3_BGEU     0x7

// Funct3 para loads
#define FUNCT3_LB       0x0
#define FUNCT3_LH       0x1
#define FUNCT3_LW       0x2
#define FUNCT3_LBU      0x4
#define FUNCT3_LHU      0x5

// Funct3 para stores
#define FUNCT3_SB       0x0
#define FUNCT3_SH       0x1
#define FUNCT3_SW       0x2

// Funct7
#define FUNCT7_NORMAL   0x00
#define FUNCT7_MUL      0x01
#define FUNCT7_SUB_SRA  0x20

// Direcciones base por defecto
#define TEXT_BASE_ADDRESS   0x00400000
#define DATA_BASE_ADDRESS   0x10010000


// Funciones de tabla de símbolos
void init_symbol_table(symbol_table_t* table);
int add_symbol(symbol_table_t* table, const char* name, uint32_t address, section_type_t section, int32_t value);
symbol_t* find_symbol(symbol_table_t* table, const char* name);
int resolve_symbol(symbol_table_t* table, const char* name, uint32_t* address);
void print_symbol_table(symbol_table_t* table);
void set_global_symtab(symbol_table_t *tab);

// Funciones de procesamiento de archivo
int first_pass(const char* filename, symbol_table_t* table);
int process_data_directive(symbol_table_t* table, const char* line);
section_type_t get_current_section(const char* line);

// Funciones principales
instruction_type_t classify_instruction(const char* mnemonic);
int parse_register(const char* reg_str);
int parse_immediate_or_symbol(const char* imm_str, symbol_table_t* table, uint32_t current_pc);
uint32_t encode_instruction_with_symbols(const char* instruction_line, symbol_table_t* table, uint32_t current_pc);
uint32_t encode_r_type(const r_type_t* instr);
uint32_t encode_i_type(const i_type_t* instr);
uint32_t encode_s_type(const s_type_t* instr);
uint32_t encode_b_type(const b_type_t* instr);
uint32_t encode_u_type(const u_type_t* instr);
uint32_t encode_j_type(const j_type_t* instr);

// Funciones auxiliares
uint32_t parse_number(const char *s);
char* trim_whitespace(char* str);
int split_instruction(const char* line, char tokens[][MAX_SYMBOL_NAME], int max_tokens);
const instruction_info_t* get_instruction_info(const char* mnemonic);
void print_binary_instruction(uint32_t instruction);
int is_label(const char* line);
char* extract_label(const char* line, char* label_buf);
int is_comment_or_empty(const char* line);
uint32_t align_address(uint32_t address, int alignment);

// Funciones para manejo de palabras de datos
void write_data_word(FILE *out, data_word_t *word, int formato);
void add_byte_to_word(FILE *out, data_word_t *word, uint8_t byte_val, int formato);
void add_byte_to_word_with_comment(FILE *out, data_word_t *word, uint8_t byte_val, int formato, const char* comment);

// Pseudoinstrucciones
int is_pseudoinstruction(const char* mnemonic);
int expand_pseudoinstruction(const char* instruction_line, char expanded[][256], int max_expansions);

#endif // ENCODER_H