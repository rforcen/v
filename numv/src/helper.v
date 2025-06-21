module numv

import strconv { v_sprintf }
import arrays { append }

// .npy file struct
struct HeaderNPY {
	id0      u8 = u8(`\x93`)
	id1      u8 = u8(`N`)
	id2      u8 = u8(`U`)
	id3      u8 = u8(`M`)
	id4      u8 = u8(`P`)
	id5      u8 = u8(`Y`)
	min_ver  u8 = 1
	max_ver  u8 // = 0
	head_len u16
}

@[inline]
fn (nv Numv) calc_index(ix []int) u64 {
	mut res := u64(0)
	for i in 0 .. ix.len {
		res += u64(ix[i]) * u64(nv.mlt[i])
	}
	if res >= nv.size {
		panic('index out of range, ${res} >= ${nv.size}')
	}
	return res
}

@[inline]
fn (nv Numv) get__[T](i u64) T {
	return unsafe { &T(nv.pdata)[i] }
}

@[inline]
fn (mut nv Numv) set__[T](i u64, v T) {
	unsafe { &T(nv.pdata)[i] = v }
}

fn size_type(dtype DataType) u64 {
	match dtype {
		.f16_ { return 2 }
		.f32_ { return 4 }
		.f64_ { return 8 }
		.f128_ { return 16 }
	}
}

pub fn (nv Numv) str_flat() string {
	mut s := ''

	for i in 0 .. nv.size {
		match nv.dtype {
			//.f16_ { s += unsafe { &f16(&nv.data[0])[i] }.str() }
			.f32_ { s += nv.get__[f32](i).str() }
			.f64_ { s += nv.get__[f64](i).str() }
			.f128_ { s += nv.get__[F128](i).str() }
			else {}
		}
		s += ', '
		if (i + 1) % nv.dim0 == 0 {
			s += '\n'
		}
	}
	s += '\n'
	return s
}

pub fn (nv Numv) str() string {
	return nv.u8_recursive(0, mut nv.dims.clone())[..].bytestr()
}

fn (nv Numv) to_string(i u64) string {
	match nv.dtype {
		.f32_ {
			x := nv.get__[f32](i)
			return unsafe { v_sprintf('%.${nv.prec_decs}e', x) }
		}
		.f64_ {
			x := nv.get__[f64](i)
			return unsafe { v_sprintf('%.${nv.prec_decs}e', x) }
		}
		.f128_ {
			x := nv.get__[F128](i)
			return x.str()
		}
		else {
			return '0'
		}
	}
}

pub fn (nv Numv) u8_recursive(current_dim int, mut indices []int) []u8 {
	mut s := []u8{}
	if current_dim == nv.dims.len { // Base case: print the element
		index := nv.calc_index(indices)
		s << nv.to_string(index).bytes()
		return s
	}

	s << '['.bytes()
	for i in 0 .. nv.dims[current_dim] {
		indices[current_dim] = i
		s << nv.u8_recursive(current_dim + 1, mut indices)
		if i < nv.dims[current_dim] - 1 {
			s << ', '.bytes()
		}
	}
	s << ']'.bytes()

	// if (current_dim == 0 && indices[0] < dims[0] -1) s+="\n";
	if current_dim == 1 {
		s << '\n'.bytes()
	}
	if current_dim < nv.dims.len - 1 && indices[current_dim] < nv.dims[current_dim] - 1 {
		s << ', '.bytes()
	}

	return s
}

pub fn (nv Numv) str_recursive(current_dim int, mut indices []int) string {
	mut s := ''
	if current_dim == nv.dims.len { // Base case: print the element
		index := nv.calc_index(indices)
		s += nv.to_string(index)
		return s
	}

	s += '['
	for i in 0 .. nv.dims[current_dim] {
		indices[current_dim] = i
		s += nv.str_recursive(current_dim + 1, mut indices)
		if i < nv.dims[current_dim] - 1 {
			s += ', '
		}
	}
	s += ']'

	// if (current_dim == 0 && indices[0] < dims[0] -1) s+="\n";
	if current_dim == 1 {
		s += '\n'
	}
	if current_dim < nv.dims.len - 1 && indices[current_dim] < nv.dims[current_dim] - 1 {
		s += ', '
	}

	return s
}

fn (nv Numv) assert_quadratic() {
	if nv.dims.len != 2 {
		panic('assert_quadratic: nv.dims.len != 2, ${nv.dims.len}')
	}
	if nv.dims[0] != nv.dims[1] {
		panic('assert_quadratic: nv.dims[0] != nv.dims[1], ${nv.dims}[0] != ${nv.dims}[1]')
	}
}

@[inline]
fn (nv Numv) get2[T](i u64, j u64) T {
	if i * nv.dim0 + j >= nv.size {
		panic('set2: index out of range, ${i * nv.dim0 + j} >= ${nv.size}')
	}
	return unsafe { &T(nv.pdata)[i * nv.dim0 + j] }
}

@[inline]
fn (mut nv Numv) set2[T](i u64, j u64, v T) {
	if i * nv.dim0 + j >= nv.size {
		panic('set2: index out of range, ${i * nv.dim0 + j} >= ${nv.size}')
	}
	unsafe {
		&T(nv.pdata)[i * nv.dim0 + j] = v
	}
}

pub fn (nv Numv) clone() Numv { // clone data (deep copy)
	mut res := nv // shallow copy
	// clone arrays
	res.data = nv.data.clone()
	res.pdata = &res.data[0]
	res.dims = nv.dims.clone()
	res.mlt = nv.mlt.clone()

	return res
}

fn combinations(limits []int) [][]int { // generate all combinations of limits - 1
	mut cmb := []int{len: limits.len}

	ncb := prod(limits)
	mut res := [][]int{len: int(ncb)}

	for i in 0 .. ncb {
		res[i] = cmb.clone()

		mut idx := limits.len - 1 // rightmost to inc.
		for idx >= 0 && cmb[idx] == limits[idx] - 1 {
			idx--
		}

		if idx < 0 {
			break // If no such element exists, we are done
		}
		cmb[idx]++ // Increment this element

		// Reset all elements to the right of this element
		for j in idx + 1 .. limits.len {
			cmb[j] = 0
		}
	}

	return res
}

fn (nv Numv) slice(index []int) Numv {
	istart := nv.calc_index(append(index, [0].repeat(nv.ndims - index.len)))
	iend := nv.calc_index(append(index, nv.dims[index.len..nv.ndims].map(it - 1))) + 1

	mut res := new_numv(nv.dtype, nv.dims[index.len..nv.ndims])
	unsafe { vmemcpy(res.pdata, &nv.data[istart * u64(nv.sz_type)], (iend - istart) * u64(nv.sz_type)) }
	return res
}

// u8 <--> string converters
pub fn u8_to_string(u []u8) string {
	return u[..].bytestr()
}

pub fn string_to_u8(s string) []u8 {
	return s.bytes()
}

fn identity(dtype DataType, n int) Numv {
	mut res := new_numv(dtype, [n, n])
	res.fill(0.0)
	for i in 0 .. n {
		match dtype {
			.f32_ {
				res.set2[f32](i, i, 1.0)
			}
			.f64_ {
				res.set2[f64](i, i, 1.0)
			}
			.f128_ {
				res.set2[F128](i, i, one_f128)
			}
			else {
				panic('identity: unknown dtype')
			}
		}
	}
	return res
}

// inv support
@[inline]
fn (mut nv Numv) swap[T](i u64, j u64, k u64, l u64) {
	mut tmp := nv.get2[T](i, j)
	nv.set2[T](i, j, nv.get2[T](k, l))
	nv.set2[T](k, l, tmp)
}

fn numpy_fmt(v []int) string {
	mut s := ''
	for i in 0 .. v.len {
		s += v[i].str() + ','
	}
	return s
}

fn (nv Numv) dim(ix int) int {
	return nv.dims[nv.ndims - 1 - ix]
}

fn prod(v []int) u64 {
	mut p := u64(1)
	for i in v {
		p *= u64(i)
	}
	if int(p) < 0 {
		panic('size of array too big: overflow')
	}
	return p
}

fn (nv Numv) sum_typed[T](init T) T {
	mut res := init

	for i in 0 .. nv.size {
		res += nv.get__[T](i)
	}

	return res
}

