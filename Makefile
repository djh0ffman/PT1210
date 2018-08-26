SOURCES :=	action.c audiodevice.c consoledevice.c filesystem.c \
			graphics.c input.c inputdevice.c keyboard.c libraries.c \
			main.c

OUTPUT_EXE := bin/pt1210.exe
OUTPUT_ADF := bin/pt1210.adf

XDFTOOL_CMDS := format "PT1210" + \
				boot install boot1x + \
				makedir s + \
				write bin/s/startup-sequence s + \
				write $(OUTPUT_EXE)

# Search for sources in the following directory
VPATH = src

# Build objects in the following directory
BUILD_DIR = build

# Assembler flags
AS := vasmm68k_mot
ASFLAGS += -m68000 -Fhunk -x -Iinclude -quiet

# Define CC=vc to compile with VBCC
ifeq ($(CC),vc)
# VBCC compiler setup
# The following variables should be either passed to 'make' or set as environment variables
ifndef NDK
$(error NDK is not set; please set NDK to the root of your OS3.9 NDK directory)
endif

ifndef VBCC
$(error VBCC is not set; please set VBCC to the root of your vbcc installation)
endif

# Swap all backslashes for forward slashes - can avoid confusing some tools under Windows
NDK := $(subst \,/,$(NDK))
VBCC := $(subst \,/,$(VBCC))

VBCC_INCLUDE_PATH := $(VBCC)/targets/m68k-kick13/include
NDK_INCLUDE_PATH := $(NDK)/Include/include_h
NDK_LINKER_PATH := $(NDK)/Include/linker_libs

CFLAGS += +vc.config -lamiga -c99 -I$(VBCC_INCLUDE_PATH) -I$(NDK_INCLUDE_PATH) -L$(NDK_LINKER_PATH)

else
# GCC compiler setup
CC := m68k-amigaos-gcc
CFLAGS += -mcrt=nix13 -std=c99 -Wall -Werror -Wno-pointer-sign

# Optimized CFLAGS
ifndef DEBUG
CFLAGS += -fomit-frame-pointer
endif

# Automatic compiler-assisted dependency generation
DEPFLAGS = -MT $@ -MMD -MP -MF $(BUILD_DIR)/$*.Td
POST_COMPILE = @mv -f $(BUILD_DIR)/$*.Td $(BUILD_DIR)/$*.d && touch $@
endif

# Define DEBUG=1 to build in debug mode
ifeq ($(DEBUG),1)
# Debug CFLAGS
CFLAGS += -g -DDEBUG -ldebug
else
# Optimized CFLAGS
CFLAGS += -Os
endif

$(shell mkdir -p $(BUILD_DIR))

# Default target - ADF disk image
$(OUTPUT_ADF): $(OUTPUT_EXE)
	xdftool -f $(OUTPUT_ADF) $(XDFTOOL_CMDS)

$(OUTPUT_EXE): $(BUILD_DIR)/pt1210.o $(SOURCES:%.c=$(BUILD_DIR)/%.o)
	$(CC) $(CFLAGS) -o $(OUTPUT_EXE) $^

# Assembly code
$(BUILD_DIR)/pt1210.o: $(wildcard legacy/*.asm)
	$(AS) $(ASFLAGS) -o $@ legacy/pt1210.asm

# C code
$(BUILD_DIR)/%.o : %.c
$(BUILD_DIR)/%.o : %.c $(BUILD_DIR)/%.d
	$(CC) $(DEPFLAGS) $(CFLAGS) -c -o $@ $<
	$(POST_COMPILE)

.PHONY: clean
clean:
	@rm -rf $(OUTPUT_ADF) $(OUTPUT_EXE) $(BUILD_DIR)

.PHONY: run
run: $(OUTPUT_EXE)
	winuae64 -serlog

.PHONY: run-fs
run-fs: $(OUTPUT_EXE)
	fs-uae emu_configs/a1200.fs-uae

.PHONY: cppcheck
cppcheck:
	cppcheck --enable=all --std=c99 --verbose --quiet .

$(BUILD_DIR)/%.d: ;
.PRECIOUS: $(BUILD_DIR)/%.d

include $(wildcard $(SOURCES:%.c=$(BUILD_DIR)/%.d))