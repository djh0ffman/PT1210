/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * libraries.h
 * System library open/close functions for startup and shutdown.
 */

#ifndef LIBRARIES_H
#define LIBRARIES_H

#include <stdbool.h>

bool pt1210_libs_open();
void pt1210_libs_close();

#endif /* LIBRARIES_H */