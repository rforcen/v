/*
 float 128 wrapper
*/
module numv

#flag -I. -Isrc -lm
#include "float128.h"

pub struct F128 {
mut:
	data [16]u8
}

// pub const zero = F128{}
// pub const one = from_string('1')
pub const zero_f128 = F128{}
pub const one_f128 = from_int(1)

// c string conversion funcs wrap
fn C.str2f128(s &char) F128
fn C.f128_2_str(f [16]u8) &char // must free!!

// type conversion
fn C.f128_to_f64(f [16]u8) f64
fn C.f128_to_f32(f [16]u8) f32
fn C.f128_to_int(f [16]u8) int
fn C.f128_from_f64(f f64, res [16]u8)
fn C.f128_from_f32(f f32, res [16]u8)
fn C.f128_from_int(f int, res [16]u8)

// operators
fn C.f128_add(f1 [16]u8, f2 [16]u8, r [16]u8)
fn C.f128_sub(f1 [16]u8, f2 [16]u8, r [16]u8)
fn C.f128_mul(f1 [16]u8, f2 [16]u8, r [16]u8)
fn C.f128_div(f1 [16]u8, f2 [16]u8, r [16]u8)
fn C.f128_neg(f1 [16]u8, r [16]u8)

fn C.f128_eq(f1 [16]u8, f2 [16]u8) bool
fn C.f128_lt(f1 [16]u8, f2 [16]u8) bool
fn C.f128_gt(f1 [16]u8, f2 [16]u8) bool
fn C.f128_le(f1 [16]u8, f2 [16]u8) bool
fn C.f128_ge(f1 [16]u8, f2 [16]u8) bool
fn C.f128_ne(f1 [16]u8, f2 [16]u8) bool
fn C.f128_is_zero(f1 [16]u8) bool
fn C.f128_is_nan(f1 [16]u8) bool
fn C.f128_is_inf(f1 [16]u8) bool

// funcs
fn C.f128_sqrt(f1 [16]u8, res [16]u8)
fn C.f128_sin(f1 [16]u8, res [16]u8)
fn C.f128_cos(f1 [16]u8, res [16]u8)
fn C.f128_tan(f1 [16]u8, res [16]u8)
fn C.f128_asin(f1 [16]u8, res [16]u8)
fn C.f128_acos(f1 [16]u8, res [16]u8)
fn C.f128_atan(f1 [16]u8, res [16]u8)
fn C.f128_atan2(f1 [16]u8, f2 [16]u8, res [16]u8)
fn C.f128_exp(f1 [16]u8, res [16]u8)
fn C.f128_log(f1 [16]u8, res [16]u8)
fn C.f128_log10(f1 [16]u8, res [16]u8)
fn C.f128_log2(f1 [16]u8, res [16]u8)
fn C.f128_pow(f1 [16]u8, f2 [16]u8, res [16]u8)
fn C.f128_ceil(f1 [16]u8, res [16]u8)
fn C.f128_floor(f1 [16]u8, res [16]u8)
fn C.f128_round(f1 [16]u8, res [16]u8)
fn C.f128_trunc(f1 [16]u8, res [16]u8)
fn C.f128_fabs(f1 [16]u8, res [16]u8)
fn C.f128_fmod(f1 [16]u8, f2 [16]u8, res [16]u8)
fn C.f128_fmodf(f1 [16]u8, f2 [16]u8, res [16]u8)
fn C.f128_rand(res [16]u8)
fn C.f128_seed()

// v primitives
pub fn from_string(s string) F128 {
	return unsafe { F128{
		data: C.str2f128(s.str).data
	} }
}

pub fn (f F128) str() string {
	// println('f: ${f.data}')
	cs := C.f128_2_str(f.data)
	s := unsafe { cstring_to_vstring(cs) }
	unsafe { free(cs) }
	return s
}

// operators

@[inline]
pub fn (a F128) + (b F128) F128 {
	f := F128{}
	C.f128_add(a.data, b.data, f.data)
	return f
}

@[inline]
pub fn (a F128) - (b F128) F128 {
	f := F128{}
	C.f128_sub(a.data, b.data, f.data)
	return f
}
@[inline]
pub fn (a F128) negate() F128 {
	f := F128{}
	C.f128_neg(a.data, f.data)
	return f
}

@[inline]
pub fn (a F128) * (b F128) F128 {
	f := F128{}
	C.f128_mul(a.data, b.data, f.data)
	return f
}

// @[inline]
pub fn (a F128) / (b F128) F128 {
	f := F128{}
	C.f128_div(a.data, b.data, f.data)
	return f
}

// comparison
@[inline]
pub fn (a F128) == (b F128) bool {
	return C.f128_eq(a.data, b.data)
}

@[inline]
pub fn (a F128) < (b F128) bool {
	return C.f128_lt(a.data, b.data)
}

@[inline]
pub fn (a F128) is_zero() bool {
	return C.f128_is_zero(a.data)
}

@[inline]
pub fn (a F128) is_nan() bool {
	return C.f128_is_nan(a.data)
}

@[inline]
pub fn (a F128) is_inf() bool {
	return C.f128_is_inf(a.data)
}

pub fn cmp_int(a F128, b F128) int {
	if a > b {
		return 1
	}
	if a < b {
		return -1
	}
	return 0
}

// funcs
pub fn sqrt(a F128) F128 {
	f := F128{}
	C.f128_sqrt(a.data, f.data)
	return f
}

pub fn sin(a F128) F128 {
	f := F128{}
	C.f128_sin(a.data, f.data)
	return f
}

pub fn cos(a F128) F128 {
	f := F128{}
	C.f128_cos(a.data, f.data)
	return f
}

pub fn tan(a F128) F128 {
	f := F128{}
	C.f128_tan(a.data, f.data)
	return f
}

pub fn asin(a F128) F128 {
	f := F128{}
	C.f128_asin(a.data, f.data)
	return f
}

pub fn acos(a F128) F128 {
	f := F128{}
	C.f128_acos(a.data, f.data)
	return f
}

pub fn atan(a F128) F128 {
	f := F128{}
	C.f128_atan(a.data, f.data)
	return f
}

pub fn atan2(a F128, b F128) F128 {
	f := F128{}
	C.f128_atan2(a.data, b.data, f.data)
	return f
}

pub fn exp(a F128) F128 {
	f := F128{}
	C.f128_exp(a.data, f.data)
	return f
}

pub fn log(a F128) F128 {
	f := F128{}
	C.f128_log(a.data, f.data)
	return f
}

pub fn log10(a F128) F128 {
	f := F128{}
	C.f128_log10(a.data, f.data)
	return f
}

pub fn log2(a F128) F128 {
	f := F128{}
	C.f128_log2(a.data, f.data)
	return f
}

pub fn pow(a F128, b F128) F128 {
	f := F128{}
	C.f128_pow(a.data, b.data, f.data)
	return f
}

pub fn ceil(a F128) F128 {
	f := F128{}
	C.f128_ceil(a.data, f.data)
	return f
}

pub fn floor(a F128) F128 {
	f := F128{}
	C.f128_floor(a.data, f.data)
	return f
}

pub fn round(a F128) F128 {
	f := F128{}
	C.f128_round(a.data, f.data)
	return f
}

pub fn trunc(a F128) F128 {
	f := F128{}
	C.f128_trunc(a.data, f.data)
	return f
}

pub fn abs(a F128) F128 {
	f := F128{}
	C.f128_fabs(a.data, f.data)
	return f
}

pub fn rand() F128 {
	f := F128{}
	C.f128_rand(f.data)
	return f
}

pub fn (_ F128) seed() {
	C.f128_seed()
}

// converters
pub fn (f F128) f64() f64 {
	return C.f128_to_f64(f.data)
}

pub fn (f F128) f32() f32 {
	return C.f128_to_f32(f.data)
}

pub fn (f F128) int() int {
	return C.f128_to_int(f.data)
}

pub fn from_f64(v f64) F128 {
	res := F128{}
	C.f128_from_f64(v, res.data)
	return res
}

pub fn assign(v f64) F128 {
	res := F128{}
	C.f128_from_f64(v, res.data)
	return res
}

pub fn from_f32(v f32) F128 {
	res := F128{}
	C.f128_from_f32(v, res.data)
	return res
}

pub fn from_int(v int) F128 {
	res := F128{}
	C.f128_from_int(v, res.data)
	return res
}

// stats
pub fn std(arr []F128) F128 {
	if arr.len == 0 {
		return F128{}
	}

	n := arr.len
	mean := sum(arr) / from_int(n)
	mut sum_squared_diff := zero_f128

	for x in arr {
		diff := x - mean
		sum_squared_diff += diff * diff
	}

	variance := sum_squared_diff / from_int(n)
	std_dev := sqrt(variance)

	return std_dev
}

// Helper function to calculate the sum of a float array.
fn sum(arr []F128) F128 {
	mut total := F128{}
	for x in arr {
		total += x
	}
	return total
}
