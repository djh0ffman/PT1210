/**
 *  ____ _____     _ ____  _  ___
 * |  _ |_   _|   / |___ \/ |/ _ \
 * | |_) || |_____| | __) | | | | |
 * |  __/ | |_____| |/ __/| | |_| |
 * |_|    |_|     |_|_____|_|\___/
 *
 * Protracker DJ Player
 *
 * filesystem.c
 * File I/O functions.
 */

#include <ctype.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include <proto/dos.h>

#include "filesystem.h"
#include "utility.h"

file_list_t pt1210_file_list[MAX_FILE_COUNT];
uint16_t pt1210_file_count;

/* Imported from ASM code */
extern char FS_LoadErrBuff[80];
void FS_DrawLoadError(REG(d0, int32_t error_code));

/* A generic comparator function pointer type */
typedef bool(*comparator_t)(const void*, const void*);

/* Comparator functions for sorting each of the file structure fields */
static inline bool pt1210_file_cmp_bpm(const void* a, const void* b)
{
	return ((file_list_t*)a)->bpm < ((file_list_t*)b)->bpm;
}

static inline bool pt1210_file_cmp_file_name(const void* a, const void* b)
{
	return strncmp(((file_list_t*)a)->file_name, ((file_list_t*)b)->file_name, MAX_FILE_NAME_LENGTH) < 0;
}

static inline bool pt1210_file_cmp_name(const void* a, const void* b)
{
	return strncmp(((file_list_t*)a)->name, ((file_list_t*)b)->name, MAX_FILE_NAME_DISPLAY) < 0;
}

/* Performs an in-place swap of two file list entries */
static inline void pt1210_file_swap(file_list_t* a, file_list_t* b)
{
	file_list_t temp = *a;
	*a = *b;
	*b = temp;
}

void pt1210_file_gen_list()
{
	BPTR folder_lock;
	struct FileInfoBlock fib;

	pt1210_file_count = 0;

	/* Lock the current directory for reading */
	folder_lock = Lock("", ACCESS_READ);
	if (!folder_lock)
		return;

	/* Iterate over directory contents and search for modules */
	if (Examine(folder_lock, &fib))
	{
		while (pt1210_file_count < MAX_FILE_COUNT)
		{
			if (!ExNext(folder_lock, &fib))
				break;

			/* Check this file is a module and add it to the file browser if so */
			pt1210_file_check_module(&fib);
		}
	}

	UnLock(folder_lock);
}

/* Function for white spacing and uppercase display name */
void pt1210_display_name(char *input, size_t count)
{
	for (int i = 0; i < count; i++)
	{
		char temp = input[i];
		if (temp == '\0')
			temp = ' ';

		input[i] = (char) toupper(temp);
	}
}

static int partition(int low, int high, comparator_t comparator, bool descending)
{
	file_list_t* pivot = &pt1210_file_list[high];
	int i = low - 1;
	for (int j = low; j <= high - 1; ++j)
	{
		if (comparator(&pt1210_file_list[j], pivot) ^ descending)
		{
			++i;
			pt1210_file_swap(&pt1210_file_list[i], &pt1210_file_list[j]);
		}
	}

	pt1210_file_swap(&pt1210_file_list[i + 1], &pt1210_file_list[high]);
	return i + 1;
}

static void quicksort(int low, int high, comparator_t comparator, bool descending)
{
	if (low < high)
	{
		size_t p = partition(low, high, comparator, descending);
		quicksort(low, p - 1, comparator, descending);
		quicksort(p + 1, high, comparator, descending);
	}
}

void pt1210_file_sort_list(file_sort_key_t key, bool descending)
{
	if (pt1210_file_count <= 1)
		return;

	/* Function pointer to the comparator we want to use */
	comparator_t comparator;

	switch (key)
	{
		case NAME: 			comparator = pt1210_file_cmp_name;			break;
		case FILE_NAME:		comparator = pt1210_file_cmp_file_name;		break;
		case BPM:			comparator = pt1210_file_cmp_bpm;			break;
		default:			return;
	}

	quicksort(0, pt1210_file_count - 1, comparator, descending);
}

void pt1210_file_check_module(struct FileInfoBlock* fib)
{
	file_list_t* list_entry = &pt1210_file_list[pt1210_file_count];
	uint32_t magic = 0;
	uint8_t first_pattern = 0;
	uint32_t pattern_row[4];
	uint32_t fpb_tag[2];
	uint32_t mod_tag = 0;

	/* Ignore files too small to be valid Protracker modules */
	if (fib->fib_Size < MIN_MODULE_FILE_SIZE)
		return;

	/* Check for valid magic numbers */
	pt1210_file_read(fib->fib_FileName, &magic, PT_MAGIC_OFFSET, sizeof(magic));
	if (magic != PT_MAGIC && magic != PT_MAGIC_64_PAT)
		return;

	/* Get number of first pattern */
	if (!pt1210_file_read(fib->fib_FileName, &first_pattern, PT_POSITION_OFFSET, sizeof(first_pattern)))
		return;

	/* Multiply to get offset into pattern data */
	size_t pattern_offset = PT_PATTERN_OFFSET + first_pattern * PT_PATTERN_DATA_LEN;

	/* Read first row of first pattern */
	if (!pt1210_file_read(fib->fib_FileName, pattern_row, pattern_offset, sizeof(pattern_row)))
		return;

	/* Store a default BPM */
	list_entry->bpm = DEFAULT_BPM;

	/* Iterate over the first row and look for FXX commands to determine BPM */
	for (uint8_t i = 0; i < 4; ++i)
	{
		/* Do we have a tempo command? */
		if ((pattern_row[i] & 0x0F00) != 0x0F00)
			continue;

		/* Parameters >= 0x20 are tempo; else frames per row ("SPD") */
		uint8_t param = pattern_row[i] & 0xFF;
		if (param >= 0x20)
		{
			list_entry->bpm = param;
			break;
		}
	}

	/* Look for a frames-per-beat tag in the name string of sample 31 */
	list_entry->frames = 0;
	if (!pt1210_file_read(fib->fib_FileName, fpb_tag, PT_SMP_31_NAME_OFFSET, sizeof(fpb_tag)))
		return;

	/* Force upper case on text */
	fpb_tag[0] &= FPB_MAGIC_UPPER;

	if (fpb_tag[0] == FPB_MAGIC)
	{
		uint8_t tens = (fpb_tag[1] >> 24) & 0x0F;
		uint8_t units = (fpb_tag[1] >> 16) & 0x0F;
		uint16_t fpb = (tens * 10) + units;

		if (fpb)
		{
			list_entry->frames = fpb;
			list_entry->bpm = list_entry->bpm * DEFAULT_FPB / fpb;
		}
	}

	/* Store file name */
	strncpy(list_entry->file_name, fib->fib_FileName, MAX_FILE_NAME_LENGTH);

	mod_tag = *(unsigned int*)fib->fib_FileName;
	mod_tag &= FS_MOD_PREFIX_UPPER;

	/* Create display name removing mod. prefix */
	if (mod_tag == FS_MOD_PREFIX)
		strncpy(list_entry->name, fib->fib_FileName + 4, MAX_FILE_NAME_DISPLAY - 4);
	else
		strncpy(list_entry->name, fib->fib_FileName, MAX_FILE_NAME_DISPLAY);

	/* clear display string with white space for text display */
	pt1210_display_name(list_entry->name, MAX_FILE_NAME_DISPLAY);

	/* Store file size */
	list_entry->file_size = fib->fib_Size;

	++pt1210_file_count;
}

bool pt1210_file_read(const char* file_name, void* buffer, size_t seek_point, size_t read_size)
{
	BPTR file;
	LONG result;

	file = Open(file_name, MODE_OLDFILE);
	if (!file)
	{
		pt1210_file_read_error();
		return false;
	}

	/* FIXME: Possible bug in Kickstarts v36/v37 not returning -1 on error */
	result = Seek(file, seek_point, OFFSET_BEGINNING);
	if (result == -1)
	{
		pt1210_file_read_error();
		Close(file);
		return false;
	}

	result = Read(file, buffer, read_size);
	if (result == -1)
		pt1210_file_read_error();

	Close(file);

	if (result != read_size)
		return false;

	/* Success */
	return true;
}

void pt1210_file_read_error()
{
	LONG error = IoErr();

	/* TODO: Use Fault() when it's available (Kickstart v36) */
	/* Fault(error, "", FS_LoadErrBuff, sizeof(FS_LoadErrBuff)); */

	FS_DrawLoadError(error);
}