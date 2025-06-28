/*
	Fstring fixed string mut s := str{10}{'hello'}  // Creates a fixed-length string initialized with 'hello'
	u8 as string replacement
*/
module noaa

const data_len = 16 // to accomodate a 11 char station

type SmallString = [data_len]u8

pub struct Fstring {
mut:
	data SmallString
}

pub fn fstring(u []u8) Fstring {
	mut fs := Fstring{}
	unsafe {
		C.memcpy(&fs.data[0], &u[0], min(u.len, fs.data.len))
	}
	return fs
}

pub fn fstring4(u [4]u8) Fstring {
	mut fs := Fstring{}
	unsafe {
		C.memcpy(&fs.data[0], &u[0], u.len)
	}
	return fs
}

pub fn fstring11(u [11]u8) Fstring {
	mut fs := Fstring{}
	unsafe {
		C.memcpy(&fs.data[0], &u[0], u.len)
	}
	return fs
}

pub fn fstr(s string) Fstring {
	mut fs := Fstring{}
	unsafe {
		C.memcpy(&fs.data[0], s.str, min(s.len, data_len))
	}
	return fs
}

@[inline]
pub fn copy(fs &Fstring, other &Fstring) {
	unsafe {
		C.memcpy(&fs.data[0], &other.data[0], other.len())
	}
}

@[inline]
pub fn (fs &Fstring) set(other &Fstring) {
	unsafe {
		C.memcpy(&fs.data[0], &other.data[0], other.len())
	}
}

pub fn (fs Fstring) data() []u8 {
	return fs.data[..]
}

@[inline]
pub fn (fs &Fstring) len() int {
	return fs.data.index(0)
}

pub fn (fs Fstring) str() string {
	return fs.data[..fs.len()].bytestr()
}

pub fn (fs Fstring) clone() Fstring {
	mut res := Fstring{}
	unsafe {
		C.memcpy(&res.data[0], &fs.data[0], fs.len())
	}
	return res
}

@[inline]
pub fn (mut fs Fstring) reset() {
	fs.data = [data_len]u8{}
}

// Operator overloading

// fast mt versions
pub fn (fs &Fstring) append(other &Fstring) {
	if fs.len() + other.len() < data_len {
		unsafe {
			C.memcpy(&fs.data[fs.len()], &other.data[0], other.len())
		}
	}
}

pub fn (fs &Fstring) eq(other &Fstring) bool {
	// for i in 0..min(fs.len(), other.len())
	for i := 0; fs.data[i] != 0 && other.data[i] != 0 && i < data_len; i++ {
		if fs.data[i] != other.data[i] {
			return false
		}
	}
	return true
}

pub fn (fs &Fstring) lt(other &Fstring) bool {
	for i := 0; fs.data[i] != 0 && other.data[i] != 0 && i < data_len; i++ {
		if fs.data[i] >= other.data[i] {
			return false
		}
	}
	return true
}

pub fn (fs &Fstring) le(other &Fstring) bool {
	for i := 0; fs.data[i] != 0 && other.data[i] != 0 && i < data_len; i++ {
		if fs.data[i] > other.data[i] {
			return false
		}
	}
	return true
}

pub fn (fs &Fstring) gt(other &Fstring) bool {
	return !fs.le(other)
}

pub fn (fs &Fstring) ge(other &Fstring) bool {
	return !fs.lt(other)
}

pub fn (fs &Fstring) ne(other &Fstring) bool {
	return !fs.eq(other)
}

// general purpose -> this is slow in mt
pub fn (fs Fstring) + (other Fstring) Fstring {
	mut result := Fstring{}
	if fs.data.index(0) + other.data.index(0) < data_len {
		unsafe {
			C.memcpy(&result.data[0], &fs.data[0], fs.data.index(0))
			C.memcpy(&result.data[fs.data.index(0)], &other.data[0], other.data.index(0))
		}
	}
	return result
}

pub fn (fs Fstring) == (other Fstring) bool {
	return fs.data[..] == other.data[..]
}

pub fn (fs Fstring) < (other Fstring) bool {
	return fs.str() < other.str()
}

// u8 <--> string converters
pub fn u8_to_string(u []u8) string {
	return u[..].bytestr()
}

pub fn string_to_u8(s string) []u8 {
	return s.bytes()
}

// helpers
@[inline]
fn min(a int, b int) int {
	return if a < b { a } else { b }
}
