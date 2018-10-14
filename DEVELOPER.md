# PT1210 Developer Notes

## Setting up a cross-compiling Amiga toolchain

Two C compilers are available which can generate Amiga executables: __VBCC__ and __GCC__.

The general consensus is that VBCC was the best modern C compiler available for the Amiga until recently (~2017), when a recent version of GCC was adapted to the Amiga by Stefan "bebbo" Franke.

| Compiler       | Pros | Cons |
|----------------|------|------|
| __VBCC__       | Stable, good documentation, tailored for 68000 systems from the beginning, nice extensions for Amiga quirks (e.g. placing data in Chip/Fast memory or making system-legal interrupt handlers in C). | A little tricky to set up, no up-to-date Windows binaries/installer, can produce sub-optimal code. |
| __GCC 6 port__ | Superior code generation (+20yrs of compiler tech progress), supports modern C and C++, shows promise for enabling use of modern source-level debugging tools like GDB for easier debugging. | A little unstable/unproven for Amiga (but quickly improving), some minor bugs in the installer package, large installation footprint (e.g. depends on MSYS2 support libraries for Windows), requires PC to cross-compile (can't compile on the Amiga itself). |

We would like to be able to compile PT1210 with both compilers, as this can reveal bugs in the code that may not be picked up by one compiler's warnings, and allows us to compare the quality of the generated code between the two.

It is likely that GCC will emerge as the best compiler for the Amiga in the near future, hence our default compiler will be the GCC 6 port.

The following sections detail the steps required to set up the tools you need to compile PT1210 on your platform of choice.

### Windows

#### GCC
1. Download and run the [`amiga-gcc` installer for Windows by bebbo](https://franke.ms/download/setup-amiga-gcc.exe).
2. The `amiga-gcc` project [currently has a bug](https://github.com/bebbo/amiga-gcc/issues/42) which means that an Amiga NDK 1.3 header that we depend on ends up blank. Until this bug is fixed, we must work around it by doing the following:
	1. Navigate to your `amiga-gcc` installation (e.g. `C:\amiga-gcc`).
	2. Copy the file `m68k-amigaos\ndk-include\graphics\monitor.h` to `m68k-amigaos\ndk13-include\graphics\monitor.h`, overwriting the empty file.
3. In Windows System settings, add a new environment variable (either for your user or for the system; it doesn't matter) named `AMIGA_GCC` and point it to the root of your `amiga-gcc` installation (e.g. `C:\amiga-gcc`). This helps our Makefile find the necessary include paths for the assembler.
4. Edit the `PATH` variable to add `%AMIGA_GCC%\bin` to the list, which makes all of the `m68k-amigaos-*` tools available from any Windows command prompt.
5. You need _GNU Make_ available in your `PATH`. There may be some old binary versions for Windows available for download around the Internet, but the best way to get a recent version is probably via [MSYS2](http://www.msys2.org/):
	1. Download and run the [MSYS2 installer](http://www.msys2.org/).
	2. Open the MSYS2 terminal and install _GNU Make_ by running `pacman -S make`.
	3. Edit your `PATH` environment variable in Windows System settings to add your MSYS2 `usr\bin` directory to the list, e.g. `C:\msys64\usr\bin`. The `make` tool should now be available in any Windows command prompt.

#### VBCC
1. Follow the steps above for GCC, as the `amiga-gcc` installer actually includes VBCC too.
2. Make a copy of `vc.config.win` in the root of the PT1210 repository and rename it to `vc.config`.
3. If you have installed `amiga-gcc` in a location other than `C:\amiga-gcc`, edit `vc.config` so that all references to `C:/amiga-gcc` are changed to the correct location. __Note:__ use _forward slashes_ here as path separators.
4. We now need to download and install the Kickstart 1.3-compatible includes and link libraries for VBCC, as the `amiga-gcc` installer currently only comes with the 2.x+ VBCC target:
	1. Download the [m68k-kick13 VBCC target package](http://server.owl.de/~frank/vbcc/2017-05-18/vbcc_target_m68k-kick13.lha).
	2. Navigate to the `m68k-amigaos` directory within your `amiga-gcc` installation (e.g. `C:\amiga-gcc\m68k-amigaos`).
	3. Create a new directory called `vbcc13` (alongside the existing `vbcc` directory).
	4. Inside the archive you downloaded, there are two directories we're interested in: `include` and `lib`, located in `<root of archive>/vbcc_target_m68k-kick13/targets/m68k-kick13`. Extract these to your new `vbcc13` directory, so you end up with `C:\amiga-gcc\m68k-amigaos\vbcc13\include` and `C:\amiga-gcc\m68k-amigaos\vbcc13\lib`, for example.

### All platforms

1. __(Optional)__ Download and install [amitools](https://github.com/cnvogelg/amitools) for creating a bootable ADF disk image.
2. __(Optional)__ Download and install [Cppcheck](http://cppcheck.sourceforge.net/) for performing source code linting.

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

## Static analysis

If you installed `Cppcheck`, you can run `make cppcheck` to perform a static analysis of all C code in the project. This can be helpful to find obscure bugs or error-prone code that may not cause the compiler to throw a warning.