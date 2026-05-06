# Compiler and flags
FC = gfortran
FFLAGS = -std=legacy -fdefault-real-8 -fdefault-double-8 -fdefault-integer-8 -fbacktrace
FDEBUG = -g -Wall -Wextra -O0 -fcheck=all -ffpe-trap=invalid,zero,overflow \
         -finit-real=snan -finit-integer=-999999 -finit-logical=true \
		 -fsanitize=address,undefined

# Directories
SRC_DIR = src
BIN_DIR = bin

# Files
TARGET = $(BIN_DIR)/sources4d
SRC    = src/sources4d.for

.PHONY: all debug clean

all: $(BIN_DIR) $(TARGET)

debug: FFLAGS += $(FDEBUG)
debug: $(BIN_DIR) $(TARGET)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(TARGET): $(SRC)
	$(FC) $(FFLAGS) $< -o $@

clean:
	rm -f $(TARGET)