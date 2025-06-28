module sh

import math
import os { create }
import runtime { nr_cpus }

const pi2 = math.pi * 2

pub struct SH {
mut:
	mesh          []Location
	faces         [][]int
	trigs         [][]int
	res           int = 256
	color_map     int = 7
	size          int
	code          int
	m             []int
	m0            f64
	m1            f64
	m2            f64
	m3            f64
	m4            f64
	m5            f64
	m6            f64
	m7            f64
	du            f64
	dv            f64
	du10          f64
	dv10          f64
	dx            f64
	max_val       f64 = -1
	single_thread bool
}

struct Location {
mut:
	coord   Coord
	normal  Coord
	color   Coord
	texture Coord
}

struct Mesh {
mut:
	coords   []Coord
	normals  []Coord
	colors   []Coord
	textures []Coord
}

////////////////////////////////////////
// Mesh methods
fn (mut sh_ SH) scale_coords() {
	if sh_.max_val != 0 {
		for i in 0 .. sh_.mesh.len {
			sh_.mesh[i].coord.mut_divc(sh_.max_val)
		}
	}
}

////////////////////////////////////////
// SH methods
pub fn new_sh(res int, color_map int, code int) SH {
	return new_sh_mode(res, color_map, code, false)
}

pub fn new_sh_mode(res int, color_map int, code int, single_thread bool) SH {
	mut sh_ := SH{
		res:       res
		size:      res * res
		color_map: color_map
		code:      code
		m:         to_intv(code)
		du:        pi2 / f64(res)
		dv:        math.pi / f64(res)
		dx:        1.0 / f64(res)
		max_val:   -1.0
		single_thread: single_thread
	}
	sh_.du10 = sh_.du / 10
	sh_.dv10 = sh_.dv / 10
	sh_.mesh = []Location{len: sh_.size}

	if sh_.single_thread {
		sh_.calc_mesh()
	} else {
		sh_.calc_mesh_parallel(nr_cpus())
	}
	return sh_
}

fn (mut sh_ SH) read_code(code_index int) {
	sh_.code = sh_codes[code_index % sh_codes.len]
	sh_.m = to_intv(sh_.code)
}

pub fn (mut sh_ SH) set_single_thread() {
	sh_.single_thread = true
}

pub fn (mut sh_ SH) set_multi_thread() {
	sh_.single_thread = false
}

fn pow_int(x f64, y int) f64 {
	match y {
		0 {
			return 1
		}
		1 {
			return x
		}
		2 {
			return x * x
		}
		3 {
			return x * x * x
		}
		4 {
			return x * x * x * x
		}
		5 {
			return x * x * x * x * x
		}
		6 {
			return x * x * x * x * x * x
		}
		7 {
			return x * x * x * x * x * x * x
		}
		8 {
			return x * x * x * x * x * x * x * x
		}
		else {
			mut r := f64(1)
			for _ in 0 .. y {
				r *= x
			}
			return r
		}
	}
}

fn pow_filt(x f64, y f64) f64 {
	return if y == 0 {
		1
	} else {
		p := math.pow(x, y)
		return if math.is_inf(p, 0) {
			0
		} else {
			p
		}
	}
}

fn (sh_ SH) calc_coord(theta f64, phi f64) Coord {
	mut sin_phi := math.sin(phi)
	mut r := pow_filt(math.sin(sh_.m[0] * phi), sh_.m[1])

	r += pow_filt(math.cos(sh_.m[2] * phi), sh_.m[3])
	r += pow_filt(math.sin(sh_.m[4] * theta), sh_.m[5])
	r += pow_filt(math.cos(sh_.m[6] * theta), sh_.m[7])

	return Coord{
		x: r * sin_phi * math.cos(theta)
		y: r * math.cos(phi)
		z: r * sin_phi * math.sin(theta)
	}
}

fn (mut loc Location) calc_location(mut sh_ SH, i int, j int) {
	u := sh_.du * f64(i)
	v := sh_.dv * f64(j)

	idx := f64(i) * sh_.dx
	jdx := f64(j) * sh_.dx

	coord := sh_.calc_coord(u, v)
	crd_up := sh_.calc_coord(u + sh_.du10, v)
	crd_right := sh_.calc_coord(u, v + sh_.dv10)

	sh_.max_val = math.max(sh_.max_val, coord.max_abs()) // used to scale coords

	loc = Location{
		coord:   coord
		normal:  normal(coord, crd_up, crd_right)
		color:   color_map(u, 0, pi2, sh_.color_map).to_coord()
		texture: Coord{
			x: idx
			y: jdx
		}
	}
}

fn (mut sh_ SH) calc_location_range(start int, end int) {
	for index in start .. end {
		sh_.mesh[index].calc_location(mut sh_, index / sh_.res, index % sh_.res)
	}
}

fn (mut sh_ SH) calc_mesh() {
	mut ix := 0
	for i in 0 .. sh_.res {
		for j in 0 .. sh_.res {
			sh_.mesh[ix].calc_location(mut sh_, i, j)
			ix++
		}
	}
	sh_.scale_coords()
	sh_.generate_faces()
}

fn (mut sh_ SH) calc_mesh_parallel(n_threads int) {
	mut threads := []thread{cap: n_threads}

	for th in 0 .. n_threads {
		start := th * sh_.size / n_threads
		end := math.min(start + sh_.size / n_threads, sh_.size)

		threads << spawn sh_.calc_location_range(start, end)
	}

	threads.wait()

	sh_.scale_coords()

	sh_.generate_faces()
	// sh_.generate_trigs()
	// sh_.check_faces_trigs()
}

fn (sh_ SH) check_faces_trigs() { // very expensive fn use only when really required
	for face in sh_.faces {
		for v in face {
			if v < 0 || v >= sh_.mesh.len {
				println('Invalid face: ${face}')
			}
			if face.filter(it == v).len != 1 { // time costly!
				println('Invalid face: ${face}')
			}
		}
	}
	for face in sh_.trigs {
		for v in face {
			if v < 0 || v >= sh_.mesh.len {
				println('Invalid face: ${face}')
			}
			if face.filter(it == v).len != 1 { // time costly!
				println('Invalid face: ${face}')
			}
		}
	}
}

fn (sh_ SH) get_mesh() []Location {
	return sh_.mesh
}

fn triangularize(f []int) [][]int {
	mut result := [][]int{cap: 2}
	for t in [[0, 1, 2], [0, 2, 3]] {
		result << [f[t[0]], f[t[1]], f[t[2]]]
	}
	return result
}

fn (mut sh_ SH) generate_trigs() {
	n := sh_.res
	sh_.trigs = [][]int{cap: 508 * n}

	for i in 0 .. n - 2 {
		for j in 0 .. n - 2 {
			for t in triangularize([(i + 1) * n + j, (i + 1) * n + j + 1, i * n + j + 1, i * n + j]) {
				sh_.trigs << t
			}
		}
		for t in triangularize([(i + 1) * n, (i + 1) * n + n - 1, i * n, i * n + n - 1]) {
			sh_.trigs << t
		}
	}
	for i in 0 .. n - 2 {
		for t in triangularize([i, i + 1, n * (n - 1) + i + 1, n * (n - 1) + i]) {
			sh_.trigs << t
		}
	}
}

fn (mut sh_ SH) generate_faces() {
	n := sh_.res
	sh_.faces = [][]int{cap: n * n}
	for i in 0 .. n - 1 {
		for j in 0 .. n - 1 {
			sh_.faces << [i * n + j, (i + 1) * n + j, (i + 1) * n + j + 1, i * n + j + 1]
		}
		sh_.faces << [i * n + (n - 1), (i + 1) * n + (n - 1), (i + 1) * n, i * n]
	}
}

pub fn (sh_ SH) write_obj() ! {
	mut file := create('${sh_.m.map(it.str()).join('')}.obj')!
	file.write_string('#Spherical Harmonics: ${sh_.code}\n')!

	file.write_string('group ${sh_.code}\n')!
	file.write_string('#vertices\n')!

	for loc in sh_.mesh {
		file.write_string('v ${loc.coord.x} ${loc.coord.y} ${loc.coord.z} ${loc.color.x} ${loc.color.y} ${loc.color.z}\n')!
	}
	file.write_string('#normal vector defs \n')!
	for loc in sh_.mesh {
		norm := loc.normal
		file.write_string('vn ${norm.x} ${norm.y} ${norm.z}\n')!
	}
	file.write_string('#face defs \n')!
	for i, face in sh_.faces {
		file.write_string('f ')!
		for v in face {
			file.write_string('${v + 1}//${i + 1} ')!
		}
		file.write_string('\n')!
	}
	file.close()
}
