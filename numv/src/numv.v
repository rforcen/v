// numv numpy inspired numeric vector operations

module numv

import rand
import rand.pcg32
import rand.seed
import os
import strings { repeat }
import strconv

//

pub enum DataType {
	f16_
	f32_
	f64_
	f128_
}

// @[heap] // this slows down in a factor of > 170!!
pub struct Numv {
mut:
	data  []u8
	pdata &u8 = unsafe { nil }

	dim0      u64
	dims      []int
	mlt       []int
	ndims     int
	sz_type   int
	dtype     DataType
	char_type u8  = u8(`f`)
	prec_decs int = 4
pub:
	size       u64
	size_bytes u64
}

pub fn new_numv(dtype DataType, dims []int) Numv {
	mut size := prod(dims)
	if int(size) < 0 {
		panic('new_numv: array size too large')
	}
	mut size_bytes := size * size_type(dtype)

	mut nv := Numv{
		data: []u8{len: int(size_bytes)}

		dtype:      dtype
		dims:       dims.clone()
		mlt:        calc_mlt(dims)
		ndims:      dims.len
		sz_type:    int(size_type(dtype))
		char_type:  u8(`f`)
		dim0:       u64(if dims.len > 0 { dims[dims.len - 1] } else { 0 })
		size:       size
		size_bytes: size_bytes
	}
	nv.pdata = &nv.data[0]
	return nv
}

fn calc_mlt(dims []int) []int {
	mut mlt := []int{len: dims.len}
	mut nn := 1
	for i in 0 .. dims.len {
		mlt[dims.len - 1 - i] = nn
		nn *= dims[dims.len - 1 - i]
	}
	return mlt
}

pub fn rand_numv(dtype DataType, dims []int) Numv {
	mut nv := new_numv(dtype, dims)
	return nv.rand()
}

pub fn (mut nv Numv) fill(v f64) {
	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				nv.set__[f32](i, f32(v))
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				nv.set__[f64](i, v)
			}
		}
		.f128_ {
			for i in 0 .. nv.size {
				nv.set__[F128](i, from_f64(v))
			}
		}
		else {}
	}
}

pub fn (mut nv Numv) rand() Numv {
	mut rng := &rand.PRNG(pcg32.PCG32RNG{})
	rng.seed(seed.time_seed_array(pcg32.seed_len))

	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				nv.set__[f32](i, rng.f32())
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				nv.set__[f64](i, rng.f64())
			}
		}
		.f128_ {
			for i in 0 .. nv.size {
				nv.set__[F128](i, from_f64(rng.f64()))
			}
		}
		else {
			panic('unknown dtype')
		}
	}
	return nv
}

pub fn (mut nv Numv) ones() {
	nv.fill(1.0)
}

pub fn (mut nv Numv) zeros() {
	nv.fill(0.0)
}

pub fn (nv Numv) size() u64 {
	return nv.size
}

// index
@[inline]
pub fn (nv Numv) get[T](ix []int) T {
	return nv.get__[T](nv.calc_index(ix))
}

@[inline]
pub fn (mut nv Numv) set(ix []int, v f64) {
	match nv.dtype {
		.f32_ {
			nv.set__[f32](nv.calc_index(ix), f32(v))
		}
		.f64_ {
			nv.set__[f64](nv.calc_index(ix), v)
		}
		else {
			panic('unknown dtype')
		}
	}
}

pub fn (mut nv Numv) set_f128(ix []int, v F128) {
	nv.set__[F128](nv.calc_index(ix), v)
}

// arithmetics
pub fn (nv Numv) + (v Numv) Numv {
	mut res := new_numv(nv.dtype, nv.dims)
	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				res.set__[f32](i, nv.get__[f32](i) + v.get__[f32](i))
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				res.set__[f64](i, nv.get__[f64](i) + v.get__[f64](i))
			}
		}
		else {}
	}
	return res
}

pub fn (nv Numv) - (v Numv) Numv {
	mut res := new_numv(nv.dtype, nv.dims)
	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				res.set__[f32](i, nv.get__[f32](i) - v.get__[f32](i))
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				res.set__[f64](i, nv.get__[f64](i) - v.get__[f64](i))
			}
		}
		else {}
	}
	return res
}

pub fn (nv Numv) * (v Numv) Numv {
	mut res := new_numv(nv.dtype, nv.dims)
	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				res.set__[f32](i, nv.get__[f32](i) * v.get__[f32](i))
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				res.set__[f64](i, nv.get__[f64](i) * v.get__[f64](i))
			}
		}
		else {}
	}
	return res
}

pub fn (nv Numv) / (v Numv) Numv {
	mut res := new_numv(nv.dtype, nv.dims)
	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				res.set__[f32](i, nv.get__[f32](i) / v.get__[f32](i))
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				res.set__[f64](i, nv.get__[f64](i) / v.get__[f64](i))
			}
		}
		else {}
	}
	return res
}

pub fn (mut nv Numv) addc(c f64) {
	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				nv.set__[f32](i, nv.get__[f32](i) + f32(c))
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				nv.set__[f64](i, nv.get__[f64](i) + c)
			}
		}
		else {}
	}
}

pub fn (mut nv Numv) subc(c f64) {
	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				nv.set__[f32](i, nv.get__[f32](i) - f32(c))
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				nv.set__[f64](i, nv.get__[f64](i) - c)
			}
		}
		else {}
	}
}

pub fn (mut nv Numv) mulc(c f64) {
	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				nv.set__[f32](i, nv.get__[f32](i) * f32(c))
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				nv.set__[f64](i, nv.get__[f64](i) * c)
			}
		}
		else {}
	}
}

pub fn (mut nv Numv) divc(c f64) {
	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				nv.set__[f32](i, nv.get__[f32](i) / f32(c))
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				nv.set__[f64](i, nv.get__[f64](i) / c)
			}
		}
		else {}
	}
}

pub fn (mut nv Numv) reshape(dims []int) Numv {
	if prod(nv.dims) != prod(dims) {
		panic('reshape: sizes do not match')
	}
	nv.dims = dims.clone()
	nv.mlt = calc_mlt(dims)
	nv.ndims = dims.len
	nv.dim0 = u64(if dims.len > 0 { dims[dims.len - 1] } else { 0 })

	return nv
}

// logic
fn (nv Numv) == (v Numv) bool {
	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				if nv.get__[f32](i) != v.get__[f32](i) {
					return false
				}
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				if nv.get__[f64](i) != v.get__[f64](i) {
					return false
				}
			}
		}
		else {}
	}
	return true
}

fn (nv Numv) < (v Numv) bool {
	match nv.dtype {
		.f32_ {
			for i in 0 .. nv.size {
				if nv.get__[f32](i) >= v.get__[f32](i) {
					return false
				}
			}
		}
		.f64_ {
			for i in 0 .. nv.size {
				if nv.get__[f64](i) >= v.get__[f64](i) {
					return false
				}
			}
		}
		else {}
	}
	return true
}

// sort
pub fn (mut nv Numv) sort() {
	match nv.dtype {
		// sort a [] copy of pdata
		.f32_ {
			mut vf := []f32{len: int(nv.size)}
			unsafe { vmemcpy(&vf[0], nv.pdata, nv.size_bytes) } // vf=nv.pdata
			vf.sort()
			unsafe { vmemcpy(nv.pdata, &vf[0], nv.size_bytes) } // nv.pdata=vf
		}
		.f64_ {
			mut vf := []f64{len: int(nv.size)}
			unsafe { vmemcpy(&vf[0], nv.pdata, nv.size_bytes) } // vf=nv.pdata
			vf.sort()
			unsafe { vmemcpy(nv.pdata, &vf[0], nv.size_bytes) } // nv.pdata=vf
		}
		.f128_ {
			mut vf := []F128{len: int(nv.size)}
			unsafe { vmemcpy(&vf[0], nv.pdata, nv.size_bytes) } // vf=nv.pdata
			vf.sort_with_compare(fn (a &F128, b &F128) int {
				return cmp_int(*a, *b)
			})
			unsafe { vmemcpy(nv.pdata, &vf[0], nv.size_bytes) } // nv.pdata=vf
		}
		else {}
	}
}

fn (mut nv Numv) setv(ix []int, sl Numv) {
	mut idx := nv.calc_index(ix)
	match nv.dtype {
		.f32_ {
			for i in 0 .. sl.size {
				nv.set__[f32](idx + i, sl.get__[f32](i))
			}
		}
		.f64_ {
			for i in 0 .. sl.size {
				nv.set__[f64](idx + i, sl.get__[f64](i))
			}
		}
		else {}
	}
}

// file io
fn (nv Numv) save(name string) ! {
	mut desc := "{'descr':'<${nv.char_type.ascii_str()}${nv.sz_type}', 'fortran_order':False, 'shape':(${numpy_fmt(nv.dims)})}"

	sz_hdr := int(sizeof(HeaderNPY)) + desc.len + 1 // header size + $0a
	desc += repeat(` `, 64 * ((sz_hdr / 64) + 1) - sz_hdr) + '\x0a'

	hdr := HeaderNPY{
		head_len: u16(desc.len)
	}

	mut f := os.create(name)!
	unsafe { f.write_ptr(&hdr, int(sizeof(HeaderNPY))) } // header
	f.write_string(desc)! // description
	f.write(nv.data)! // data

	f.close()
}

fn load(name string) !Numv {
	mut f := os.open(name)!

	mut hdr := HeaderNPY{} // read header
	unsafe { f.read_into_ptr(&u8(&hdr), int(sizeof(HeaderNPY)))! } // header

	mut desc_u8 := []u8{len: int(hdr.head_len)} // read description
	unsafe { f.read_into_ptr(&desc_u8[0], desc_u8.len) }
	mut desc := u8_to_string(desc_u8)

	// extract type and len
	mut dtype_str := strings.find_between_pair_rune(desc, `<`, `'`) // "'descr':'<f8'" -> f8
	mut dtype := DataType.f64_
	match dtype_str {
		'f8' {
			dtype = DataType.f64_
		}
		'f4' {
			dtype = DataType.f32_
		}
		else {}
	}

	// extract dims
	mut dims_str := strings.find_between_pair_rune(desc, `(`, `,`) // 'shape':(90,40,40,)
	mut dims := []int{}
	for s in dims_str.split(',') {
		dims << strconv.atoi(s)!
	}

	mut nv := new_numv(dtype, dims)
	f.read_into_ptr(&nv.data[0], int(nv.size_bytes))!
	f.close()
	return nv
}

// utils
fn (nv Numv) sum() f64 {
	match nv.dtype {
		.f32_ {
			return f64(nv.sum_typed[f32](f32(0)))
		}
		.f64_ {
			return f64(nv.sum_typed[f64](f64(0)))
		}
		.f128_ {
			return nv.sum_typed[F128](F128{}).f64()
		}
		else {
			panic('sum: unknown dtype')
		}
	}
}

fn (nv Numv) retype(dtype DataType) Numv {
	mut res := new_numv(dtype, nv.dims)

	match nv.dtype {
		.f32_ {
			match dtype {
				.f32_ {
					res = nv.clone()
				}
				.f64_ {
					for i in 0 .. nv.size {
						res.set__[f64](i, f64(nv.get__[f32](i)))
					}
				}
				.f128_ {
					for i in 0 .. nv.size {
						res.set__[F128](i, from_f32(nv.get__[f32](i)))
					}
				}
				else {
					panic('retype: unknown dtype')
				}
			}
		}
		.f64_ {
			match dtype {
				.f32_ {
					for i in 0 .. nv.size {
						res.set__[f32](i, f32(nv.get__[f64](i)))
					}
				}
				.f64_ {
					res = nv.clone()
				}
				.f128_ {
					for i in 0 .. nv.size {
						res.set__[F128](i, from_f64(nv.get__[f64](i)))
					}
				}
				else {
					panic('retype: unknown dtype')
				}
			}
		}
		.f128_ {
			match dtype {
				.f32_ {
					for i in 0 .. nv.size {
						res.set__[f32](i, nv.get__[F128](i).f32())
					}
				}
				.f64_ {
					for i in 0 .. nv.size {
						res.set__[f64](i, nv.get__[F128](i).f64())
					}
				}
				.f128_ {
					res = nv.clone()
				}
				else {
					panic('retype: unknown dtype')
				}
			}
		}
		else {
			panic('retype: unknown dtype')
		}
	}

	return res
}
