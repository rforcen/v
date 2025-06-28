module noaa

// define struct, funcs
#include "arch.h"
#flag -larchive -I. -Isrc

// lib archive wrapper

// consts
const archive_ok = 0
const archive_eof = 1
const ae_ifreg = 0o100000 // #define AE_IFREG	((__LA_MODE_T)0100000)

// struct
struct C.archive {}

struct C.archive_entry {}

// funcs
fn C.archive_read_new() &C.archive
fn C.archive_read_support_filter_all(&C.archive) int
fn C.archive_read_support_format_tar(&C.archive) int
fn C.archive_entry_new() &C.archive_entry
fn C.archive_entry_free(&C.archive_entry)
fn C.archive_read_close(&C.archive) int
fn C.archive_read_free(&C.archive) int
fn C.archive_read_open_filename(&C.archive, &C.char, int) int
fn C.archive_read_next_header(&C.archive, &&C.archive_entry) int
fn C.archive_entry_pathname(&C.archive_entry) &char
fn C.archive_entry_size(&C.archive_entry) int
fn C.archive_entry_filetype(&C.archive_entry) int
fn C.archive_entry_clear(&C.archive_entry)
fn C.archive_read_data(&C.archive, &C.char, int) int
fn C.archive_error_string(&C.archive) &char

///////////////

// TarGZ struct

pub struct TarGz {
mut:
	archive   &C.archive // lib archive
	entry     &C.archive_entry
	file_name string // targz file name
	file_idx  int    // file index 0..

	fname     string // tar.gz content file name
	file_type int    // last targz file
	file_size int

	buff string // file content
}

pub fn new_targz() TarGz {
	unsafe {
		return TarGz{
			archive:   nil
			entry:     nil
			file_idx:  -1
			file_name: ''
			fname:     ''
			file_type: 0
			file_size: 0
			buff:      ''
		}
	}
}

pub fn open_targz(file_name string) !TarGz {
	unsafe {
		mut t := TarGz{
			file_name: file_name
			archive:   nil
			entry:     nil
			file_idx:  -1
		}

		t.archive = C.archive_read_new()
		if t.archive == nil {
			return error('targz.v : Error: Failed to create archive read object.')
		}

		C.archive_read_support_filter_all(t.archive) // Enable all supported decompression filters
		C.archive_read_support_format_tar(t.archive) // Enable TAR format

		if C.archive_read_open_filename(t.archive, file_name.str, 1024 * 10) != archive_ok {
			return error("targz.v : Error : can't open file ${file_name}")
		}

		t.entry = C.archive_entry_new()

		return t
	}
}

pub fn (mut t TarGz) reset() {
	t.close()
	t = open_targz(t.file_name) or { unsafe {
		TarGz{
			archive: nil
			entry:   nil
		}
	} }
}

pub fn (mut t TarGz) get_next() bool {
	C.archive_entry_clear(t.entry) // Clear entry for the next iteration	

	ret := C.archive_read_next_header(t.archive, &t.entry) != archive_eof
	if ret {
		fn_ptr := C.archive_entry_pathname(t.entry)

		t.file_size = C.archive_entry_size(t.entry)
		t.file_type = C.archive_entry_filetype(t.entry)
		t.fname = unsafe { fn_ptr.vstring() } // convert &char to string

		t.file_idx++
	}
	return ret
}

pub fn (mut t TarGz) next() ?TarGz {
	for {
		if !t.get_next() {
			return none
		}
		if t.is_daily() {
			if !t.read() {
				return none
			} else {
				break
			}
		}
	}
	return t
}

pub fn (t TarGz) is_file() bool {
	return t.file_type == ae_ifreg
}

pub fn (t TarGz) is_daily() bool {
	return t.is_file() && t.fname.contains('.dly')
}

pub fn (mut t TarGz) read() bool { // fill t.buff string
	buff := []u8{len: t.file_size} // read buffer
	read_len := C.archive_read_data(t.archive, &buff[0], t.file_size)

	t.buff = buff.bytestr() // convert []u8 -> string
	return read_len == t.file_size
}

pub fn (t TarGz) close() {
	C.archive_entry_free(t.entry)
	C.archive_read_close(t.archive)
}

pub fn (t TarGz) get_error() string {
	unsafe {
		return C.archive_error_string(t.archive).vstring()
	}
}

pub fn (t TarGz) get_data() string {
	return t.buff
}

pub fn (t TarGz) get_lines() []string {
	return t.buff.split('\n')
}

pub fn (t TarGz) nlines() int {
	return t.buff.count('\n')
}

pub fn (t TarGz) get_file_counter() int {
	return t.file_idx
}

pub fn (t TarGz) get_file_name() string {
	return t.fname
}

pub fn (t TarGz) get_file_size() int {
	return t.file_size
}
