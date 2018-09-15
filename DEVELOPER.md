# PT1210 Developer Notes

## Setting up a cross-compiling Amiga toolchain

The following steps must be carried out to set up the tools required to compile PT1210.

### Windows

#### GCC
1. Download and run the [`amiga-gcc` installer by SteveMoody](https://github.com/SteveMoody73/amiga-gcc/releases), ensuring the _Add Amiga GCC Tools to PATH_ option is selected.
2. The `amiga-gcc` project [currently has a bug](https://github.com/bebbo/amiga-gcc/issues/42) which means that an Amiga NDK 1.3 header that we depend on ends up blank. Until this bug is fixed, we must work around it by doing the following:
	1. Navigate to your `amiga-gcc` installation (e.g. `C:\amiga-gcc`).
	2. Copy the file `m68k-amigaos\ndk-include\graphics\monitor.h` to `m68k-amigaos\ndk13-include\graphics\monitor.h`, overwriting the empty file.
3. In Windows System settings, add an environment variable named `AMIGA_GCC` and point it to the root of your `amiga-gcc` installation (e.g. `C:\amiga-gcc`). This helps our Makefile find the necessary include paths for the assembler.
4. You need _GNU Make_ available in your `PATH`. There may be some old binary versions for Windows available for download around the Internet, but the best way to get a recent version is probably via [MSYS2](http://www.msys2.org/):
	1. Download and run the [MSYS2 installer](http://www.msys2.org/).
	2. Open the MSYS2 terminal and install _GNU Make_ by running `pacman -S make`.
	3. Edit your `PATH` environment variable in Windows System settings to add your MSYS2 `usr\bin` directory to the list, e.g. `C:\msys64\usr\bin`. The `make` tool should now be available in any Windows command prompt.
5. __(Optional)__ Download and install [amitools](https://github.com/cnvogelg/amitools) for creating a bootable ADF disk image.
6. __(Optional)__ Download and install [Cppcheck](http://cppcheck.sourceforge.net/) for performing source code linting.

#### VBCC

TODO.

## Building PT1210

You can compile PT1210 by opening a terminal/command prompt, navigating to the root of this repo, and typing:
```
make bin/pt1210.exe
```

If you have `amitools` installed, with `xdftool` available in your `PATH`, you can just type `make` to build the executable _and_ a bootable ADF disk image.

`make clean` will delete any built objects, returning the project directory to a clean state.

### Build options

The following options can be passed to the `make` command to change how PT1210 is built:

| Option    | Description |
|-----------|-------------|
| `CC=vc`   | Compiles with the VBCC compiler instead of GCC. |
| `DEBUG=1` | Compiles PT1210 with debug information enabled, no optimizations, and `DEBUG` defined as a preprocessor macro (which generally enables debug print output). Also links with `debug.lib`. |