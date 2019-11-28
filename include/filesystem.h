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

#define MAX_FILE_NAME_LENGTH 	30
/* TODO: Make this dynamic */
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
#define PT_PATTERN_DATA_LEN		1024
#define PT_HEADER_LEN			1084

/* !FRM (frames-per-beat tag) */
#define FPB_MAGIC				0x2146524DUL
#define FPB_MAGIC_UPPER			0xFFDFDFDFUL

/* mod. prefix */
#define FS_MOD_PREFIX			0x4D4F442EUL
#define FS_MOD_PREFIX_UPPER		0xDFDFDFFFUL

/* .mod suffix */
#define FS_MOD_SUFFIX			0x2E4D4F44UL
#define FS_MOD_SUFFIX_UPPER		0xFFDFDFDFUL

/* Types of file list entries */
typedef enum {
	ENTRY_PARENT,
	ENTRY_VOLUME,
	ENTRY_ASSIGN,
	ENTRY_DIRECTORY,
	ENTRY_FILE,
} file_entry_t;

/* Structure to hold entries in the file list */
typedef struct {
	file_entry_t type;
	size_t file_size;
	uint16_t bpm;
	uint16_t frames;
	char file_name[MAX_FILE_NAME_LENGTH];
} file_list_t;

/* Structure to hold memory allocations */
typedef struct {
	size_t size;
	void* buffer;
} memory_buffer_t;

/* Keys for sorting the file list */
typedef enum
{
	SORT_NAME,
	SORT_BPM,
} file_sort_key_t;

void pt1210_file_initialize();
void pt1210_file_shutdown();
bool pt1210_file_change_dir(const char* path);
bool pt1210_file_parent_dir();
void pt1210_file_gen_file_list();
void pt1210_file_gen_volume_list();
const char* pt1210_file_dev_name_from_vol_name(const char* vol_name);
void pt1210_file_sort_list(file_sort_key_t key, bool ascending);
void pt1210_file_check_module(struct FileInfoBlock* fib);
bool pt1210_file_read(const char* file_name, void* buffer, size_t seek_point, size_t read_size);
void pt1210_file_load_module(size_t current);
void pt1210_file_free_tune_memory();

#endif /* FILE_SYSTEM_H */
