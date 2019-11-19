# PT1210 Developer Notes

## Prerequisites

### Windows

#### CMake
1. Download and run the [*CMake* installer for Windows](https://cmake.org/download/) - choose the latest stable release.

#### Python 3
1. Download and run the latest [*Python* 3.x installer for Windows](https://www.python.org/downloads/). Ensure you check the **Add Python 3.x to PATH** option.
2. Open a command prompt, and type `pip3 install --user pyyaml` to install the *Python* YAML library.

#### Amiga GCC
1. Download and run the [`amiga-gcc` installer for Windows by bebbo](https://franke.ms/download/setup-amiga-gcc.exe).
2. In Windows System settings, add a new environment variable (either for your user or for the system; it doesn't matter) named `AMIGA_GCC` and point it to the root of your `amiga-gcc` installation (e.g. `C:\amiga-gcc`). This helps our build system find the necessary include paths for the assembler.
3. Edit the `PATH` variable to add `%AMIGA_GCC%\bin` to the list, which makes all of the `m68k-amigaos-*` tools as well as *GNU Make* available from any Windows command prompt.

### Linux
TODO

### All platforms

* __(Optional)__ Download and install [Cppcheck](http://cppcheck.sourceforge.net/) for performing source code linting.

## Building PT1210

PT-1210 uses the *CMake* build system generator, which makes it easier to build the software on various different host platforms and configurations.

We can currently generate two build types:

| Configuration | Description |
|---------------|-------------|
| `build-debug` | Enables debug symbols, defines the `DEBUG` C preprocessor definition (e.g. for enabling serial port debug print), and disables compiler optimizations. Links with `debug.lib`. For development and distributing to testers. |
| `build-release` | Enables `-Os` optimisations (smaller code size), and omits debug symbols. For distributing to users. |

Run the `generate_projects.bat` (Windows) or `generate_projects.sh` script (Linux) to generate the `build-debug` and `build-release` folders.

If the script succeeded, you can now compile PT-1210 by opening a terminal/command prompt, navigating to either `build-debug` or `build-release`, and typing `make`.

`make clean` will delete any built objects, returning the project directory to a clean state. Alternatively, you can delete the `build-debug` and `build-release` folders and re-run the project generation script.

## Static analysis

If you installed `Cppcheck`, additional diagnostics will be performed while building.

This can be helpful to find obscure bugs or error-prone code that may not cause the compiler to throw a warning.