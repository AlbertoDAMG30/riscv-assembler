# Makefile para Traductor RISC-V con SDL2 + SDL2_ttf + pthread

# Compilador y flags de compilación
CC       := gcc
CFLAGS   := -Wall -Wextra -std=c11 -I. $(shell sdl2-config --cflags) -D_REENTRANT

# Flags de enlace (añadimos SDL2_ttf y pthread)
LDFLAGS  := $(shell sdl2-config --libs) -lSDL2_ttf -pthread

# Fuentes y objetos
SRCS     := Proyecto_3.c encoder.c tinyfiledialogs.c
OBJS     := $(SRCS:.c=.o)

# Ejecutable
TARGET   := traductor

.PHONY: all clean run

# Regla por defecto: compila todo
all: $(TARGET)

# Enlaza objetos para generar el ejecutable
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# Compila cada .c en su .o
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Limpia artefactos
clean:
	rm -f $(OBJS) $(TARGET)

# Compila y ejecuta
run: all
	./$(TARGET)