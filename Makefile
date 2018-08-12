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

NDK_LINKER_PATH := $(NDK)/include/linker_libs
NDK_INCLUDE_PATH := $(NDK)/include/include_h
VBCC_INCLUDE_PATH := $(VBCC)/targets/m68k-kick13/include

CC := vc
AS := vasmm68k_mot

ASFLAGS += -Fhunk -x -Iinclude
CFLAGS += +kick13 -g -lamiga -ldebug -c99 -I$(NDK_INCLUDE_PATH) -L$(NDK_LINKER_PATH) -DDEBUG

OUTPUT_EXE := bin/pt1210.exe

# Default target - the program executable
$(OUTPUT_EXE): main.o action.o audiodevice.o consoledevice.o filesystem.o graphics.o input.o inputdevice.o keyboard.o libraries.o pt1210.o
	$(CC) $(CFLAGS) -o $(OUTPUT_EXE) $^

# Assembly code
pt1210.o: $(wildcard legacy/*.asm)
	$(AS) $(ASFLAGS) -o $@ legacy/pt1210.asm

# C code
action.o: action.c action.h
	$(CC) $(CFLAGS) -c -o $@ $<

audiodevice.o: audiodevice.c audiodevice.h
	$(CC) $(CFLAGS) -c -o $@ $<

consoledevice.o: consoledevice.c consoledevice.h
	$(CC) $(CFLAGS) -c -o $@ $<

filesystem.o: filesystem.c filesystem.h utility.h
	$(CC) $(CFLAGS) -c -o $@ $<

graphics.o: graphics.c graphics.h
	$(CC) $(CFLAGS) -c -o $@ $<

input.o: input.c input.h
	$(CC) $(CFLAGS) -c -o $@ $<

inputdevice.o: inputdevice.c inputdevice.h
	$(CC) $(CFLAGS) -c -o $@ $<

keyboard.o: keyboard.c keyboard.h
	$(CC) $(CFLAGS) -c -o $@ $<

libraries.o: libraries.c libraries.h
	$(CC) $(CFLAGS) -c -o $@ $<

main.o: main.c
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean
clean:
	-rm -f $(OUTPUT_EXE) *.o

.PHONY: run
run: $(OUTPUT_EXE)
	winuae64 -serlog

.PHONY: cppcheck
cppcheck:
	cppcheck -I$(VBCC_INCLUDE_PATH) -I$(NDK_INCLUDE_PATH) --enable=all --std=c99 --verbose --quiet -D__VBCC__ .