#include "encoder.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <errno.h>

static symbol_table_t *global_symtab = NULL;
void set_global_symtab(symbol_table_t *t) { global_symtab = t; }

/* ================================================================
 *  TABLA DE INSTRUCCIONES (subset RV32I)                         */
/* ================================================================ */

static const instruction_info_t instruction_table[] = {
    /*------ tipo R ------*/
    {"add",   INSTR_TYPE_R, OPCODE_OP,      FUNCT3_ADD_SUB, FUNCT7_NORMAL},
    {"sub",   INSTR_TYPE_R, OPCODE_OP,      FUNCT3_ADD_SUB, FUNCT7_SUB_SRA},
    {"and",   INSTR_TYPE_R, OPCODE_OP,      FUNCT3_AND,     FUNCT7_NORMAL},
    {"or",    INSTR_TYPE_R, OPCODE_OP,      FUNCT3_OR,      FUNCT7_NORMAL},
    {"xor",   INSTR_TYPE_R, OPCODE_OP,      FUNCT3_XOR,     FUNCT7_NORMAL},
    {"sll",   INSTR_TYPE_R, OPCODE_OP,      FUNCT3_SLL,     FUNCT7_NORMAL},
    {"srl",   INSTR_TYPE_R, OPCODE_OP,      FUNCT3_SRL_SRA, FUNCT7_NORMAL},
    {"sra",   INSTR_TYPE_R, OPCODE_OP,      FUNCT3_SRL_SRA, FUNCT7_SUB_SRA},
    {"slt",   INSTR_TYPE_R, OPCODE_OP,      FUNCT3_SLT,     FUNCT7_NORMAL},
    {"sltu",  INSTR_TYPE_R, OPCODE_OP,      FUNCT3_SLTU,    FUNCT7_NORMAL},

    /*------ tipo R, multiply extension  ------*/
    {"mul",   INSTR_TYPE_R, OPCODE_OP,      FUNCT3_MUL, FUNCT7_MUL},
    {"mulh",  INSTR_TYPE_R, OPCODE_OP,      FUNCT3_MULH, FUNCT7_MUL},
    {"mulsu", INSTR_TYPE_R, OPCODE_OP,      FUNCT3_MULSU, FUNCT7_MUL},
    {"mulu",  INSTR_TYPE_R, OPCODE_OP,      FUNCT3_MULU,     FUNCT7_MUL},
    {"div",   INSTR_TYPE_R, OPCODE_OP,      FUNCT3_DIV, FUNCT7_MUL},
    {"divu",  INSTR_TYPE_R, OPCODE_OP,      FUNCT3_DIVU, FUNCT7_MUL},
    {"rem",   INSTR_TYPE_R, OPCODE_OP,      FUNCT3_REM, FUNCT7_MUL},
    {"remu",  INSTR_TYPE_R, OPCODE_OP,      FUNCT3_REMU, FUNCT7_MUL},
    
    /*------ tipo I (aritm/logic) ------*/
    {"addi",  INSTR_TYPE_I, OPCODE_OP_IMM,  FUNCT3_ADD_SUB, 0},
    {"andi",  INSTR_TYPE_I, OPCODE_OP_IMM,  FUNCT3_AND,     0},
    {"ori",   INSTR_TYPE_I, OPCODE_OP_IMM,  FUNCT3_OR,      0},
    {"xori",  INSTR_TYPE_I, OPCODE_OP_IMM,  FUNCT3_XOR,     0},
    {"slti",  INSTR_TYPE_I, OPCODE_OP_IMM,  FUNCT3_SLT,     0},
    {"sltiu", INSTR_TYPE_I, OPCODE_OP_IMM,  FUNCT3_SLTU,    0},
    {"slli",  INSTR_TYPE_I, OPCODE_OP_IMM,  FUNCT3_SLL,     0},
    {"srli",  INSTR_TYPE_I, OPCODE_OP_IMM,  FUNCT3_SRL_SRA, 0},
    {"srai",  INSTR_TYPE_I, OPCODE_OP_IMM,  FUNCT3_SRL_SRA, FUNCT7_SUB_SRA},

    /*------ cargas (I) ------*/
    {"lb",    INSTR_TYPE_I, OPCODE_LOAD,    FUNCT3_LB,   0},
    {"lh",    INSTR_TYPE_I, OPCODE_LOAD,    FUNCT3_LH,   0},
    {"lw",    INSTR_TYPE_I, OPCODE_LOAD,    FUNCT3_LW,   0},
    {"lbu",   INSTR_TYPE_I, OPCODE_LOAD,    FUNCT3_LBU,  0},
    {"lhu",   INSTR_TYPE_I, OPCODE_LOAD,    FUNCT3_LHU,  0},

    /*------ stores (S) ------*/
    {"sb",    INSTR_TYPE_S, OPCODE_STORE,   FUNCT3_SB,   0},
    {"sh",    INSTR_TYPE_S, OPCODE_STORE,   FUNCT3_SH,   0},
    {"sw",    INSTR_TYPE_S, OPCODE_STORE,   FUNCT3_SW,   0},

    /*------ saltos cond. (B) ------*/
    {"beq",   INSTR_TYPE_B, OPCODE_BRANCH,  FUNCT3_BEQ,  0},
    {"bne",   INSTR_TYPE_B, OPCODE_BRANCH,  FUNCT3_BNE,  0},
    {"blt",   INSTR_TYPE_B, OPCODE_BRANCH,  FUNCT3_BLT,  0},
    {"bge",   INSTR_TYPE_B, OPCODE_BRANCH,  FUNCT3_BGE,  0},
    {"bltu",  INSTR_TYPE_B, OPCODE_BRANCH,  FUNCT3_BLTU, 0},
    {"bgeu",  INSTR_TYPE_B, OPCODE_BRANCH,  FUNCT3_BGEU, 0},

    /*------ tipo U / J ------*/
    {"lui",   INSTR_TYPE_U, OPCODE_LUI,     0, 0},
    {"auipc", INSTR_TYPE_U, OPCODE_AUIPC,   0, 0},
    {"jal",   INSTR_TYPE_J, OPCODE_JAL,     0, 0},
    {"jalr",  INSTR_TYPE_I, OPCODE_JALR,    0, 0},
    
    /*------ system (ECALL/EBREAK) ------*/
    {"ecall", INSTR_TYPE_UNKNOWN, 0, 0, 0}, 
    {"ecall",  INSTR_TYPE_I, OPCODE_SYSTEM, 0, 0},
    {"ebreak", INSTR_TYPE_I, OPCODE_SYSTEM, 0, 1},

    /* centinela */
    {"", INSTR_TYPE_UNKNOWN, 0, 0, 0}
};

// Variables globales para manejo de %pcrel_hi y %pcrel_lo
static struct {
    char label[MAX_SYMBOL_NAME];
    uint32_t hi_pc;
    int32_t hi_value;
} pcrel_context = {"", 0, 0};

/* ================================================================
 *  HELPERS genéricos                                              */
/* ================================================================ */

/* Devuelve UINT32_MAX si la cadena NO es un número válido */
uint32_t parse_number(const char *s)
{
    errno = 0;
    char *end = NULL;

    /* base 0  →  "0x…" = hex, "0b…" = bin (GNU ext.), "0…" = octal   *
     *            cualquier otro = decimal                             */
    unsigned long val = strtoul(s, &end, 0);

    if (errno || end == s || *end != '\0')
        return UINT32_MAX;          /* error ► símbolo mal formado    */

    return (uint32_t)val;
}

char *trim_whitespace(char *s)
{
    if (!s) return s;
    while (isspace((unsigned char)*s)) ++s;
    if (!*s) return s;
    char *e = s + strlen(s) - 1;
    while (e > s && isspace((unsigned char)*e)) *e-- = '\0';
    return s;
}

int split_instruction(const char *line, char tk[][MAX_SYMBOL_NAME], int max)
{
    int n = 0;
    char buf[256];
    strncpy(buf, line, sizeof buf - 1);
    buf[sizeof buf - 1] = '\0';
    for (char *p = strtok(buf, " ,\t\r\n"); p && n < max; p = strtok(NULL, " ,\t\r\n"))
        strncpy(tk[n++], p, MAX_SYMBOL_NAME-1)[MAX_SYMBOL_NAME-1] = '\0';
    return n;
}

uint32_t align_address(uint32_t address, int alignment) {
    return (address + alignment - 1) & ~(alignment - 1);
}

/* ================================================================
 *  TABLA DE SÍMBOLOS                                              */
/* ================================================================ */

void init_symbol_table(symbol_table_t *t)
{
    t->count = 0;
    t->text_address = TEXT_BASE_ADDRESS;
    t->data_address = DATA_BASE_ADDRESS;
}

int add_symbol(symbol_table_t *t, const char *name,
               uint32_t addr_or_val, section_type_t sec, int32_t value)
{
    if (t->count >= MAX_SYMBOLS) return -1;
    strcpy(t->symbols[t->count].name, name);
    t->symbols[t->count].address = addr_or_val;
    t->symbols[t->count].section = sec;
    t->symbols[t->count].defined = 1;
    t->symbols[t->count].value = value;
    t->count++;
    return 0;
}

symbol_t *find_symbol(symbol_table_t *t, const char *name)
{
    for (int i = 0; i < t->count; ++i)
        if (!strcmp(t->symbols[i].name, name)) return &t->symbols[i];
    return NULL;
}

int resolve_symbol(symbol_table_t *t, const char *name, uint32_t *out)
{
    symbol_t *s = find_symbol(t, name);
    if (!s || !s->defined) return -1;
    *out = s->address;
    return 0;
}

/* ================================================================
 *  FUNCIONES PARA MANEJO DE PALABRAS DE DATOS                    */
/* ================================================================ */

void write_data_word(FILE *out, data_word_t *word, int formato) {
    if (word->byte_count == 0) return;
    
    // Completar con ceros si no está llena
    while (word->byte_count < 4) {
        word->bytes[word->byte_count++] = 0;
    }
    
    // Convertir a uint32_t (little-endian)
    uint32_t value = (uint32_t)word->bytes[0] |
                     ((uint32_t)word->bytes[1] << 8) |
                     ((uint32_t)word->bytes[2] << 16) |
                     ((uint32_t)word->bytes[3] << 24);
    
    if (formato == 0) { // Hexadecimal
        if (word->has_comment && strlen(word->comment) > 0) {
            fprintf(out, "0x%08X: 0x%08X  # %s\n", word->address, value, word->comment);
        } else {
            fprintf(out, "0x%08X: 0x%08X\n", word->address, value);
        }
    } else if (formato == 1) { // Binario
        // Formatear binario manualmente con espacios cada 4 bits
        char binarioFormateado[50];
        int j = 0;
        for (int i = 31; i >= 0; i--) {
            binarioFormateado[j++] = ((value >> i) & 1) ? '1' : '0';
            if ((31 - i + 1) % 4 == 0 && i > 0) {
                binarioFormateado[j++] = ' ';
            }
        }
        binarioFormateado[j] = '\0';
        
        if (word->has_comment && strlen(word->comment) > 0) {
            fprintf(out, "0x%08X: %s  # %s\n", word->address, binarioFormateado, word->comment);
        } else {
            fprintf(out, "0x%08X: %s\n", word->address, binarioFormateado);
        }
    }
    
    // Reset para la siguiente palabra
    word->byte_count = 0;
    word->address += 4;
    word->comment[0] = '\0';  // Limpiar comentario
    word->has_comment = 0;
}

// Función modificada para agregar bytes con comentarios
void add_byte_to_word_with_comment(FILE *out, data_word_t *word, uint8_t byte_val, int formato, const char* comment) {
    // Si no hay comentario previo, agregar este
    if (!word->has_comment && comment && strlen(comment) > 0) {
        strncpy(word->comment, comment, sizeof(word->comment) - 1);
        word->comment[sizeof(word->comment) - 1] = '\0';
        word->has_comment = 1;
    }
    
    word->bytes[word->byte_count++] = byte_val;
    
    // Si la palabra está completa, escribirla
    if (word->byte_count == 4) {
        write_data_word(out, word, formato);
    }
}

// Función wrapper para mantener compatibilidad
void add_byte_to_word(FILE *out, data_word_t *word, uint8_t byte_val, int formato) {
    add_byte_to_word_with_comment(out, word, byte_val, formato, NULL);
}


// Función auxiliar para contar bytes en un string (usar en AMBAS pasadas)
static size_t count_string_bytes(const char *start, const char *end) {
    size_t count = 0;
    const char *p = start;
    
    while (p < end) {
        if (*p == '\\' && (p + 1) < end) {
            // Secuencia de escape - siempre cuenta como 1 byte
            p += 2;
            count += 1;
        } else {
            // Byte normal - contar cada byte individualmente
            // NO interpretar UTF-8 multibyte, solo contar bytes raw
            p++;
            count += 1;
        }
    }
    
    return count;
}

/* ================================================================
 *  DIRECTIVAS .data (con valor de salida)                         */
/* ================================================================ */

static int process_data_directive_ex(symbol_table_t *table,
                                     const char *line,
                                     int32_t *value_out)
{
    if (value_out) *value_out = 0;  // Inicializar siempre
    
    char tk[8][MAX_SYMBOL_NAME];
    int n = split_instruction(line, tk, 8);
    if (n < 1) return 0;

    const char *dir = tk[0];
    
    /* ---- .align N ---- */
    if (!strcmp(dir, ".align") && n >= 2) {
        int shift = atoi(tk[1]);
        table->data_address = align_address(table->data_address, 1 << shift);
        return 0;
    }

    /* ---- cadenas: .asciz / .asciiz (con '\0')  ---- */
    if (!strcmp(dir, ".asciz") || !strcmp(dir, ".asciiz") || !strcmp(dir, ".string")) {
        const char *start = strchr(line, '"');
        if (start) {
            const char *end = strrchr(start + 1, '"');
            if (end && end > start) {
                size_t count = 0;
                const char *p = start + 1;
                
                printf("DEBUG PRIMERA PASADA: Contando string '%.*s'\n", (int)(end - start - 1), start + 1);
                
                // IMPORTANTE: Contar BYTES, no caracteres
                while (p < end) {
                    if (*p == '\\' && (p + 1) < end) {
                        // Secuencia de escape
                        printf("DEBUG PRIMERA PASADA: Escape sequence \\%c = 1 byte\n", *(p + 1));
                        p += 2; // Saltar los dos caracteres de la secuencia
                        count += 1; // Pero cuenta como 1 byte
                    } else {
                        // Carácter normal - contar como byte individual
                        unsigned char ch = (unsigned char)*p;
                        printf("DEBUG PRIMERA PASADA: Byte 0x%02X ('%c')\n", ch, 
                               (ch >= 32 && ch < 127) ? ch : '.');
                        p++;
                        count += 1;
                    }
                }
                
                printf("DEBUG PRIMERA PASADA: String cuenta %zu bytes + 1 null = %zu total\n", 
                       count, count + 1);
                
                size_t len = count + 1;  // +1 para '\0'
                table->data_address += len;
                if (value_out) *value_out = 0;
                return (int)len;
            }
        }
        return 0;
    }

    /* ---- cadenas: .ascii (sin '\0')  ---- */
    if (!strcmp(dir, ".ascii")) {
        const char *start = strchr(line, '"');
        if (start) {
            const char *end = strrchr(start + 1, '"');
            if (end && end > start) {
                size_t count = 0;
                const char *p = start + 1;
                
                printf("DEBUG PRIMERA PASADA (.ascii): Contando string\n");
                
                // IMPORTANTE: Contar BYTES, no caracteres
                while (p < end) {
                    if (*p == '\\' && (p + 1) < end) {
                        p += 2;
                        count += 1;
                    } else {
                        // Cada byte cuenta como 1
                        unsigned char ch = (unsigned char)*p;
                        printf("DEBUG PRIMERA PASADA: Byte 0x%02X\n", ch);
                        p++;
                        count += 1;
                    }
                }
                
                printf("DEBUG PRIMERA PASADA (.ascii): Total %zu bytes\n", count);
                
                table->data_address += count;
                if (value_out) *value_out = 0;
                return (int)count;
            }
        }
        return 0;
    }

    /* ---- .space / .skip N ---- */
    if ((!strcmp(dir, ".space") || !strcmp(dir, ".skip")) && n >= 2) {
        int sz = parse_number(tk[1]);
        table->data_address += sz;
        return sz;
    }

    /* ---- datos numéricos: .word/.half/.byte ---- */
    int bytes = !strcmp(dir, ".word") ? 4 :
                !strcmp(dir, ".half") || !strcmp(dir, ".short") ? 2 :
                !strcmp(dir, ".byte") ? 1 : 0;
    
    if (bytes) {
        // Alineación si es necesario
        if (bytes > 1) {
            table->data_address = align_address(table->data_address, bytes);
        }
        
        // Contar elementos después de la directiva
        const char *p = line + strlen(dir);
        while (*p && isspace((unsigned char)*p)) ++p;
        int count = 0;
        if (*p) {
            count = 1;
            for (const char *q = p; *q; ++q)
                if (*q == ',') ++count;
        }
        
        // Obtener el valor del primer elemento si se solicita
        if (value_out && count > 0) {
            char buf[MAX_SYMBOL_NAME];
            const char *comma = strchr(p, ',');
            size_t len = comma ? (size_t)(comma - p) : strcspn(p, " \t\r\n");
            if (len >= sizeof(buf)) len = sizeof(buf) - 1;
            memcpy(buf, p, len);
            buf[len] = '\0';
            
            char *trimmed = trim_whitespace(buf);
            
            // Manejar caracteres entre comillas simples
            if (trimmed[0] == '\'' && strlen(trimmed) >= 3 && trimmed[2] == '\'') {
                *value_out = (int32_t)(unsigned char)trimmed[1];
            } else {
                *value_out = (int32_t)parse_number(trimmed);
            }
        }
        
        int total = bytes * count;
        table->data_address += total;
        return total;
    }

    /* no reconocido */
    return 0;
}

int process_data_directive(symbol_table_t *table, const char *line)
{
    return process_data_directive_ex(table, line, NULL);
}

/* Verifica si necesita expansión PC-relative */
static int needs_pcrel_expansion(const char *token)
{
    // Es una etiqueta si NO es un número y NO contiene paréntesis
    if (strchr(token, '(')) return 0;
    
    // Si empieza con dígito o signo, es un número
    if (isdigit(token[0]) || token[0] == '-' || token[0] == '+') return 0;
    
    // Si es hexadecimal
    if (token[0] == '0' && (token[1] == 'x' || token[1] == 'X')) return 0;
    
    // Si contiene %pcrel ya está expandido
    if (strstr(token, "%pcrel")) return 0;
    
    // En otro caso, es una etiqueta que necesita expansión
    return 1;
}
/* ================================================================
 *  PRIMERA PASADA – genera tabla de símbolos                      */
/* ================================================================ */

static int is_label_line(const char *l) {
    return strchr(l, ':') != NULL;
}

char *extract_label(const char *l, char *buf)
{
    const char *c = strchr(l, ':');
    if (!c) return NULL;
    size_t len = c - l;
    strncpy(buf, l, len);
    buf[len] = '\0';
    return buf;
}

int first_pass(const char *filename, symbol_table_t *table)
{
    FILE *f = fopen(filename, "r");
    if (!f) { perror(filename); return -1; }

    init_symbol_table(table);
    set_global_symtab(table);
    
    section_type_t current = SECTION_UNKNOWN;
    char line[1024];
    char pending[MAX_SYMBOL_NAME] = "";
    int waiting = 0;
    uint32_t pending_addr = 0;

    while (fgets(line, sizeof line, f)) {
        char *clean = trim_whitespace(line);
        char *cmt = strstr(clean, "#");
        if (!cmt) cmt = strstr(clean, "//");
        if (cmt) *cmt = '\0';
        if (!*clean) continue;

        /* -------- cambio de sección -------- */
        if (!strncmp(clean, ".text", 5)) {
            current = SECTION_TEXT;
            pending[0] = 0; 
            waiting = 0;
            continue;
        }
        if (!strncmp(clean, ".data", 5)) {
            current = SECTION_DATA;
            pending[0] = 0; 
            waiting = 0;
            continue;
        }

        /* -------- directiva .eqv -------- */
        if (!strncmp(clean, ".eqv", 4)) {
            char tk[8][MAX_SYMBOL_NAME];
            int nt = split_instruction(clean, tk, 8);
            if (nt >= 3) {
                uint32_t val = (uint32_t)parse_number(tk[2]);
                add_symbol(table, tk[1], val, SECTION_UNKNOWN, val);
            } else {
                fprintf(stderr, "Advertencia: directiva .eqv mal formada: %s\n", clean);
            }
            continue;
        }

        /* -------- línea con etiqueta -------- */
        if (is_label_line(clean)) {
            char label[MAX_SYMBOL_NAME];
            extract_label(clean, label);

            if (current == SECTION_TEXT) {
                add_symbol(table, label, table->text_address, SECTION_TEXT, 0);
            }
            else if (current == SECTION_DATA) {
                strcpy(pending, label);
                waiting = 1;
                pending_addr = table->data_address;
            }

            /* procesar código tras ':' */
            char *after = strchr(clean, ':') + 1;
            after = trim_whitespace(after);
            
            if (*after && current == SECTION_DATA) {
                uint32_t sym_addr = pending_addr;
                int32_t val = 0;
                process_data_directive_ex(table, after, &val);
                add_symbol(table, pending, sym_addr, SECTION_DATA, val);
                pending[0] = 0; 
                waiting = 0;
            }

            /* procesar inline en .text según RARS */
            if (*after && current == SECTION_TEXT) {
                char tk2[8][MAX_SYMBOL_NAME];
                int nt2 = split_instruction(after, tk2, 8);
                if (nt2 > 0) {
                    int real_count2 = 1;
                    char expanded2[8][256];
                    int ec2 = expand_pseudoinstruction(after, expanded2, 8);
                    if (ec2 > 0) real_count2 = ec2;
                    table->text_address += 4 * real_count2;
                }
            }

            continue;
        }

        /* -------- directivas .data -------- */
        if (current == SECTION_DATA && clean[0] == '.') {
            uint32_t sym_addr = pending_addr;
            int32_t val = 0;
            process_data_directive_ex(table, clean, &val);
            
            if (waiting && *pending) {
                add_symbol(table, pending, sym_addr, SECTION_DATA, val);
                pending[0] = 0; 
                waiting = 0;
            }
            continue;
        }

        /* ---- SALTAR directivas en .text que NO emiten código ---- */
        if (current == SECTION_TEXT && clean[0] == '.') {
            if (!strncmp(clean, ".globl", 6)   ||
                !strncmp(clean, ".global", 7)  ||
                !strncmp(clean, ".align", 6)   ||
                !strncmp(clean, ".option", 7)  ||
                !strncmp(clean, ".section", 8)) {
                if (!strncmp(clean, ".align", 6)) {
                    int n = atoi(clean + 6);
                    table->text_address = align_address(table->text_address, 1 << n);
                }
                continue;
            }
        }

        /* =========================================================
         *  INSTRUCCIONES EN LA SECCIÓN .text
         * ========================================================= */
        if (current == SECTION_TEXT) {
            char tk[8][MAX_SYMBOL_NAME];
            int nt = split_instruction(clean, tk, 8);
            if (nt == 0) continue;

            int real_count = 1;
            char expanded[8][256];
            int ec = expand_pseudoinstruction(clean, expanded, 8);
            if (ec > 0) {
                real_count = ec;
            }
            else if ((!strcmp(tk[0], "lw")  || !strcmp(tk[0], "lh") ||
                      !strcmp(tk[0], "lb")  || !strcmp(tk[0], "lhu")||
                      !strcmp(tk[0], "lbu") || !strcmp(tk[0], "sw") ||
                      !strcmp(tk[0], "sh")  || !strcmp(tk[0], "sb")) &&
                      nt >= 3) {
                if (needs_pcrel_expansion(tk[2])) {
                    real_count = 2;
                }
            }
            table->text_address += 4 * real_count;
        }
    }

    fclose(f);
    return 0;
}

/* ================================================================
 *  FUNCIONES DE PROCESAMIENTO DE LÍNEA (.text / .data, comentarios)
 * ================================================================ */

section_type_t get_current_section(const char* line)
{
    if (!line) return SECTION_UNKNOWN;

    char trimmed[256];
    strncpy(trimmed, line, sizeof(trimmed) - 1);
    trimmed[sizeof(trimmed) - 1] = '\0';
    char* clean = trim_whitespace(trimmed);

    if (strstr(clean, ".text")) return SECTION_TEXT;
    if (strstr(clean, ".data")) return SECTION_DATA;
    return SECTION_UNKNOWN;
}

int is_comment_or_empty(const char* line)
{
    if (!line) return 1;

    char trimmed[256];
    strncpy(trimmed, line, sizeof(trimmed) - 1);
    trimmed[sizeof(trimmed) - 1] = '\0';
    char* clean = trim_whitespace(trimmed);

    return (*clean == '\0'           ||
            *clean == '#'            ||
            *clean == ';'            ||
            strncmp(clean, "//", 2) == 0);
}

int is_label(const char *token)
{
    if (!token || !*token) return 0;

    size_t len = strlen(token);
    if (token[len - 1] == ':')
        return 1;

    return strchr(token, ':') != NULL;
}

/* ================================================================
 *  DECODIFICACIÓN DE INSTRUCCIONES                               */
/* ================================================================ */

const instruction_info_t *get_instruction_info(const char *mnem)
{
    for (int i = 0; *instruction_table[i].mnemonic; ++i)
        if (!strcmp(instruction_table[i].mnemonic, mnem))
            return &instruction_table[i];
    return NULL;
}

instruction_type_t classify_instruction(const char *mnemonic)
{
    const instruction_info_t *inf = get_instruction_info(mnemonic);
    return inf ? inf->type : INSTR_TYPE_UNKNOWN;
}

/* --- registros x0..x31 / nombres ABI --- */

static int reg_code(const char *s)
{
    if (s[0] == 'x' && isdigit((unsigned char)s[1]))
        return atoi(s + 1);
    /* alias ABI */
    static const char *abi[32] = {
        "zero","ra","sp","gp","tp","t0","t1","t2",
        "s0","s1","a0","a1","a2","a3","a4","a5",
        "a6","a7","s2","s3","s4","s5","s6","s7",
        "s8","s9","s10","s11","t3","t4","t5","t6"};
    for (int i = 0; i < 32; ++i)
        if (!strcmp(s, abi[i])) return i;
    return -1;
}

int parse_register(const char *str) { return reg_code(str); }

/* --- inmediatos: decimal, hex, símbolo --- */

int parse_immediate_or_symbol(const char *imm,
                              symbol_table_t *tab, uint32_t pc)
{
    if (!imm) return 0;
    
    // Manejar %pcrel_hi y %pcrel_lo
    if (strstr(imm, "%pcrel_hi(")) {
        char label[MAX_SYMBOL_NAME];
        sscanf(imm, "%%pcrel_hi(%[^)])", label);
        uint32_t target;
        if (resolve_symbol(tab, label, &target) == 0) {
            int32_t offset = (int32_t)target - (int32_t)pc;
            int32_t hi = (offset + 0x800) >> 12;
            hi = hi & 0xFFFFF;
            uint32_t hi_addr = pc + ((uint32_t)hi << 12);
            strcpy(pcrel_context.label, label);
            pcrel_context.hi_pc = hi_addr;
            pcrel_context.hi_value = hi;
            return hi;
        }
        return 0;
    }
    
    if (strstr(imm, "%pcrel_lo(")) {
        char label[MAX_SYMBOL_NAME];
        sscanf(imm, "%%pcrel_lo(%[^)])", label);
        if (!strcmp(label, pcrel_context.label)) {
            uint32_t target_addr;
            if (resolve_symbol(tab, label, &target_addr) == 0) {
                int32_t full_offset = (int32_t)target_addr - (int32_t)pcrel_context.hi_pc;
                int32_t lo = full_offset - (pcrel_context.hi_value << 12);
                return lo;
            }
        }
        return 0;
    }
    
    if (imm[0] == '0' && (imm[1] == 'x' || imm[1] == 'X'))
        return strtol(imm, NULL, 16);
    if (isdigit((unsigned char)imm[0]) || imm[0] == '-' || imm[0] == '+')
        return atoi(imm);
    
    /* símbolo */
    uint32_t val;
    if (resolve_symbol(tab, imm, &val) == 0)
        return (int32_t)val;
    fprintf(stderr, "Símbolo no definido: %s\n", imm);
    return 0;
}

/* ================================================================
 *  ENCODERS POR TIPO                                              */
/* ================================================================ */

uint32_t encode_r_type(const r_type_t *i)
{
    return  (i->opcode & 0x7F) |
           ((i->rd     & 0x1F) << 7)  |
           ((i->funct3 & 0x07) << 12) |
           ((i->rs1    & 0x1F) << 15) |
           ((i->rs2    & 0x1F) << 20) |
           ((i->funct7 & 0x7F) << 25);
}

uint32_t encode_i_type(const i_type_t *i)
{
    return  (i->opcode & 0x7F) |
           ((i->rd     & 0x1F) << 7)  |
           ((i->funct3 & 0x07) << 12) |
           ((i->rs1    & 0x1F) << 15) |
           ((i->imm    & 0xFFF) << 20);
}

uint32_t encode_s_type(const s_type_t *i)
{
    uint16_t imm = i->imm & 0xFFF;
    return  (i->opcode & 0x7F) |
           ((imm       & 0x1F) << 7)  |
           ((i->funct3 & 0x07) << 12) |
           ((i->rs1    & 0x1F) << 15) |
           ((i->rs2    & 0x1F) << 20) |
           (((imm >> 5) & 0x7F) << 25);
}

uint32_t encode_b_type(const b_type_t *i)
{
    uint32_t imm = (uint32_t)i->imm;
    return  (i->opcode & 0x7F) |
           (((imm >> 11) & 0x1)  << 7)  |
           (((imm >> 1)  & 0xF)  << 8)  |
           ((i->funct3   & 0x7)  << 12) |
           ((i->rs1      & 0x1F) << 15) |
           ((i->rs2      & 0x1F) << 20) |
           (((imm >> 5)  & 0x3F) << 25) |
           (((imm >> 12) & 0x1)  << 31);
}

uint32_t encode_u_type(const u_type_t *i)
{
    return  (i->opcode & 0x7F)       |
           ((i->rd     & 0x1F) << 7)  |
           ((i->imm    & 0xFFFFF) << 12);
}

uint32_t encode_j_type(const j_type_t *j)
{
    int32_t imm = j->imm;
    uint32_t inst = 0;

    if (imm % 2 != 0) {
        fprintf(stderr, "Offset JAL no alineado: %d\n", imm);
        return 0;
    }

    uint32_t imm_enc = 0;
    imm_enc |= ((imm >> 12) & 0xFF) << 12;
    imm_enc |= ((imm >> 11) & 0x1)  << 20;
    imm_enc |= ((imm >> 1)  & 0x3FF) << 21;
    imm_enc |= ((imm >> 20) & 0x1)  << 31;

    inst |= (j->opcode & 0x7F);
    inst |= (j->rd & 0x1F) << 7;
    inst |= imm_enc;

    return inst;
}

/* ================================================================
 *  ENCODE GENERAL CON TABLA DE SÍMBOLOS                           */
/* ================================================================ */

uint32_t encode_instruction_with_symbols(const char *line,
                                         symbol_table_t *tab,
                                         uint32_t pc)
{
    char tk[8][MAX_SYMBOL_NAME];
    int nt = split_instruction(line, tk, 8);
    if (!nt) return 0;

    const instruction_info_t *info = get_instruction_info(tk[0]);
    if (!info) { 
        fprintf(stderr, "Mnemonico desconocido: %s\n", tk[0]); 
        return 0; 
    }
    
    if (!strcmp(tk[0], "ecall")) {
        return 0x00000073;
    }

    if (!strcmp(tk[0], "ebreak")) {
        return 0x00100073;
    }
    
    // Para SRAI necesitamos manejar el bit 30 especial
    if (!strcmp(tk[0], "srai") && info->type == INSTR_TYPE_I) {
        if (nt < 4) { 
            fprintf(stderr,"srai req rd,rs1,shamt\n"); 
            return 0; 
        }
        int shamt = parse_immediate_or_symbol(tk[3], tab, pc) & 0x1F;
        i_type_t i = {
            info->opcode,
            (uint8_t)parse_register(tk[1]),
            info->funct3,
            (uint8_t)parse_register(tk[2]),
            (int16_t)(0x400 | shamt)  // Bit 30 = 1 para SRAI
        };
        return encode_i_type(&i);
    }

    switch (info->type) {
        case INSTR_TYPE_R: {
            if (nt < 4) { 
                fprintf(stderr,"R req 3 op\n"); 
                return 0; 
            }
            r_type_t r = {
                info->opcode, 
                (uint8_t)parse_register(tk[1]),
                info->funct3, 
                (uint8_t)parse_register(tk[2]),
                (uint8_t)parse_register(tk[3]), 
                info->funct7
            };
            return encode_r_type(&r);
        }

        case INSTR_TYPE_I: {
            /* Instrucciones de carga (LOAD) */
            if (info->opcode == OPCODE_LOAD) {
                if (nt < 3) { 
                    fprintf(stderr, "load req rd,imm(rs1)\n"); 
                    return 0; 
                }

                char *p = strrchr(tk[2], '(');
                if (!p) { 
                    fprintf(stderr, "fmt load\n"); 
                    return 0; 
                }
                *p = '\0';

                char *regp = strrchr(p + 1, ')');
                if (!regp) { 
                    fprintf(stderr, "fmt load\n"); 
                    return 0; 
                }
                *regp = '\0';

                i_type_t i = {
                    info->opcode,
                    (uint8_t)parse_register(tk[1]),
                    info->funct3,
                    (uint8_t)parse_register(p + 1),
                    (int16_t)parse_immediate_or_symbol(tk[2], tab, pc)
                };
                return encode_i_type(&i);
            }

            /* Resto de instrucciones tipo-I */
            if (nt < 4) { 
                fprintf(stderr, "I req rd,rs1,imm\n"); 
                return 0; 
            }

            i_type_t i = {
                info->opcode,
                (uint8_t)parse_register(tk[1]),
                info->funct3,
                (uint8_t)parse_register(tk[2]),
                (int16_t)parse_immediate_or_symbol(tk[3], tab, pc)
            };
            return encode_i_type(&i);
        }

        case INSTR_TYPE_S: {
            if (nt < 3) { 
                fprintf(stderr,"S req rs2,imm(rs1)\n"); 
                return 0; 
            }
        
            char *p = strrchr(tk[2], '(');
            if (!p) { 
                fprintf(stderr,"fmt store\n"); 
                return 0; 
            }
        
            *p = 0;
            char *regp = strrchr(p + 1, ')');
            if (!regp) { 
                fprintf(stderr,"fmt store\n"); 
                return 0; 
            }
            *regp = 0;

            s_type_t s = { 
                info->opcode, 
                info->funct3,
                (uint8_t)parse_register(p + 1),
                (uint8_t)parse_register(tk[1]),
                (int16_t)parse_immediate_or_symbol(tk[2], tab, pc) 
            };
            return encode_s_type(&s);
        }

        case INSTR_TYPE_B: {
            if (nt < 4){
                fprintf(stderr,"B req rs1,rs2,label\n");
                return 0;
            }
            int32_t offset = parse_immediate_or_symbol(tk[3],tab,pc) - (int32_t)pc;
            b_type_t b = {
                info->opcode, 
                info->funct3,
                (uint8_t)parse_register(tk[1]),
                (uint8_t)parse_register(tk[2]),
                (int16_t)offset
            };
            return encode_b_type(&b);
        }

        case INSTR_TYPE_U: {
            if (nt < 3){
                fprintf(stderr,"U req rd,imm\n");
                return 0;
            }
            int32_t imm_val = parse_immediate_or_symbol(tk[2],tab,pc);
            u_type_t u = {
                info->opcode, 
                (uint8_t)parse_register(tk[1]), 
                imm_val
            };
            return encode_u_type(&u);
        }

        case INSTR_TYPE_J: {
            uint32_t target;
            int rd;
            
            if (nt == 2) {
                rd = 1;
                target = parse_immediate_or_symbol(tk[1], tab, pc);
            } else {
                rd = parse_register(tk[1]);
                target = parse_immediate_or_symbol(tk[2], tab, pc);
            }
            
            int32_t off = (int32_t)target - (int32_t)pc;
            j_type_t j = { info->opcode, (uint8_t)rd, off };
            return encode_j_type(&j);
        }

        default:
            fprintf(stderr,"Tipo no implementado\n"); 
            return 0;
    }
}

/* ================================================================
 *  DEBUG: imprimir binario                                        */
/* ================================================================ */

void print_binary_instruction(uint32_t x)
{
    for (int i = 31; i >= 0; --i) {
        putchar((x >> i) & 1 ? '1' : '0');
        if (!(i % 4) && i) putchar(' ');
    }
    putchar('\n');
}

/* ================================================================
 *  PSEUDOINSTRUCCIONES MEJORADAS                                  */
/* ================================================================ */

static int32_t str_to_imm(const char *s)
{
    return (int32_t)strtol(s, NULL, 0);
}

int is_pseudoinstruction(const char *m)
{
    /* Pseudos "clásicos" */
    if (!strcmp(m,"li")   || !strcmp(m,"la")   || !strcmp(m,"mv")  ||
        !strcmp(m,"nop")  || !strcmp(m,"j")    || !strcmp(m,"jr")  || 
        !strcmp(m,"ret")  || !strcmp(m,"call") || !strcmp(m,"tail") ||
        !strcmp(m,"bnez") || !strcmp(m,"beqz") || !strcmp(m,"blez") ||
        !strcmp(m,"bgez") || !strcmp(m,"bgtz") || !strcmp(m,"bltz") || 
        !strcmp(m,"bgt")  || !strcmp(m,"not")  || !strcmp(m,"ble"))
        return 1;

    /* Pseudos de carga/almacenamiento PC-relativos */
    if (!strcmp(m,"lw") || !strcmp(m,"sw") || 
        !strcmp(m,"lb") || !strcmp(m,"lh") || !strcmp(m,"lbu") || !strcmp(m,"lhu") ||
        !strcmp(m,"sb") || !strcmp(m,"sh"))
        return 1;

    return 0;
}

int expand_pseudoinstruction(const char *line,
                             char expanded[][256],
                             int  max_exp)
{
    (void)max_exp;
    char tok[8][MAX_SYMBOL_NAME];
    int  n = split_instruction(line, tok, 8);
    if (n == 0) return 0;

    /* PSEUDOS DE CARGA: LW/LH/LB/LHU/LBU */
    if (( !strcmp(tok[0],"lw")  || !strcmp(tok[0],"lh") ||
          !strcmp(tok[0],"lb")  || !strcmp(tok[0],"lhu")||
          !strcmp(tok[0],"lbu") ) && n >= 3)
    {
        if (strchr(tok[2], '(') == NULL)
        {
            symbol_t *sym = NULL;
            uint32_t addr = 0;
            if (global_symtab && resolve_symbol(global_symtab, tok[2], &addr) == 0)
                sym = find_symbol(global_symtab, tok[2]);
            int is_data_label = (sym && sym->section == SECTION_DATA);

            if (is_data_label) {
                snprintf(expanded[0], 256,
                         "auipc %s, %%pcrel_hi(%s)",
                         tok[1], tok[2]);
                snprintf(expanded[1], 256,
                         "%s %s, %%pcrel_lo(%s)(%s)",
                         tok[0], tok[1], tok[2], tok[1]);
            } else {
                uint32_t hi = (addr + 0x800) >> 12;
                int32_t  lo = (int32_t)addr - ((int32_t)hi << 12);
                snprintf(expanded[0], 256,
                         "lui %s, 0x%X",
                         tok[1], hi);
                snprintf(expanded[1], 256,
                         "%s %s, %d(%s)",
                         tok[0], tok[1], lo, tok[1]);
            }
            return 2;
        }
        return 0;
    }

    /* SW/SH/SB con símbolo */
    if ((!strcmp(tok[0],"sw") || !strcmp(tok[0],"sh") || !strcmp(tok[0],"sb")) && n >= 3)
    {
        symbol_t *sym = NULL;
        uint32_t addr;
        if (global_symtab && resolve_symbol(global_symtab, tok[2], &addr)==0)
            sym = find_symbol(global_symtab, tok[2]);

        int is_data_label = (sym && sym->section == SECTION_DATA);

        if (n == 4 && strchr(tok[2], '(') == NULL)
        {
            if (is_data_label) {
                snprintf(expanded[0],256,
                         "auipc %s, %%pcrel_hi(%s)",
                         tok[3], tok[2]);
                snprintf(expanded[1],256,
                         "%s %s, %%pcrel_lo(%s)(%s)",
                         tok[0], tok[1], tok[2], tok[3]);
            } else {
                uint32_t hi = (addr + 0x800) >> 12;
                int32_t  lo = (int32_t)addr - ((int32_t)hi << 12);
                snprintf(expanded[0],256,
                         "lui %s, 0x%X",
                         tok[3], hi);
                snprintf(expanded[1],256,
                         "%s %s, %d(%s)",
                         tok[0], tok[1], lo, tok[3]);
            }
            return 2;
        }
        else if (n == 3 && strchr(tok[2], '(') == NULL)
        {
            if (is_data_label) {
                snprintf(expanded[0],256,
                         "auipc t6, %%pcrel_hi(%s)",
                         tok[2]);
                snprintf(expanded[1],256,
                         "%s %s, %%pcrel_lo(%s)(t6)",
                         tok[0], tok[1], tok[2]);
            } else {
                uint32_t hi = (addr + 0x800) >> 12;
                int32_t  lo = (int32_t)addr - ((int32_t)hi << 12);
                snprintf(expanded[0],256,
                         "lui t6, 0x%X", hi);
                snprintf(expanded[1],256,
                         "%s %s, %d(t6)",
                         tok[0], tok[1], lo);
            }
            return 2;
        }
        return 0;
    }

    /* li rd, imm_or_symbol */
    if (!strcmp(tok[0],"li") && n >= 3)
    {
        int32_t imm;
        uint32_t symval;
        if (global_symtab && resolve_symbol(global_symtab, tok[2], &symval) == 0) {
            imm = (int32_t)symval;
        } else {
            imm = str_to_imm(tok[2]);
        }

        if (imm >= -2048 && imm <= 2047)
        {
            snprintf(expanded[0],256,"addi %s, x0, %d", tok[1], imm);
            return 1;
        }
        int32_t hi = ((imm + 0x800) >> 12) & 0xFFFFF;
        int32_t lo = imm - (hi << 12);
        snprintf(expanded[0],256,"lui %s, 0x%X",    tok[1], hi);
        snprintf(expanded[1],256,"addi %s, %s, %d", tok[1], tok[1], lo);
        return 2;
    }

    /* la rd, symbol */
    if (!strcmp(tok[0],"la") && n >= 3)
    {
        snprintf(expanded[0],256,"auipc %s, %%pcrel_hi(%s)",
                 tok[1], tok[2]);
        snprintf(expanded[1],256,"addi %s, %s, %%pcrel_lo(%s)",
                 tok[1], tok[1], tok[2]);
        return 2;
    }

    /* mv rd, rs */
    if (!strcmp(tok[0],"mv") && n >= 3)
    {
        snprintf(expanded[0],256,"add %s, x0 , %s", tok[1], tok[2]);
        return 1;
    }

    /* nop */
    if (!strcmp(tok[0],"nop"))
    {
        snprintf(expanded[0],256,"addi x0, x0, 0");
        return 1;
    }

    /* j label */
    if (!strcmp(tok[0],"j") && n >= 2)
    {
        snprintf(expanded[0],256,"jal x0, %s", tok[1]);
        return 1;
    }

    /* jal label (sin rd explícito) */
    if (!strcmp(tok[0],"jal") && n == 2)
    {
        snprintf(expanded[0],256,"jal x1, %s", tok[1]);
        return 1;
    }

    /* jr rs */
    if (!strcmp(tok[0],"jr") && n >= 2)
    {
        snprintf(expanded[0],256,"jalr x0, %s, 0", tok[1]);
        return 1;
    }

    /* ret */
    if (!strcmp(tok[0],"ret"))
    {
        snprintf(expanded[0],256,"jalr x0, x1, 0");
        return 1;
    }

    /* call / tail */
    if (!strcmp(tok[0],"call") && n >= 2)
    {
        snprintf(expanded[0],256,"auipc x1, %%pcrel_hi(%s)", tok[1]);
        snprintf(expanded[1],256,"jalr x1, x1, %%pcrel_lo(%s)", tok[1]);
        return 2;
    }
    
    if (!strcmp(tok[0],"tail") && n >= 2)
    {
        snprintf(expanded[0],256,"auipc x6, %%pcrel_hi(%s)", tok[1]);
        snprintf(expanded[1],256,"jalr x0, x6, %%pcrel_lo(%s)", tok[1]);
        return 2;
    }

    /* not rd, rs → xori rd, rs, -1 */
    if (!strcmp(tok[0],"not") && n >= 3) {
        snprintf(expanded[0],256,"xori %s, %s, -1",
                 tok[1], tok[2]);
        return 1;
    }

    /* ramas contra cero */
    if (!strcmp(tok[0],"bnez") && n >= 3)
    {   snprintf(expanded[0],256,"bne %s, x0, %s", tok[1], tok[2]); return 1; }

    if (!strcmp(tok[0],"beqz") && n >= 3)
    {   snprintf(expanded[0],256,"beq %s, x0, %s", tok[1], tok[2]); return 1; }

    if (!strcmp(tok[0],"blez") && n >= 3)
    {   snprintf(expanded[0],256,"bge x0, %s, %s", tok[1], tok[2]); return 1; }

    if (!strcmp(tok[0],"bgez") && n >= 3)
    {   snprintf(expanded[0],256,"bge %s, x0, %s", tok[1], tok[2]); return 1; }

    if (!strcmp(tok[0],"bgtz") && n >= 3)
    {   snprintf(expanded[0],256,"blt x0, %s, %s", tok[1], tok[2]); return 1; }

    if (!strcmp(tok[0],"bltz") && n >= 3)
    {   snprintf(expanded[0],256,"blt %s, x0, %s", tok[1], tok[2]); return 1; }

    /* bgt rs1, rs2, etiqueta */
    if (!strcmp(tok[0],"bgt") && n >= 4)
    {
        snprintf(expanded[0],256,
                 "blt %s, %s, %s",
                 tok[2], tok[1], tok[3]);
        return 1;
    }

    /* ble rs1, rs2, etiqueta → bge rs2, rs1, etiqueta */
    if (!strcmp(tok[0], "ble") && n >= 4) {
        snprintf(expanded[0], 256,
                "bge %s, %s, %s",
                tok[2], tok[1], tok[3]);
        return 1;
    }

    return 0;
}