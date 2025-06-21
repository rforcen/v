// lin alg : det, inv, dot

module numv

import arrays { append }
import math { min }

// dot
fn (nv Numv) dot(a Numv) Numv {
	match nv.dtype {
		.f32_ {
			return nv.dot_typed[f32](a)
		}
		.f64_ {
			return nv.dot_typed[f64](a)
		}
		.f128_ {
			return nv.dot_typed_f128(a)
		}
		else {
			panic('dot: unknown dtype')
		}
	}
}

// det
pub fn (nv Numv) det() Numv {
	if nv.dims.len == 2 {
		mut res := new_numv(nv.dtype, [1])
		match nv.dtype {
			.f32_ {
				res.set__[f32](0, nv.det_nxn_param[f32](f32(0), f32(1)))
			}
			.f64_ {
				res.set__[f64](0, nv.det_nxn_param[f64](f64(0), f64(1)))
			}
			.f128_ {
				res.set__[F128](0, nv.det_nxn_param[F128](zero_f128, one_f128))
			}
			else {}
		}
		return res
	} else {
		mut tdim := nv.dims[0..nv.dims.len - 2] // remove last two dimensions		
		mut res := new_numv(nv.dtype, tdim)

		for c in combinations(tdim) {
			match nv.dtype {
				.f32_ {
					res.set(c, nv.slice(c).det_nxn_param[f32](f32(0), f32(1)))
				}
				.f64_ {
					res.set(c, nv.slice(c).det_nxn_param[f64](f64(0), f64(1)))
				}
				.f128_ {
					res.set_f128(c, nv.slice(c).det_nxn_param[F128](zero_f128, one_f128))
				}
				else {}
			}
		}
		return res
	}
}

// inv
pub fn (nv Numv) inv() Numv {
	return if nv.ndims == 2 {
		nv.clone().inv_nxn_type()
	} else {
		mut res := nv.clone()
		for c in combinations(nv.dims[0..nv.dims.len - 2]) { // 0..-2 dims
			res.setv(c, nv.slice(c).inv_nxn_type())
		}
		res
	}
}

/////////////////////////////////////////////////////////////////////
// lin alg helpers

fn (nv Numv) det_nxn_param[T](zero_ T, one_ T) T { // det for n x n matrix (Bareiss algo.)
	nv.assert_quadratic()

	mut res := one_
	n := nv.dim0
	mut a := nv.clone()

	for i in 0 .. n {
		for j in i + 1 .. n {
			if a.get2[T](i, i) != zero_ {
				mut factor := a.get2[T](j, i) // / a-get2 generates error (compiler bug?)
				factor /= a.get2[T](i, i)
				for k in i .. n {
					a.set2[T](j, k, a.get2[T](j, k) - factor * a.get2[T](i, k))
				}
			}
		}
		res *= a.get2[T](i, i)
	}
	return res
}

fn (nv Numv) inv_nxn[T]() Numv {
	nv.assert_quadratic()

	mut n := nv.dim0
	mut res := identity(nv.dtype, int(n))
	mut a := nv.clone()

	for j in 0 .. n {
		for i in j .. n {
			if a.get2[T](i, j) != T(0.0) {
				for k in 0 .. n {
					a.swap[T](j, k, i, k)
					res.swap[T](j, k, i, k)
				}
				mut tmp := T(1.0) / a.get2[T](j, j)
				for k in 0 .. n {
					a.set2[T](j, k, a.get2[T](j, k) * tmp)
					res.set2[T](j, k, res.get2[T](j, k) * tmp)
				}

				for k in 0 .. n {
					if k != j {
						mut tmp1 := -a.get2[T](k, j)
						for c in 0 .. n {
							a.set2[T](k, c, a.get2[T](k, c) + tmp1 * a.get2[T](j, c))
							res.set2[T](k, c, res.get2[T](k, c) + tmp1 * res.get2[T](j, c))
						}
					}
				}
				break
			}
		}
	}

	return res
}

fn (nv Numv) inv_nxn_f128() Numv {
	nv.assert_quadratic()

	mut n := nv.dim0
	mut res := identity(nv.dtype, int(n))
	mut a := nv.clone()

	for j in 0 .. n {
		for i in j .. n {
			if a.get2[F128](i, j) != zero_f128 {
				for k in 0 .. n {
					a.swap[F128](j, k, i, k)
					res.swap[F128](j, k, i, k)
				}
				mut tmp := one_f128 / a.get2[F128](j, j)
				for k in 0 .. n {
					a.set2[F128](j, k, a.get2[F128](j, k) * tmp)
					res.set2[F128](j, k, res.get2[F128](j, k) * tmp)
				}

				for k in 0 .. n {
					if k != j {
						mut tmp1 := a.get2[F128](k, j).negate()
						for c in 0 .. n {
							a.set2[F128](k, c, a.get2[F128](k, c) + tmp1 * a.get2[F128](j, c))
							res.set2[F128](k, c, res.get2[F128](k, c) + tmp1 * res.get2[F128](j, c))
						}
					}
				}
				break
			}
		}
	}

	return res
}

fn (nv Numv) inv_nxn_type() Numv {
	match nv.dtype {
		.f32_ {
			return nv.inv_nxn[f32]()
		}
		.f64_ {
			return nv.inv_nxn[f64]()
		}
		.f128_ {
			return nv.inv_nxn_f128()
		}
		else {
			panic('inv_nxn_type: unknown dtype')
		}
	}
}

fn (nv Numv) prep_dot() (Numv, u64, u64, u64) {
	pivot_pos := min(1, nv.ndims - 1) // position in a of pivot dim in  1|0
	pivd := u64(nv.dim(pivot_pos)) // pivot dimension, a.dim(1|0) = dim(0)

	if nv.dim0 != pivd {
		panic('dot: shapes not aligned: ${nv.dim0} != ${pivd}, pivot_pos:${pivot_pos}, nv.dims:${nv.dims}')
	}

	sdim := nv.dims[..nv.ndims - 1]
	mut adim := nv.dims.clone() // remove 'pp' 0|1
	adim.delete(nv.ndims - 1 - pivot_pos)

	mut res_dim := append(sdim, adim) // resDim = sDim + aDim

	if res_dim.len == 0 {
		res_dim = [1]
	}

	prs := prod(sdim)
	return new_numv(nv.dtype, res_dim), u64(pivot_pos), pivd, u64(prs)
}

fn (nv Numv) dot_typed[T](a Numv) Numv {
	mut res, pivot_pos, pivd, prs := nv.prep_dot()

	match pivot_pos {
		0 {
			for s_start in 0 .. prs {
				mut p := T(0.0)
				for r in 0 .. pivd {
					p += nv.get__[T](s_start + r) * a.get__[T](r)
				}
				res.set__[T](s_start, p)
			}
		}
		1 {
			pra := if a.ndims > 2 { prod(a.dims[..a.dims.len - 2]) } else { 1 }
			mut a_stride := a.size / pra
			mut adim0 := u64(a.dim0)
			mut ahi0 := u64(a.dim0)
			mut ahi1 := if a.ndims > 1 { u64(a.dim(1)) } else { 1 }

			for ix in 0 .. prs {
				mut a_start := u64(0)
				mut s_start := u64(ix * pivd)
				mut ixr := u64(ix * (pra * adim0))

				for _ in 0 .. pra {
					for c in 0 .. ahi0 {
						mut p := T(0.0)
						for r in 0 .. ahi1 {
							p += nv.get__[T](s_start + r) * a.get__[T](a_start + r * adim0 + c)
						}
						res.set__[T](ixr, p)
						ixr++
					}
					a_start += a_stride
				}
			}
		}
		else {
			panic('dot: pivot_pos not 0 or 1')
		}
	}
	return res
}

fn (nv Numv) dot_typed_f128(a Numv) Numv {
	mut res, pivot_pos, pivd, prs := nv.prep_dot()

	match pivot_pos {
		0 {
			for s_start in 0 .. prs {
				mut p := zero_f128
				for r in 0 .. pivd {
					p += nv.get__[F128](s_start + r) * a.get__[F128](r)
				}
				res.set__[F128](s_start, p)
			}
		}
		1 {
			pra := if a.ndims > 2 { prod(a.dims[..a.dims.len - 2]) } else { 1 }
			mut a_stride := a.size / pra
			mut adim0 := u64(a.dim0)
			mut ahi0 := u64(a.dim0)
			mut ahi1 := if a.ndims > 1 { u64(a.dim(1)) } else { 1 }

			for ix in 0 .. prs {
				mut a_start := u64(0)
				mut s_start := u64(ix * pivd)
				mut ixr := u64(ix * (pra * adim0))

				for _ in 0 .. pra {
					for c in 0 .. ahi0 {
						mut p := zero_f128
						for r in 0 .. ahi1 {
							p += nv.get__[F128](s_start + r) * a.get__[F128](a_start + r * adim0 + c)
						}
						res.set__[F128](ixr, p)
						ixr++
					}
					a_start += a_stride
				}
			}
		}
		else {
			panic('dot: pivot_pos not 0 or 1')
		}
	}
	return res
}
