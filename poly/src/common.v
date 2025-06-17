// common stuff for all module

module poly

import math { min }
import rand
import rand.pcg32
import rand.seed

struct Int4 {
pub mut:
	i0 int
	i1 int
	i2 int
	i3 int
}

struct VertexIndex {
pub mut:
	index  int
	vertex Vertex
}

struct I4Vix {
pub mut:
	index Int4
	vix   VertexIndex
}

struct DualFaces {
mut:
	face_org    []int // The original order of elements
	face_sorted []int // The sorted version of the elements
}

@[inline]
fn (i I4Vix) < (o I4Vix) bool {
	return i.index < o.index
}

@[inline]
fn (i Int4) < (o Int4) bool {
	if i.i0 != o.i0 {
		return i.i0 < o.i0
	}
	if i.i1 != o.i1 {
		return i.i1 < o.i1
	}
	if i.i2 != o.i2 {
		return i.i2 < o.i2
	}
	return i.i3 < o.i3
}

// Int4 contructors +1 to avoid 0
@[inline]
pub fn to_int4(i0 int, i1 int, i2 int, i3 int) Int4 {
	return Int4{
		i0: i0 + 1
		i1: i1 + 1
		i2: i2 + 1
		i3: i3 + 1
	}
}

@[inline]
pub fn to_int4_3(i0 int, i1 int, i2 int) Int4 {
	return Int4{
		i0: i0 + 1
		i1: i1 + 1
		i2: i2 + 1
	}
}

@[inline]
pub fn to_int4_2(i0 int, i1 int) Int4 {
	return Int4{
		i0: i0 + 1
		i1: i1 + 1
	}
}

@[inline]
pub fn to_int4_1(i0 int) Int4 {
	return Int4{
		i0: i0 + 1
	}
}

@[inline]
pub fn i4_min(i1 int, i2 int) Int4 {
	return if i1 < i2 { to_int4_2(i1, i2) } else { to_int4_2(i2, i1) }
}

@[inline]
pub fn i4_min3(i int, v1 int, v2 int) Int4 {
	return if v1 < v2 { to_int4_3(i, v1, v2) } else { to_int4_3(i, v2, v1) }
}

fn cmp_int4(a &Int4, b &Int4) int {
	if a.i0 != b.i0 {
		if a.i0 < b.i0 {
			return -1
		}
		return 1
	}
	if a.i1 != b.i1 {
		if a.i1 < b.i1 {
			return -1
		}
		return 1
	}
	if a.i2 != b.i2 {
		if a.i2 < b.i2 {
			return -1
		}
		return 1
	}
	if a.i3 != b.i3 {
		if a.i3 < b.i3 {
			return -1
		}
		return 1
	}
	return 0
}

pub fn (mut i4 []Int4) sort_int4() {
	i4.sort_with_compare(cmp_int4)
}

fn sort_clone(a []int) []int {
	mut a1 := a.clone()
	a1.sort()
	return a1
}

fn cmp_vint(a []int, b []int) int { // compare in sorted order
	if a.len != b.len {
		return a.len - b.len
	}

	mut a1 := sort_clone(a)
	mut b1 := sort_clone(b)

	for i in 0 .. a.len {
		if a1[i] != b1[i] {
			return a1[i] - b1[i]
		}
	}
	return 0
}

// Vertex helpers
@[inline]
pub fn midpoint(vec1 Vertex, vec2 Vertex) Vertex {
	return Vertex{
		x: (vec1.x + vec2.x) / 2
		y: (vec1.y + vec2.y) / 2
		z: (vec1.z + vec2.z) / 2
	}
}

@[inline]
pub fn tween(vec1 Vertex, vec2 Vertex, t f32) Vertex {
	return Vertex{ // vec1 * (1-t) + vec2 * t
		x: vec1.x * (1 - t) + vec2.x * t
		y: vec1.y * (1 - t) + vec2.y * t
		z: vec1.z * (1 - t) + vec2.z * t
	}
}

@[inline]
pub fn one_third(vec1 Vertex, vec2 Vertex) Vertex {
	return tween(vec1, vec2, f32(1.0) / f32(3.0))
}

fn unique[T](mut arr []T) {
	if arr.len == 0 {
		return
	}
	mut result := []T{cap: arr.len}
	result << arr[0]

	for i := 1; i < arr.len; i++ {
		if arr[i] != result[result.len - 1] {
			result << arr[i]
		}
	}

	arr = result.clone()
}

fn (mut arr [][]int) uniquev() {
	if arr.len == 0 {
		return
	}
	mut result := [][]int{cap: arr.len}
	result << arr[0]

	for i := 1; i < arr.len; i++ {
		if cmp_vint(arr[i], result[result.len - 1]) != 0 {
			result << arr[i]
		}
	}

	arr = result.clone()
}

fn lower_bound[T](arr []T, target T) T {
	mut low := 0
	mut high := arr.len
	mut ans := arr.len

	for low < high {
		mut mid := low + (high - low) / 2

		if arr[mid] >= target {
			ans = mid
			high = mid
		} else {
			low = mid + 1
		}
	}

	return if ans < arr.len { arr[ans] } else { arr[arr.len - 1] }
}

fn str2int(s string) int { // pack a string into an int
	mut i := 0
	unsafe { vmemmove(&i, s, min(s.len, int(sizeof(i)))) }
	return i
}

// Int4int

struct Int4int {
	i4_ Int4
	i   int
}

fn new_face_map(p &Polyhedron) []Int4int {
	mut face_map := []Int4int{}

	for i, face in p.faces {
		mut v1 := face[face.len - 1]
		for v2 in face {
			face_map << Int4int{
				i4_: to_int4_2(v1, v2)
				i:   i
			}
			v1 = v2
		}
	}
	face_map.sort_with_compare(fn (a &Int4int, b &Int4int) int {
		if a.i4_ < b.i4_ {
			return -1
		} else if a.i4_ > b.i4_ {
			return 1
		} else {
			return 0
		}
	})
	return face_map
}

fn (a Int4int) < (b Int4int) bool {
	if a.i4_ < b.i4_ {
		return true
	} else {
		return false
	}
}

fn (face_map []Int4int) find(k Int4) Int4 {
	return to_int4_1(lower_bound(face_map, Int4int{ i4_: k }).i)
}

// hash section
@[inline]
fn (i Int4) hash1() u64 { // first attenmpt, simple but effective
	return (u64(i.i0) << 32) ^ (u64(i.i1) << 24) ^ (u64(i.i2) << 16) ^ u64(i.i3)
}

// optimal implementation
const prime1 = u64(0x9e3779b97f4a7c15)
const prime2 = u64(0xbf58476d1ce4e5b9)
const fnv_offset_basis = u64(0xcbf29ce484222325)
const final_mixer = u64(0xff51afd7ed558ccd)

@[inline]
fn (i Int4) hash() u64 {
	mut h := fnv_offset_basis
	h = (h ^ u64(i.i0)) * prime1
	h = (h ^ u64(i.i1)) * prime2
	h = (h ^ u64(i.i2)) * prime1
	h = (h ^ u64(i.i3)) * prime2

	return (h ^ (h >> 33)) * final_mixer ^ ((h ^ (h >> 33)) * final_mixer >> 33)
}

//
pub fn build(tr_name string) &Polyhedron {
	mut p := Polyhedron{
		name: tr_name
	}
	return p.rebuild()
}

fn (mut p Polyhedron) rebuild() &Polyhedron {
	name := p.name
	p = new_poly_by_name(name[name.len - 1])

	for i := name.len - 2; i >= 0; i-- {
		match name[i] {
			`k` {
				p = kiss_n(mut p, 0, 0.1)
			}
			`a` {
				p = ambo(mut p)
			}
			`q` {
				p = quinto(mut p)
			}
			`g` {
				p = gyro(mut p)
			}
			`h` {
				p = hollow(mut p)
			}
			`p` {
				p = propellor(mut p)
			}
			`c` {
				p = chamfer(mut p)
			}
			`i` {
				p = inset(mut p)
			}
			else {}
		}
	}
	p.recalc()
	return &p
}

fn build_rand(n int) &Polyhedron {
	// Initialise the generator struct (note the `mut`)
	mut rng := &rand.PRNG(pcg32.PCG32RNG{})
	rng.seed(seed.time_seed_array(pcg32.seed_len))

	mut random_index := rng.int_in_range(0, poly_initials.len) or { 0 }
	mut p := new_poly_by_name(poly_initials[random_index])

	for _ in 0 .. n {
		match rng.int_in_range(0, 'kaqghpci'.len) or { 0 } {
			0 { p = kiss_n(mut p, 0, 0.1) }
			1 { p = ambo(mut p) }
			2 { p = quinto(mut p) }
			3 { p = gyro(mut p) }
			4 { p = hollow(mut p) }
			5 { p = propellor(mut p) }
			6 { p = chamfer(mut p) }
			7 { p = inset(mut p) }
			else {}
		}
	}
	return p
}
