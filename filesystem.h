/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * filesystem.h
 * File I/O functions.
 */

#ifndef FILE_SYSTEM_H
#define FILE_SYSTEM_H

#include <stdint.h>

#define MAX_FILE_NAME_LENGTH 	108
#define MAX_FILE_COUNT 			500

/* Smallest possible module = header + one pattern; no samples */
#define MIN_MODULE_FILE_SIZE 	2018

/* The BPM value given to modules with no tempo set on the first line */
#define DEFAULT_BPM				125

/* M.K. and M!K! */
#define PT_MAGIC				0x4D2E4B2EUL
#define PT_MAGIC_64_PAT			0x4D214B21UL

/* Offsets into the Protracker header */
#define PT_POSITION_OFFSET		952
#define PT_MAGIC_OFFSET			1080
#define PT_PATTERN_OFFSET		1084
#define PT_PATTERN_DATA_LEN		1024

/* Structure to hold entries in the file list */
typedef struct {
	uint32_t file_size;
	uint16_t bpm;
	uint16_t frames;
	char file_name[MAX_FILE_NAME_LENGTH];
} file_list_t;

file_list_t pt1210_file_list[MAX_FILE_COUNT];
uint16_t pt1210_file_count;

void pt1210_file_gen_list();
void pt1210_file_check_module(struct FileInfoBlock* fib);

/* TODO: Remove register mappings when we replace FS_LoadTune */
int pt1210_file_read(__reg("a0") const char* file_name, __reg("a1") void* buffer, __reg("d6") size_t seek_point, __reg("d7") size_t read_size);
void pt1210_file_read_error();

#endif /* FILE_SYSTEM_H */