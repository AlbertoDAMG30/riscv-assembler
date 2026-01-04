#include <SDL2/SDL.h>
#include <SDL2/SDL_ttf.h>
#include "tinyfiledialogs.h"
#include "encoder.h"
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <stdlib.h>
#include <strings.h>
#include <ctype.h>

// Variables externas de tinyfiledialogs
extern int tinyfd_forceConsole;
extern int tinyfd_silent;

#define WIDTH 640
#define HEIGHT 600

// Estructura para pasar datos al thread
typedef struct {
    char archivoSeleccionado[1024];
    char archivoNombre[256];
    int fileDialogComplete;
    int fileDialogResult;
} FileDialogData;

// Estructura para pasar datos al thread de mensaje
typedef struct {
    char title[256];
    char message[4096];
    char type[32];
    char iconType[32];
    int defaultButton;
} MessageBoxData;

// Función del thread para abrir el diálogo de archivo
void* openFileDialogThread(void* arg) {
    FileDialogData* data = (FileDialogData*)arg;
    
    const char *filtro[] = { "*.s" };
    const char *archivo = tinyfd_openFileDialog("Seleccionar archivo .s", "", 1, filtro, "Archivos RISC-V", 0);
    
    if (archivo) {
        strcpy(data->archivoSeleccionado, archivo);
        const char *nombreSimple = strrchr(archivo, '/');
        const char *nombreWin = strrchr(archivo, '\\');
        if (!nombreSimple || (nombreWin && nombreWin > nombreSimple)) nombreSimple = nombreWin;
        if (!nombreSimple) nombreSimple = archivo;
        else nombreSimple++;
        strncpy(data->archivoNombre, nombreSimple, sizeof(data->archivoNombre));
        data->archivoNombre[sizeof(data->archivoNombre) - 1] = '\0';
        data->fileDialogResult = 1;
    } else {
        data->fileDialogResult = 0;
    }
    
    data->fileDialogComplete = 1;
    return NULL;
}

// Función del thread para mostrar message box
void* messageBoxThread(void* arg) {
    MessageBoxData* data = (MessageBoxData*)arg;
    tinyfd_messageBox(data->title, data->message, data->type, data->iconType, data->defaultButton);
    free(data);
    return NULL;
}

// Función auxiliar para mostrar message box en un thread
void showMessageBoxThreaded(const char* title, const char* message, const char* type, const char* iconType, int defaultButton) {
    MessageBoxData* data = (MessageBoxData*)malloc(sizeof(MessageBoxData));
    strncpy(data->title, title, sizeof(data->title) - 1);
    data->title[sizeof(data->title) - 1] = '\0';
    strncpy(data->message, message, sizeof(data->message) - 1);
    data->message[sizeof(data->message) - 1] = '\0';
    strncpy(data->type, type, sizeof(data->type) - 1);
    data->type[sizeof(data->type) - 1] = '\0';
    strncpy(data->iconType, iconType, sizeof(data->iconType) - 1);
    data->iconType[sizeof(data->iconType) - 1] = '\0';
    data->defaultButton = defaultButton;
    
    pthread_t msgThread;
    pthread_create(&msgThread, NULL, messageBoxThread, data);
    pthread_detach(msgThread);
}

// Función mejorada para extraer solo el código máquina
static void strip_machine_code(const char *inpath, const char *outpath) {
    FILE *fi = fopen(inpath, "r");
    FILE *fo = fopen(outpath, "w");
    if (!fi || !fo) {
        if (fi) fclose(fi);
        if (fo) fclose(fo);
        return;
    }
    
    char line[1024];
    int line_count = 0;
    
    printf("DEBUG STRIP: Iniciando extracción de código máquina\n");
    
    while (fgets(line, sizeof(line), fi)) {
        char *p = line;
        
        // Saltar líneas que empiecen con # (comentarios)
        while (*p == ' ' || *p == '\t') p++; // Skip leading whitespace
        if (*p == '#') continue;
        
        // Para .text: buscar el patrón "0x........: "
        char *colon = strstr(line, ": ");
        if (colon) {
            // Verificar que antes del colon hay una dirección válida (0x seguido de 8 hex digits)
            char *addr_start = colon - 8;
            if (addr_start >= line && addr_start >= line + 2 && 
                *(addr_start - 2) == '0' && *(addr_start - 1) == 'x') {
                
                p = colon + 2;
                
                // Verificar si es hexadecimal (empieza con 0x en .text)
                if (strncmp(p, "0x", 2) == 0) {
                    // Es hexadecimal en .text, copiar los próximos 8 caracteres hex
                    char hex_value[9];
                    strncpy(hex_value, p + 2, 8);
                    hex_value[8] = '\0';
                    // Convertir a minúsculas si es necesario
                    for (int i = 0; i < 8; i++) {
                        hex_value[i] = tolower(hex_value[i]);
                    }
                    fprintf(fo, "%s\n", hex_value);
                    line_count++;
                } else {
                    // Es binario
                    char binary_part[256] = {0};
                    int j = 0;
                    
                    while (*p && *p != '#' && j < 255) {
                        if (*p == '0' || *p == '1') {
                            binary_part[j++] = *p;
                        }
                        p++;
                    }
                    
                    if (j == 32) {
                        binary_part[j] = '\0';
                        fprintf(fo, "%s\n", binary_part);
                        line_count++;
                    }
                }
            }
        } else {
            // Para .data: solo procesar si NO es comentario y es formato válido
            if (*p != '#' && *p != '\0' && *p != '\n' && *p != '\r') {
                int is_hex = 1;
                int hex_count = 0;
                for (char *scan = p; *scan && *scan != '\n' && *scan != '\r'; scan++) {
                    if ((*scan >= '0' && *scan <= '9') || 
                        (*scan >= 'a' && *scan <= 'f') || 
                        (*scan >= 'A' && *scan <= 'F')) {
                        hex_count++;
                    } else if (!isspace(*scan)) {
                        is_hex = 0;
                        break;
                    }
                }
                
                if (is_hex && hex_count == 8) {
                    // Es hexadecimal (8 dígitos)
                    char hex_value[9];
                    int j = 0;
                    for (char *scan = p; *scan && j < 8; scan++) {
                        if ((*scan >= '0' && *scan <= '9') || 
                            (*scan >= 'a' && *scan <= 'f') || 
                            (*scan >= 'A' && *scan <= 'F')) {
                            hex_value[j++] = tolower(*scan);
                        }
                    }
                    hex_value[j] = '\0';
                    fprintf(fo, "%s\n", hex_value);
                    line_count++;
                    
                    // REMOVIDO: Ya no limitar a 1024 líneas para .data
                    // El límite ahora se maneja dinámicamente en la generación principal
                } else {
                    // Verificar si es binario
                    int valid = 1;
                    int digit_count = 0;
                    
                    // Contar solo 0s y 1s
                    for (char *scan = p; *scan; scan++) {
                        if (*scan == '0' || *scan == '1') {
                            digit_count++;
                        } else if (!isspace(*scan)) {
                            valid = 0;
                            break;
                        }
                    }
                    
                    // Solo escribir si hay exactamente 32 dígitos binarios
                    if (valid && digit_count == 32) {
                        // Escribir solo los dígitos binarios
                        for (char *scan = p; *scan; scan++) {
                            if (*scan == '0' || *scan == '1') {
                                fputc(*scan, fo);
                            }
                        }
                        fputc('\n', fo);
                        line_count++;
                        
                        // REMOVIDO: Ya no limitar a 1024 líneas para .data
                        // El límite ahora se maneja dinámicamente en la generación principal
                    }
                }
            }
        }
    }
    
    printf("DEBUG STRIP: Extracción completada, %d líneas procesadas\n", line_count);
    
    fclose(fi);
    fclose(fo);
}

void debug_memory_dump_info(uint32_t pc, uint32_t base_address, int instrucciones_procesadas) {
    uint32_t bytes_generados = pc - base_address;
    uint32_t palabras_usadas = (bytes_generados + 3) / 4;
    
    printf("=== DEBUG VOLCADO DE MEMORIA ===\n");
    printf("PC actual: 0x%08X\n", pc);
    printf("Dirección base: 0x%08X\n", base_address);
    printf("Bytes generados: %u\n", bytes_generados);
    printf("Palabras usadas: %u\n", palabras_usadas);
    printf("Instrucciones procesadas: %d\n", instrucciones_procesadas);
    
    uint32_t volcado_size;
    if (palabras_usadas <= 1024) volcado_size = 1024;
    else if (palabras_usadas <= 2048) volcado_size = 2048;
    else if (palabras_usadas <= 3072) volcado_size = 3072;
    else if (palabras_usadas <= 4096) volcado_size = 4096;
    else volcado_size = ((palabras_usadas + 1023) / 1024) * 1024;
    
    printf("Tamaño de volcado calculado: %u palabras\n", volcado_size);
    printf("==============================\n");
}

// Función para convertir uint32_t a string binario
void uint32_to_binary_string(uint32_t value, char* binary_str) {
    for (int i = 31; i >= 0; i--) {
        binary_str[31-i] = ((value >> i) & 1) ? '1' : '0';
    }
    binary_str[32] = '\0';
}

// Función para formatear binario con espacios cada 4 bits
void format_binary_with_spaces(const char* binary, char* formatted) {
    int j = 0;
    for (int i = 0; i < 32; i++) {
        formatted[j++] = binary[i];
        if ((i + 1) % 4 == 0 && i < 31) {
            formatted[j++] = ' ';
        }
    }
    formatted[j] = '\0';
}

void debug_escape_sequence(const char* input, char actual_char, uint8_t value) {
    printf("DEBUG ESCAPE: Input='%s' -> Char='%c' -> Value=0x%02X (%d)\n", 
           input, actual_char, value, value);
}

int main(void) {
    // Configurar tinyfiledialogs para evitar problemas con SDL
    tinyfd_forceConsole = 0;
    tinyfd_silent = 1;
    
    SDL_Init(SDL_INIT_VIDEO);
    TTF_Init();

    SDL_Window *window = SDL_CreateWindow("Ensamblador RISC-V",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);

    TTF_Font *font = TTF_OpenFont("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf", 20);
    if (!font) {
        font = TTF_OpenFont("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 20);
    }
    
    SDL_Color white = {255, 255, 255, 255};

    SDL_Rect seccionBox = {80, 90, 480, 40};
    SDL_Rect formatoBox = {80, 230, 480, 40};
    SDL_Rect fileBtn = {80, 360, 480, 50};
    SDL_Rect processBtn = {WIDTH / 2 - 100, 450, 200, 50};

    SDL_Rect seccionOpciones[2] = {{80, 130, 480, 30}, {80, 160, 480, 30}};
    SDL_Rect formatoOpciones[2] = {{80, 270, 480, 30}, {80, 300, 480, 30}};

    int running = 1;
    SDL_Event e;
    int seccion = -1;
    int formato = -1;
    int showSeccionMenu = 0;
    int showFormatoMenu = 0;

    // Datos para el diálogo de archivo
    FileDialogData fileData;
    strcpy(fileData.archivoSeleccionado, "");
    strcpy(fileData.archivoNombre, "Seleccionar archivo");
    fileData.fileDialogComplete = 0;
    fileData.fileDialogResult = 0;
    pthread_t fileDialogThread;
    int fileDialogThreadRunning = 0;

    while (running) {
        // Verificar si el thread del diálogo ha terminado
        if (fileDialogThreadRunning && fileData.fileDialogComplete) {
            pthread_join(fileDialogThread, NULL);
            fileDialogThreadRunning = 0;
            fileData.fileDialogComplete = 0;
        }

        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) running = 0;
            if (e.type == SDL_MOUSEBUTTONDOWN) {
                int x = e.button.x;
                int y = e.button.y;

                if (x >= seccionBox.x && x <= seccionBox.x + seccionBox.w && 
                    y >= seccionBox.y && y <= seccionBox.y + seccionBox.h) {
                    showSeccionMenu = !showSeccionMenu;
                    showFormatoMenu = 0;
                } else if (showSeccionMenu) {
                    for (int i = 0; i < 2; i++) {
                        SDL_Rect r = seccionOpciones[i];
                        if (x >= r.x && x <= r.x + r.w && y >= r.y && y <= r.y + r.h) {
                            seccion = i;
                            showSeccionMenu = 0;
                        }
                    }
                }

                if (x >= formatoBox.x && x <= formatoBox.x + formatoBox.w && 
                    y >= formatoBox.y && y <= formatoBox.y + formatoBox.h) {
                    showFormatoMenu = !showFormatoMenu;
                    showSeccionMenu = 0;
                } else if (showFormatoMenu) {
                    for (int i = 0; i < 2; i++) {
                        SDL_Rect r = formatoOpciones[i];
                        if (x >= r.x && x <= r.x + r.w && y >= r.y && y <= r.y + r.h) {
                            formato = i;
                            showFormatoMenu = 0;
                        }
                    }
                }

                // Manejo del botón de archivo con thread
                if (x >= fileBtn.x && x <= fileBtn.x + fileBtn.w && 
                    y >= fileBtn.y && y <= fileBtn.y + fileBtn.h) {
                    if (!fileDialogThreadRunning) {
                        fileData.fileDialogComplete = 0;
                        fileData.fileDialogResult = 0;
                        pthread_create(&fileDialogThread, NULL, openFileDialogThread, &fileData);
                        fileDialogThreadRunning = 1;
                    }
                }

                if (x >= processBtn.x && x <= processBtn.x + processBtn.w && 
                    y >= processBtn.y && y <= processBtn.y + processBtn.h) {
                    // Verificar que todo esté seleccionado
                    if (fileData.archivoSeleccionado[0] != '\0' && seccion != -1 && formato != -1) {
                        
                        // ===== PRIMERA PASADA: Construir tabla de símbolos =====
                        symbol_table_t symbol_table;
                        printf("\n========================================\n");
                        printf("INICIANDO PROCESAMIENTO DEL ARCHIVO: %s\n", fileData.archivoSeleccionado);
                        printf("========================================\n");
                        
                        if (first_pass(fileData.archivoSeleccionado, &symbol_table) != 0) {
                            showMessageBoxThreaded("Error", "Error en la primera pasada del ensamblador", "ok", "error", 1);
                            continue;
                        }
                        set_global_symtab(&symbol_table);
                        // ===== SEGUNDA PASADA: Generar código máquina =====
                        FILE *file = fopen(fileData.archivoSeleccionado, "r");
                        if (!file) {
                            printf("No se pudo abrir el archivo\n");
                            showMessageBoxThreaded("Error", "No se pudo abrir el archivo seleccionado", "ok", "error", 1);
                            continue;
                        }
                        
                        // Crear nombre del archivo de salida
                        char archivoSalida[1024];
                        const char *nombreSimple = strrchr(fileData.archivoSeleccionado, '/');
                        const char *nombreWin = strrchr(fileData.archivoSeleccionado, '\\');
                        if (!nombreSimple || (nombreWin && nombreWin > nombreSimple)) nombreSimple = nombreWin;
                        if (!nombreSimple) nombreSimple = fileData.archivoSeleccionado;
                        else nombreSimple++;

                        // Generar nombre según sección y formato seleccionados
                        const char* nombreSeccion = (seccion == 0) ? "text" : "data";
                        const char* nombreFormato = (formato == 0) ? "hex" : "bin";
                        
                        const char *punto = strrchr(nombreSimple, '.');
                        size_t nombreLen = punto ? (size_t)(punto - nombreSimple) : strlen(nombreSimple);

                        snprintf(archivoSalida, sizeof(archivoSalida), "%.*s_%s_%s.txt",
                                (int)nombreLen, nombreSimple, nombreSeccion, nombreFormato);

                        FILE *out = fopen(archivoSalida, "w");
                        if (!out) {
                            printf("No se pudo crear el archivo de salida\n");
                            showMessageBoxThreaded("Error", "No se pudo crear el archivo de salida", "ok", "error", 1);
                            fclose(file);
                            continue;
                        }
                        
                        printf("\n=== SEGUNDA PASADA: Generando código máquina ===\n");
                        printf("Sección seleccionada: %s (seccion = %d)\n", 
                            (seccion == 0) ? ".text" : ".data", seccion);
                        
                        char linea[1024];
                        section_type_t current_section = SECTION_UNKNOWN;
                        int enSeccion = 0;
                        uint32_t pc = (seccion == 0) ? TEXT_BASE_ADDRESS : DATA_BASE_ADDRESS;
                        int instruccionesProcesadas = 0;
                        int errores = 0;
                        data_word_t current_word = {0};
                        current_word.address = DATA_BASE_ADDRESS;

                        // Escribir encabezado del archivo
                        fprintf(out, "# Código máquina generado por Ensamblador RISC-V\n");
                        fprintf(out, "# Archivo fuente: %s\n", nombreSimple);
                        fprintf(out, "# Sección: %s\n", nombreSeccion);
                        fprintf(out, "# Formato: %s\n", nombreFormato);
                        fprintf(out, "# ================================================\n");
                        
                        // Imprimir tabla de símbolos en el archivo
                        fprintf(out, "# TABLA DE SÍMBOLOS:\n");
                        for (int i = 0; i < symbol_table.count; i++) {
                            symbol_t* sym = &symbol_table.symbols[i];
                            const char *sec =
                                sym->section == SECTION_TEXT ? ".text" :
                                sym->section == SECTION_DATA ? ".data" : ".eqv";
                            fprintf(out, "# %-20s 0x%08X (%s)\n", 
                                sym->name, sym->address, sec);
                        }
                        fprintf(out, "# ================================================\n\n");

                        printf("========================================\n");
                        printf("ARCHIVO A PROCESAR: %s\n", fileData.archivoSeleccionado);
                        printf("========================================\n");

                        while (fgets(linea, sizeof(linea), file)) {
                            // Crear copias completamente independientes de la línea
                            char linea_original[2048];
                            char linea_limpia[2048];
                            
                            // Copiar la línea original
                            strncpy(linea_original, linea, sizeof(linea_original) - 1);
                            linea_original[sizeof(linea_original) - 1] = '\0';
                            
                            // Trabajar con una copia para limpieza
                            strncpy(linea_limpia, linea_original, sizeof(linea_limpia) - 1);
                            linea_limpia[sizeof(linea_limpia) - 1] = '\0';
                            
                            // Procesar comentarios en la copia limpia
                            char* comentario = strstr(linea_limpia, "#");
                            if (!comentario) comentario = strstr(linea_limpia, "//");
                            if (comentario) *comentario = '\0';
                            
                            // Reemplazar tabs por espacios
                            for (int i = 0; linea_limpia[i]; i++) {
                                if (linea_limpia[i] == '\t') linea_limpia[i] = ' ';
                            }
                            
                            // Remover newlines
                            linea_limpia[strcspn(linea_limpia, "\r\n")] = '\0';
                            
                            // Trim espacios
                            char *inicio = linea_limpia;
                            while (*inicio == ' ') inicio++;
                            char *fin = inicio + strlen(inicio) - 1;
                            while (fin > inicio && *fin == ' ') *fin-- = '\0';
                            
                            // Saltar líneas vacías
                            if (*inicio == '\0') continue;
                            
                            // Detectar cambio de sección
                            if (strstr(inicio, ".text") || strstr(inicio, ".TEXT")) {
                                // Solo cambiar a .text si el usuario seleccionó .text
                                if (seccion == 0) {
                                    current_section = SECTION_TEXT;
                                    enSeccion = 1;
                                    pc = TEXT_BASE_ADDRESS;
                                }
                                continue;
                            }
                        
                            if (strstr(inicio, ".data") || strstr(inicio, ".DATA")) {
                                // Solo cambiar a .data si el usuario seleccionó .data
                                if (seccion == 1) {
                                    current_section = SECTION_DATA;
                                    enSeccion = 1;
                                    pc = DATA_BASE_ADDRESS;
                                }
                                continue;
                            }
                            
                            // Solo procesar si estamos en la sección correcta
                            if (!enSeccion) continue;
                            
                            // Si es una etiqueta, procesamos lo que viene después si existe
                            if (strchr(inicio, ':') != NULL) {
                                char *after_colon = strchr(inicio, ':') + 1;
                                after_colon = trim_whitespace(after_colon);
                                
                                if (*after_colon) {
                                    strcpy(inicio, after_colon);
                                } else {
                                    continue;
                                }
                            }
                            
                            // PROCESAR DIRECTIVAS .DATA
                            if (current_section == SECTION_DATA) {
                                
                                // Saltar directivas no relacionadas con datos
                                if (strncmp(inicio, ".global", 7) == 0 || strncmp(inicio, ".globl", 6) == 0) {
                                    continue;
                                }
                                
                                // Para directivas .string/.ascii/.asciiz/.asciz, usar la línea original
                                if (strstr(inicio, ".string") || strstr(inicio, ".asciiz") || 
                                    strstr(inicio, ".asciz") || strstr(inicio, ".ascii")) {
                                    
                                    // Buscar la posición de la directiva en la línea original
                                    char *directive_pos = strstr(linea_original, ".string");
                                    if (!directive_pos) directive_pos = strstr(linea_original, ".asciiz");
                                    if (!directive_pos) directive_pos = strstr(linea_original, ".asciz");
                                    if (!directive_pos) directive_pos = strstr(linea_original, ".ascii");
                                    
                                    if (directive_pos) {
                                        // Procesar usando la línea original desde la directiva
                                        char temp_line[2048];
                                        strncpy(temp_line, directive_pos, sizeof(temp_line) - 1);
                                        temp_line[sizeof(temp_line) - 1] = '\0';
                                        
                                        // Limpiar comentarios de temp_line
                                        char *comment = strstr(temp_line, "#");
                                        if (!comment) comment = strstr(temp_line, "//");
                                        if (comment) *comment = '\0';
                                        
                                        // Trim
                                        char *trimmed = trim_whitespace(temp_line);
                                        
                                        // Ahora procesar la directiva con el contenido correcto
                                        char tokens[8][MAX_SYMBOL_NAME];
                                        int token_count = split_instruction(trimmed, tokens, 8);
                                        
                                        if (token_count > 0) {
                                            if (strcmp(tokens[0], ".string") == 0 || 
                                                strcmp(tokens[0], ".asciiz") == 0 ||
                                                strcmp(tokens[0], ".asciz") == 0) {
                                                
                                                printf("DEBUG: Procesando directiva %s\n", tokens[0]);
                                                printf("DEBUG: Línea completa: %s\n", trimmed);
                                                
                                                char* start = strchr(trimmed, '"');
                                                char* end = strrchr(trimmed, '"');
                                                if (start && end && start != end) {
                                                    start++; // Saltar comilla inicial
                                                    
                                                    printf("DEBUG: String contenido entre comillas: '%.*s'\n", 
                                                           (int)(end - start), start);
                                                    
                                                    // Crear comentario
                                                    char comment[256];
                                                    snprintf(comment, sizeof(comment), "%s \"%.*s\"", 
                                                            tokens[0], (int)(end - start), start);
                                                    int first_byte = 1;
                                                    
                                                    // Procesar cada carácter
                                                    for (char* p = start; p < end; p++) {
                                                        uint8_t value;
                                                        
                                                        printf("DEBUG: Procesando carácter en posición %ld: '%c' (0x%02X)\n", 
                                                            p - start, *p, (unsigned char)*p);
                                                        
                                                        if (*p == '\\' && (p + 1) < end) {
                                                            char escape_char = *(p + 1);
                                                            printf("DEBUG: Encontrada secuencia de escape: \\%c\n", escape_char);
                                                            
                                                            p++; // Avanzar al carácter de escape
                                                            switch (escape_char) {
                                                                case 'n': 
                                                                    value = 0x0A; 
                                                                    printf("DEBUG: \\n -> 0x0A (newline)\n");
                                                                    break;
                                                                case 't': 
                                                                    value = 0x09; 
                                                                    printf("DEBUG: \\t -> 0x09 (tab)\n");
                                                                    break;
                                                                case 'r': 
                                                                    value = 0x0D; 
                                                                    printf("DEBUG: \\r -> 0x0D (carriage return)\n");
                                                                    break;
                                                                case '0': 
                                                                    value = 0x00; 
                                                                    printf("DEBUG: \\0 -> 0x00 (null)\n");
                                                                    break;
                                                                case '\\': 
                                                                    value = 0x5C; 
                                                                    printf("DEBUG: \\\\ -> 0x5C (backslash)\n");
                                                                    break;
                                                                case '"': 
                                                                    value = 0x22; 
                                                                    printf("DEBUG: \\\" -> 0x22 (quote)\n");
                                                                    break;
                                                                default: 
                                                                    value = escape_char; 
                                                                    printf("DEBUG: \\%c -> 0x%02X (literal)\n", escape_char, value);
                                                                    break;
                                                            }
                                                            
                                                            debug_escape_sequence("escape", escape_char, value);
                                                        } else {
                                                            value = (uint8_t)*p;
                                                            printf("DEBUG: Carácter normal: '%c' -> 0x%02X\n", *p, value);
                                                        }
                                                        
                                                        printf("DEBUG: Agregando byte 0x%02X al word\n", value);
                                                        
                                                        if (first_byte) {
                                                            add_byte_to_word_with_comment(out, &current_word, value, formato, comment);
                                                            first_byte = 0;
                                                        } else {
                                                            add_byte_to_word(out, &current_word, value, formato);
                                                        }
                                                        pc += 1;
                                                        instruccionesProcesadas++;
                                                    }
                                                    
                                                    // Añadir byte nulo al final (solo para .string/.asciiz/.asciz)
                                                    if (strcmp(tokens[0], ".string") == 0 || 
                                                        strcmp(tokens[0], ".asciiz") == 0 ||
                                                        strcmp(tokens[0], ".asciz") == 0) {
                                                        printf("DEBUG: Agregando byte nulo final (0x00)\n");
                                                        add_byte_to_word(out, &current_word, 0, formato);
                                                        pc += 1;
                                                        instruccionesProcesadas++;
                                                    }
                                                    
                                                    printf("DEBUG: Terminado procesamiento de string\n\n");
                                                } else {
                                                    printf("ERROR: No se encontraron comillas válidas en: %s\n", trimmed);
                                                }
                                                
                                                continue; // Importante: continuar con la siguiente línea
                                            }
                                            else if (strcmp(tokens[0], ".ascii") == 0) {
                                                // Extraer string entre comillas
                                                char* start = strchr(trimmed, '"');
                                                char* end = strrchr(trimmed, '"');
                                                if (start && end && start != end) {
                                                    start++; // Saltar comilla inicial
                                                    
                                                    // Crear comentario
                                                    char comment[256];
                                                    snprintf(comment, sizeof(comment), ".ascii \"%.*s\"", (int)(end - start), start);
                                                    int first_byte = 1;
                                                    
                                                    // Procesar cada carácter hasta la comilla final
                                                    for (char* p = start; p < end; p++) {
                                                        uint8_t value;
                                                        
                                                        // Manejar secuencias de escape correctamente
                                                        if (*p == '\\' && (p + 1) < end) {
                                                            p++;
                                                            switch (*p) {
                                                                case 'n': value = '\n'; break;
                                                                case 't': value = '\t'; break;
                                                                case 'r': value = '\r'; break;
                                                                case '0': value = '\0'; break;
                                                                case '\\': value = '\\'; break;
                                                                case '"': value = '"'; break;
                                                                case 'a': value = '\a'; break;
                                                                case 'b': value = '\b'; break;
                                                                case 'f': value = '\f'; break;
                                                                case 'v': value = '\v'; break;
                                                                default: value = *p; break;
                                                            }
                                                        } else {
                                                            value = (uint8_t)*p;
                                                        }
                                                        
                                                        if (first_byte) {
                                                            add_byte_to_word_with_comment(out, &current_word, value, formato, comment);
                                                            first_byte = 0;
                                                        } else {
                                                            add_byte_to_word(out, &current_word, value, formato);
                                                        }
                                                        pc += 1;
                                                        instruccionesProcesadas++;
                                                    }
                                                }
                                                
                                                continue;
                                            }
                                        }
                                    }
                                    
                                    continue; // Si era una directiva de string, ya la procesamos
                                }
                                
                                // Para otras directivas, usar el procesamiento normal
                                char tokens[8][MAX_SYMBOL_NAME];
                                int token_count = split_instruction(inicio, tokens, 8);
                                if (token_count == 0) continue;
                                
                                // .align
                                if (strcmp(tokens[0], ".align") == 0 && token_count >= 2) {
                                    // Escribir palabra actual si tiene datos
                                    if (current_word.byte_count > 0) {
                                        write_data_word(out, &current_word, formato);
                                    }
                                    
                                    int alignment = 1 << atoi(tokens[1]);
                                    while (pc % alignment != 0) {
                                        add_byte_to_word(out, &current_word, 0, formato);
                                        pc += 1;
                                    }
                                    current_word.address = pc;
                                }
                                // .word - 4 bytes
                                else if (strcmp(tokens[0], ".word") == 0) {
                                    for (int i = 1; i < token_count; i++) {
                                        // Escribir palabra actual si no hay espacio
                                        if (current_word.byte_count > 0) {
                                            write_data_word(out, &current_word, formato);
                                        }
                                        
                                        uint32_t value = (uint32_t)parse_immediate_or_symbol(tokens[i], &symbol_table, pc);
                                        
                                        // Crear comentario
                                        char comment[256];
                                        snprintf(comment, sizeof(comment), ".word %s", tokens[i]);
                                        
                                        // Añadir los 4 bytes de la palabra (little-endian)
                                        add_byte_to_word_with_comment(out, &current_word, value & 0xFF, formato, comment);
                                        add_byte_to_word(out, &current_word, (value >> 8) & 0xFF, formato);
                                        add_byte_to_word(out, &current_word, (value >> 16) & 0xFF, formato);
                                        add_byte_to_word(out, &current_word, (value >> 24) & 0xFF, formato);
                                        
                                        pc += 4;
                                        instruccionesProcesadas++;
                                    }
                                }
                                // .half / .short - 2 bytes
                                else if (strcmp(tokens[0], ".half") == 0 || strcmp(tokens[0], ".short") == 0) {
                                    for (int i = 1; i < token_count; i++) {
                                        uint16_t value = (uint16_t)parse_immediate_or_symbol(tokens[i], &symbol_table, pc);
                                        
                                        // Crear comentario para el primer byte
                                        char comment[256];
                                        snprintf(comment, sizeof(comment), "%s %s", tokens[0], tokens[i]);
                                        
                                        // Añadir los 2 bytes del half (little-endian)
                                        add_byte_to_word_with_comment(out, &current_word, value & 0xFF, formato, comment);
                                        add_byte_to_word(out, &current_word, (value >> 8) & 0xFF, formato);
                                        
                                        pc += 2;
                                        instruccionesProcesadas++;
                                    }
                                }
                                // .byte - 1 byte
                                else if (strcmp(tokens[0], ".byte") == 0) {
                                    for (int i = 1; i < token_count; i++) {
                                        uint8_t value;
                                        
                                        // Manejar caracteres entre comillas simples
                                        if (tokens[i][0] == '\'' && strlen(tokens[i]) >= 3 && tokens[i][2] == '\'') {
                                            value = (uint8_t)tokens[i][1];
                                        } else {
                                            value = (uint8_t)parse_immediate_or_symbol(tokens[i], &symbol_table, pc);
                                        }
                                        
                                        add_byte_to_word(out, &current_word, value, formato);
                                        pc += 1;
                                        instruccionesProcesadas++;
                                    }
                                }
                                // .space / .skip
                                else if (strcmp(tokens[0], ".space") == 0 || strcmp(tokens[0], ".skip") == 0) {
                                    if (token_count >= 2) {
                                        int size = atoi(tokens[1]);
                                        
                                        // Crear comentario
                                        char comment[256];
                                        snprintf(comment, sizeof(comment), "%s %s", tokens[0], tokens[1]);
                                        int first_byte = 1;
                                        
                                        for (int i = 0; i < size; i++) {
                                            if (first_byte) {
                                                add_byte_to_word_with_comment(out, &current_word, 0, formato, comment);
                                                first_byte = 0;
                                            } else {
                                                add_byte_to_word(out, &current_word, 0, formato);
                                            }
                                            pc += 1;
                                            instruccionesProcesadas++;
                                        }
                                    }
                                }
                                
                                continue;
                            }
                            
                            // PROCESAR INSTRUCCIONES .TEXT
                            if (current_section == SECTION_TEXT) {
                                // Saltar directivas en .text
                                if (inicio[0] == '.') continue;
                                
                                // Capturamos el PC actual en cada instrucción real
                                uint32_t cur_pc = pc;
                                
                                // Comprobamos si es pseudoinstrucción
                                char tokens[8][MAX_SYMBOL_NAME];
                                int token_count = split_instruction(inicio, tokens, 8);
                                if (token_count > 0 && is_pseudoinstruction(tokens[0])) {
                                    char expanded[4][256];
                                    int expansion_count = expand_pseudoinstruction(inicio, expanded, 4);
                                    if (expansion_count > 0) {
                                        for (int exp = 0; exp < expansion_count; exp++) {
                                            uint32_t codigoMaquina =
                                              encode_instruction_with_symbols(expanded[exp],
                                                                              &symbol_table,
                                                                              cur_pc);
                                            if (codigoMaquina) {
                                                if (formato == 0) {
                                                    fprintf(out,
                                                            "0x%08X: 0x%08X  # %s (expandido de: %s)\n",
                                                            cur_pc,
                                                            codigoMaquina,
                                                            expanded[exp],
                                                            inicio);
                                                } else {
                                                    char binario[33], binarioFormateado[50];
                                                    uint32_to_binary_string(codigoMaquina, binario);
                                                    format_binary_with_spaces(binario, binarioFormateado);
                                                    fprintf(out,
                                                            "0x%08X: %s  # %s (expandido de: %s)\n",
                                                            cur_pc,
                                                            binarioFormateado,
                                                            expanded[exp],
                                                            inicio);
                                                }
                                                instruccionesProcesadas++;
                                            }
                                            cur_pc += 4;
                                        }
                                        pc = cur_pc;
                                        continue;
                                    }
                                }
                                
                                // Instrucción normal
                                {
                                    uint32_t codigoMaquina =
                                      encode_instruction_with_symbols(inicio,
                                                                      &symbol_table,
                                                                      cur_pc);
                                    if (codigoMaquina) {
                                        if (formato == 0) {
                                            fprintf(out,
                                                    "0x%08X: 0x%08X  # %s\n",
                                                    cur_pc,
                                                    codigoMaquina,
                                                    inicio);
                                        } else {
                                            char binario[33], binarioFormateado[50];
                                            uint32_to_binary_string(codigoMaquina, binario);
                                            format_binary_with_spaces(binario, binarioFormateado);
                                            fprintf(out,
                                                    "0x%08X: %s  # %s\n",
                                                    cur_pc,
                                                    binarioFormateado,
                                                    inicio);
                                        }
                                        instruccionesProcesadas++;
                                    }
                                    pc = cur_pc + 4;
                                }
                            }
                        }

                        // Escribir cualquier palabra parcial pendiente
                        if (seccion == 1 && current_word.byte_count > 0) {
                            write_data_word(out, &current_word, formato);
                        }

                        debug_memory_dump_info(pc, DATA_BASE_ADDRESS, instruccionesProcesadas);

                        // Para .data, completar con ceros
                        // Para .data, completar con ceros
                        if (seccion == 1) {
                            uint32_t bytesGenerados = 0;
                            
                            if (current_section == SECTION_DATA && pc >= DATA_BASE_ADDRESS) {
                                bytesGenerados = pc - DATA_BASE_ADDRESS;
                            }
                            
                            uint32_t palabrasUsadas = (bytesGenerados + 3) / 4;
                            
                            // Calcular volcado basado SOLO en instrucciones procesadas (método RARS)
                            uint32_t totalDeseado;
                            if (instruccionesProcesadas <= 1024) {
                                totalDeseado = 1024;
                            } else if (instruccionesProcesadas <= 2048) {
                                totalDeseado = 2048;
                            } else if (instruccionesProcesadas <= 3072) {
                                totalDeseado = 3072;
                            } else {
                                totalDeseado = ((instruccionesProcesadas + 1023) / 1024) * 1024;
                            }
                            
                            printf("DEBUG VOLCADO RARS-STYLE:\n");
                            printf("  - Instrucciones procesadas: %d\n", instruccionesProcesadas);
                            printf("  - Palabras usadas: %u\n", palabrasUsadas);
                            printf("  - Volcado calculado: %u\n", totalDeseado);
                            
                            if (palabrasUsadas < totalDeseado) {
                                uint32_t faltan = totalDeseado - palabrasUsadas;
                                printf("  - Completando con: %u palabras de ceros\n", faltan);
                                
                                for (uint32_t i = 0; i < faltan; i++) {
                                    if (formato == 0) {
                                        fprintf(out, "00000000\n");
                                    } else {
                                        fprintf(out, "00000000000000000000000000000000\n");
                                    }
                                }
                            }
                        }

                        // Escribir estadísticas finales
                        fprintf(out, "\n# ================================================\n");
                        fprintf(out, "# ESTADÍSTICAS DEL ENSAMBLADO:\n");
                        fprintf(out, "# Total de instrucciones procesadas: %d\n", instruccionesProcesadas);
                        fprintf(out, "# Total de errores: %d\n", errores);
                        fprintf(out, "# Dirección inicial del PC: 0x%08X\n", 
                               (seccion == 0) ? TEXT_BASE_ADDRESS : DATA_BASE_ADDRESS);
                        fprintf(out, "# Dirección final del PC: 0x%08X\n", pc);
                        fprintf(out, "# Bytes generados: %d\n", 
                               (pc - ((seccion == 0) ? TEXT_BASE_ADDRESS : DATA_BASE_ADDRESS)));
                        fprintf(out, "# ================================================\n");

                        fclose(out);
                        fclose(file);
                        
                        // Crear archivo limpio (solo código máquina)
                        char cleanFilename[1024];
                        snprintf(cleanFilename, sizeof cleanFilename,
                                "%.*s_%s_%s_clean.txt",
                                (int)nombreLen, nombreSimple,
                                nombreSeccion, nombreFormato);

                        strip_machine_code(archivoSalida, cleanFilename);
                        
                        // Mostrar mensaje de resultado
                        char mensajeResultado[4096];
                        if (errores == 0) {
                            snprintf(mensajeResultado, sizeof(mensajeResultado), 
                                    "¡Archivo procesado exitosamente!\n\n"
                                    "Instrucciones procesadas: %d\n"
                                    "Errores: %d\n"
                                    "Símbolos definidos: %d\n"
                                    "Archivo generado: %s\n"
                                    "Archivo limpio: %s\n"
                                    "Formato: %s", 
                                    instruccionesProcesadas, errores, symbol_table.count,
                                    archivoSalida, cleanFilename,
                                    (formato == 0) ? "Hexadecimal" : "Binario");
                            
                            showMessageBoxThreaded("Procesamiento Completo", mensajeResultado, "ok", "info", 1);
                        } else {
                            snprintf(mensajeResultado, sizeof(mensajeResultado), 
                                    "Archivo procesado con errores\n\n"
                                    "Instrucciones procesadas: %d\n"
                                    "Errores encontrados: %d\n"
                                    "Símbolos definidos: %d\n"
                                    "Archivo generado: %s\n\n"
                                    "Revise el archivo de salida para más detalles.", 
                                    instruccionesProcesadas, errores, symbol_table.count, archivoSalida);
                            
                            showMessageBoxThreaded("Procesamiento con Errores", mensajeResultado, "ok", "warning", 1);
                        }
                        
                        printf("\n========================================\n");
                        printf("PROCESAMIENTO COMPLETADO\n");
                        printf("Archivo generado: %s\n", archivoSalida);
                        printf("Archivo limpio: %s\n", cleanFilename);
                        printf("Instrucciones: %d, Errores: %d\n", instruccionesProcesadas, errores);
                        printf("========================================\n\n");
                        
                        SDL_Delay(100);
                        
                    } else {
                        // Mostrar error si falta seleccionar algo
                        const char* mensajeError = "Por favor seleccione:\n"
                                                  "- Un archivo\n"
                                                  "- Una sección (.text o .data)\n"
                                                  "- Un formato (hexadecimal o binario)";
                        showMessageBoxThreaded("Selección incompleta", mensajeError, "ok", "warning", 1);
                    }
                }
            }
        }

        SDL_SetRenderDrawColor(renderer, 30, 30, 30, 255);
        SDL_RenderClear(renderer);

        SDL_Surface *surface;
        SDL_Texture *texture;
        SDL_Rect dst;

        #define RENDER_BTN(label, rect) \
            surface = TTF_RenderText_Blended(font, label, white); \
            texture = SDL_CreateTextureFromSurface(renderer, surface); \
            dst.x = rect.x + 10; \
            dst.y = rect.y + (rect.h - surface->h)/2; \
            dst.w = surface->w; dst.h = surface->h; \
            SDL_RenderCopy(renderer, texture, NULL, &dst); \
            SDL_FreeSurface(surface); SDL_DestroyTexture(texture);

        surface = TTF_RenderText_Blended(font, "Seleccione una seccion:", white);
        texture = SDL_CreateTextureFromSurface(renderer, surface);
        dst.x = WIDTH / 2 - surface->w / 2;
        dst.y = 60;
        dst.w = surface->w; dst.h = surface->h;
        SDL_RenderCopy(renderer, texture, NULL, &dst);
        SDL_FreeSurface(surface); SDL_DestroyTexture(texture);

        SDL_SetRenderDrawColor(renderer, 80, 150, 255, 255);
        SDL_RenderFillRect(renderer, &seccionBox);
        RENDER_BTN(seccion == 0 ? ".text" : seccion == 1 ? ".data" : "--", seccionBox);

        if (showSeccionMenu) {
            SDL_SetRenderDrawColor(renderer, 60, 60, 60, 255);
            for (int i = 0; i < 2; i++) {
                SDL_RenderFillRect(renderer, &seccionOpciones[i]);
                RENDER_BTN(i == 0 ? ".text" : ".data", seccionOpciones[i]);
            }
        }

        surface = TTF_RenderText_Blended(font, "Seleccione un formato:", white);
        texture = SDL_CreateTextureFromSurface(renderer, surface);
        dst.x = WIDTH / 2 - surface->w / 2;
        dst.y = 200;
        dst.w = surface->w; dst.h = surface->h;
        SDL_RenderCopy(renderer, texture, NULL, &dst);
        SDL_FreeSurface(surface); SDL_DestroyTexture(texture);

        SDL_SetRenderDrawColor(renderer, 80, 200, 100, 255);
        SDL_RenderFillRect(renderer, &formatoBox);
        RENDER_BTN(formato == 0 ? "Hexadecimal" : formato == 1 ? "Binario" : "--", formatoBox);

        if (showFormatoMenu) {
            SDL_SetRenderDrawColor(renderer, 60, 60, 60, 255);
            for (int i = 0; i < 2; i++) {
                SDL_RenderFillRect(renderer, &formatoOpciones[i]);
                RENDER_BTN(i == 0 ? "Hexadecimal" : "Binario", formatoOpciones[i]);
            }
        }

        // Cambiar color del botón de procesar según el estado
        if (fileData.archivoSeleccionado[0] != '\0' && seccion != -1 && formato != -1) {
            SDL_SetRenderDrawColor(renderer, 100, 200, 100, 255);
        } else {
            SDL_SetRenderDrawColor(renderer, 100, 100, 100, 255);
        }
        
        SDL_RenderFillRect(renderer, &fileBtn);
        SDL_RenderFillRect(renderer, &processBtn);

        RENDER_BTN(fileData.archivoNombre, fileBtn);
        RENDER_BTN("Procesar", processBtn);

        SDL_RenderPresent(renderer);
    }

    // Esperar a que termine cualquier thread pendiente
    if (fileDialogThreadRunning) {
        pthread_join(fileDialogThread, NULL);
    }

    TTF_CloseFont(font);
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    TTF_Quit();
    SDL_Quit();
    return 0;
}