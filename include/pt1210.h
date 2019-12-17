/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * pt1210.h
 * Main program task.
 */

#ifndef PT1210_H
#define PT1210_H

#include <stdbool.h>

/* A function pointer type to defer things that must run in the main Task */
typedef void (*deferred_function_t)();

void pt1210_defer_function(deferred_function_t func);
void pt1210_reset();
void pt1210_quit();
bool pt1210_initialize();
void pt1210_main();
void pt1210_shutdown();

#endif /* PT1210_H */
