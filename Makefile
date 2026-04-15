# Compiler and flags
FC = gfortran
FFLAGS = -std=legacy -fdefault-real-8 -fdefault-double-8 -fdefault-integer-8 -fbacktrace

# Directories
SRC_DIR = src
BIN_DIR = bin

# Files
TARGET  = $(BIN_DIR)/sources4d
SRC     = src/sources4d.for

all: $(BIN_DIR) $(TARGET)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(TARGET): $(SRC)
	$(FC) $(FFLAGS) $< -o $@

clean:
	rm -f $(TARGET)

.PHONY: all clean