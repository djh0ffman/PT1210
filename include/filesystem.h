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

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include <proto/dos.h>

#define MAX_FILE_NAME_LENGTH 	108
#define MAX_FILE_NAME_DISPLAY	40
#define MAX_FILE_COUNT 			500

/* Smallest possible module = header + one pattern; no samples */
#define MIN_MODULE_FILE_SIZE 	2018

/* The BPM value given to modules with no tempo set on the first line */
#define DEFAULT_BPM				125

/* The default number of frames per beat; 4 rows * 6 frames */
#define DEFAULT_FPB				24

/* M.K. and M!K! */
#define PT_MAGIC				0x4D2E4B2EUL
#define PT_MAGIC_64_PAT			0x4D214B21UL

/* Offsets into the Protracker header */
#define PT_SMP_31_NAME_OFFSET	920
#define PT_SONG_LENGTH_OFFSET	950
#define PT_POSITION_OFFSET		952
#define PT_MAGIC_OFFSET			1080
#define PT_PATTERN_OFFSET		1084
#define PT_PATTERN_DATA_LEN		1024

/* !FRM (frames-per-beat tag) */
#define FPB_MAGIC				0x2146524DUL
#define FPB_MAGIC_UPPER			0xFFDFDFDFUL

/* mod. prefix */
#define FS_MOD_PREFIX			0x4D4F442EUL
#define FS_MOD_PREFIX_UPPER		0xDFDFDFFFUL

/* Structure to hold entries in the file list */
typedef struct {
	uint32_t file_size;
	uint16_t bpm;
	uint16_t frames;
	char file_name[MAX_FILE_NAME_LENGTH];
	char name[MAX_FILE_NAME_DISPLAY];
} file_list_t;

/* Keys for sorting the file list */
typedef enum
{
	SORT_DISPLAY_NAME,
	SORT_FILE_NAME,
	SORT_BPM,
} file_sort_key_t;

void pt1210_file_gen_list();
void pt1210_display_name(char* input, size_t count);
void pt1210_file_sort_list(file_sort_key_t key, bool ascending);
void pt1210_file_check_module(struct FileInfoBlock* fib);
bool pt1210_file_read(const char* file_name, void* buffer, size_t seek_point, size_t read_size);
void pt1210_file_read_error();
bool pt1210_file_find_first(char key, size_t* index);

#endif /* FILE_SYSTEM_H */