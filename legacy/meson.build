vasm = find_program('vasmm68k_mot')
as_flags = ['-m68000', '-Fhunk', '-x', '-quiet', '-I/opt/amiga/m68k-amigaos/ndk-include']

legacy_target = custom_target('legacy', output : 'pt1210.o', input : 'pt1210.asm', command : [vasm, as_flags, '@INPUT@', '-o', '@OUTPUT@'])
legacy = static_library('legacy', legacy_target)

