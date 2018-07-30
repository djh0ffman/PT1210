# The following variables should be either passed to 'make' or set as environment variables
ifndef NDK
$(error NDK is not set. Please set NDK to the root of your OS3.9 NDK directory.)
endif

ifndef VBCC
$(error VBCC is not set. Please set VBCC to the root of your vbcc installation.)
endif

# Swap all backslashes for forward slashes - can avoid confusing some tools under Windows
NDK := $(subst \,/,$(NDK))
VBCC := $(subst \,/,$(VBCC))

NDK_INCLUDE_PATH := $(NDK)/include/include_h
VBCC_INCLUDE_PATH := $(VBCC)/targets/m68k-kick13/include

CC := vc
AS := vasmm68k_mot

ASFLAGS += -Fhunk -x -Iinclude
CFLAGS += +kick13 -g -lamiga -c99 -I$(NDK_INCLUDE_PATH)

OUTPUT_EXE := bin/pt1210.exe

# Default target - the program executable
$(OUTPUT_EXE): main.o filesystem.o pt1210.o
	$(CC) $(CFLAGS) -o $(OUTPUT_EXE) $^

# Assembly code
pt1210.o: $(wildcard legacy/*.asm)
	$(AS) $(ASFLAGS) -o $@ legacy/pt1210.asm

# C code
filesystem.o: filesystem.c filesystem.h
	$(CC) $(CFLAGS) -c -o $@ $<

main.o: main.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	-rm -f $(OUTPUT_EXE) *.o

.PHONY: run
run: $(OUTPUT_EXE)
	winuae64

.PHONY: cppcheck
cppcheck:
	cppcheck -I$(VBCC_INCLUDE_PATH) -I$(NDK_INCLUDE_PATH) --enable=all --std=c99 --verbose --quiet -D__VBCC__ .