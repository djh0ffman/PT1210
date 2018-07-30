CC = vc
AS = vasmm68k_mot

ASFLAGS = -Fhunk -Iinclude
CFLAGS = +kick13 -g -I$(NDK)/Include/include_h -lamiga -c99

OUTPUT_EXE = bin/pt1210.exe

$(OUTPUT_EXE): main.o filesystem.o pt1210.o
	$(CC) $(CFLAGS) -o $(OUTPUT_EXE) $^

# Assembly code
pt1210.o: $(wildcard legacy/*.asm)
	$(AS) $(ASFLAGS) -o $@ legacy/pt1210.asm

# C code
filesystem.o: filesystem.c filesystem.h
	$(CC) $(CFLAGS) -c $< -o $@

main.o: main.c
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: default
default: pt1210

.PHONY: clean
clean:
	-rm -f $(OUTPUT_EXE) *.o

.PHONY: run
run: $(OUTPUT_EXE)
	winuae64