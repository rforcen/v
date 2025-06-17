//  polyhedron
module poly

import math { abs, cosf, floor, log10, max, powf, round, sinf }
import rand
import os { create }

@[heap]
pub struct Polyhedron {
mut:
	vertexes [][]f32
pub mut:
	name      string
	vertexes_ []Vertex
	faces     [][]int

	normals []Vertex
	colors  []Vertex
	centers []Vertex
	areas   []f32
}

// plato solids

pub const plato_solids = [
	tetrahedron,
	cube,
	icosahedron,
	octahedron,
	dodecahedron,
]

const plato_solids_names = {
	'T': 'tetrahedron'
	'C': 'cube'
	'I': 'icosahedron'
	'O': 'octahedron'
	'D': 'dodecahedron'
}

const poly_initials ='TCIOD'

pub fn (p Polyhedron) poly_name() string {
	if p.name in plato_solids_names {
		return plato_solids_names[p.name]
	}

	return p.name
}

const cs_ = f32(0.707)

pub const tetrahedron = &Polyhedron{
	name:     'T'
	vertexes: [[cs_, cs_, cs_], [cs_, -cs_, -cs_], [-cs_, cs_, -cs_],
		[-cs_, -cs_, cs_]]
	faces:    [[0, 1, 2], [0, 2, 3], [0, 3, 1], [1, 3, 2]]
}
pub const cube = &Polyhedron{
	name: 'C'
	// vertexes: [[cs_, cs_, cs_], [cs_, cs_, -cs_], [cs_, -cs_, -cs_],		[cs_, -cs_, cs_], [-cs_, cs_, cs_], [-cs_, cs_, -cs_],		[-cs_, -cs_, -cs_], [-cs_, -cs_, cs_]]
	// faces:    [[0, 1, 2, 3], [0, 3, 7, 4], [0, 4, 5, 1], [6, 2, 1, 5],		[6, 5, 4, 7], [6, 7, 3, 2]]
	faces:    [[3, 0, 1, 2], [3, 4, 5, 0], [0, 5, 6, 1], [1, 6, 7, 2],
		[2, 7, 4, 3], [5, 4, 7, 6]]
	vertexes: [[cs_, cs_, cs_], [-cs_, cs_, cs_], [-cs_, -cs_, cs_],
		[cs_, -cs_, cs_], [cs_, -cs_, -cs_], [cs_, cs_, -cs_],
		[-cs_, cs_, -cs_], [-cs_, -cs_, -cs_]]
}
pub const icosahedron = &Polyhedron{
	name:     'I'
	vertexes: [[f32(0), f32(0), f32(1.176)], [f32(1.051), f32(0), f32(0.526)],
		[f32(0.324), f32(1.0), f32(0.525)], [f32(-0.851), f32(0.618), f32(0.526)],
		[f32(-0.851), f32(-0.618), f32(0.526)], [f32(0.325), f32(-1.0), f32(0.526)],
		[f32(0.851), f32(0.618), f32(-0.526)], [f32(0.851), f32(-0.618), f32(-0.526)],
		[f32(-0.325), f32(1.0), f32(-0.526)], [f32(-1.051), f32(0), f32(-0.526)],
		[f32(-0.325), f32(-1.0), f32(-0.526)], [f32(0), f32(0), f32(-1.176)]]

	faces: [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 1],
		[1, 5, 7], [1, 7, 6], [1, 6, 2], [2, 6, 8], [2, 8, 3],
		[3, 8, 9], [3, 9, 4], [4, 9, 10], [4, 10, 5], [5, 10, 7],
		[6, 7, 11], [6, 11, 8], [7, 10, 11], [8, 11, 9], [9, 11, 10]]
}
pub const octahedron = &Polyhedron{
	name:     'O'
	vertexes: [[f32(0), f32(0), f32(1.414)], [f32(1.414), f32(0), f32(0)],
		[f32(0), f32(1.414), f32(0)], [f32(-1.414), f32(0), f32(0)],
		[f32(0), f32(-1.414), f32(0)], [f32(0), f32(0), f32(-1.414)]]
	faces:    [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 1], [1, 4, 5],
		[1, 5, 2], [2, 5, 3], [3, 5, 4]]
}
pub const dodecahedron = &Polyhedron{
	name:     'D'
	vertexes: [[f32(0), f32(0), f32(1.07047)], [f32(0.713644), f32(0), f32(0.797878)],
		[f32(-0.356822), f32(0.618), f32(0.797878)], [f32(-0.356822), f32(-0.618), f32(0.797878)],
		[f32(0.797878), f32(0.618034), f32(0.356822)], [f32(0.797878), f32(-0.618), f32(0.356822)],
		[f32(-0.934172), f32(0.381966), f32(0.356822)], [f32(0.136294), f32(1.0), f32(0.356822)],
		[f32(0.136294), f32(-1.0), f32(0.356822)], [f32(-0.934172), f32(-0.381966), f32(0.356822)],
		[f32(0.934172), f32(0.381966), f32(-0.356822)],
		[f32(0.934172), f32(-0.381966), f32(-0.356822)], [f32(-0.797878), f32(0.618), f32(-0.356822)],
		[f32(-0.136294), f32(1.0), f32(-0.356822)], [f32(-0.136294), f32(-1.0), f32(-0.356822)],
		[f32(-0.797878), f32(-0.618034), f32(-0.356822)], [f32(0.356822), f32(0.618), f32(-0.797878)],
		[f32(0.356822), f32(-0.618), f32(-0.797878)], [f32(-0.713644), f32(0), f32(-0.797878)],
		[f32(0), f32(0), f32(-1.07047)]]

	faces: [[0, 1, 4, 7, 2], [0, 2, 6, 9, 3], [0, 3, 8, 5, 1],
		[1, 5, 11, 10, 4], [2, 7, 13, 12, 6], [3, 9, 15, 14, 8],
		[4, 10, 16, 13, 7], [5, 8, 14, 17, 11], [6, 12, 18, 15, 9],
		[10, 11, 17, 19, 16], [12, 13, 16, 19, 18], [14, 15, 18, 19, 17]]
}

// populate vertexes_ with vertexes
pub fn (mut p Polyhedron) to_vertexes_() &Polyhedron {
	if !p.has_vertexes() {
		for v in p.vertexes {
			p.vertexes_ << new_vertex(v[0], v[1], v[2])
		}
		p.vertexes = [][]f32{}
	}
	return p
}

// create trigs from faces
pub fn tesselate(face []int) [][]int {
	mut pivot := face[0]
	mut res := [][]int{}

	for i := 1; i < face.len - 1; i++ {
		res << [pivot, face[i], face[i + 1]]
	}
	return res
}

pub fn (p Polyhedron) has_vertexes() bool {
	return p.vertexes_.len > 0
}

pub fn sphere(rad f32, n_segments int) &Polyhedron {
	mut polyhedron := &Polyhedron{
		name: 'sphere'
	}

	// --- 1. Generate Vertices ---

	// Add the top pole vertex
	polyhedron.vertexes_ << new_vertex(0.0, rad, 0.0) // Top pole

	// Generate vertices for the stacks (latitude rings)
	for i in 1 .. n_segments {
		phi := math.pi * f32(i) / f32(n_segments) // Angle from y-axis (latitude)
		y := rad * cosf(phi) // Y-coordinate based on latitude
		current_radius := rad * sinf(phi) // Radius of the current latitude circle

		for j in 0 .. n_segments {
			theta := 2 * math.pi * f32(j) / f32(n_segments) // Angle around y-axis (longitude)

			x := current_radius * cosf(theta)
			z := current_radius * sinf(theta)

			polyhedron.vertexes_ << new_vertex(x, y, z)
		}
	}

	// Add the bottom pole vertex
	polyhedron.vertexes_ << new_vertex(0.0, -rad, 0.0) // Bottom pole

	// --- 2. Generate Faces ---

	// Faces for the top cap (connecting to the top pole)
	top_pole_idx := 0 // Index of the top pole vertex
	for j in 0 .. n_segments {
		idx1 := j + 1 // First vertex on the first latitude ring
		idx2 := (j + 1) % n_segments + 1 // Next vertex on the first latitude ring (wraps around)

		polyhedron.faces << [top_pole_idx, top_pole_idx, idx2, idx1]
	}

	// Faces for the middle sections (quads forming strips)
	for i in 0 .. n_segments - 2 { // Loop through stacks (excluding top and bottom caps)
		start_idx_current_ring := 1 + i * n_segments // Index of the first vertex of the current ring
		start_idx_next_ring := 1 + (i + 1) * n_segments // Index of the first vertex of the next ring

		for j in 0 .. n_segments { // Loop through sectors
			// Get indices for the current quad
			v1 := start_idx_current_ring + j
			v2 := start_idx_current_ring + (j + 1) % n_segments // Wraps around
			v3 := start_idx_next_ring + (j + 1) % n_segments // Wraps around
			v4 := start_idx_next_ring + j

			polyhedron.faces << [v1, v2, v3, v4]
		}
	}

	// Faces for the bottom cap (connecting to the bottom pole)
	bottom_pole_idx := polyhedron.vertexes_.len - 1 // Index of the bottom pole vertex
	start_idx_last_ring := 1 + (n_segments - 2) * n_segments // Index of the first vertex of the last latitude ring

	for j in 0 .. n_segments {
		idx1 := start_idx_last_ring + j
		idx2 := start_idx_last_ring + (j + 1) % n_segments // Wraps around

		polyhedron.faces << [bottom_pole_idx, bottom_pole_idx, idx1, idx2]
	}

	return polyhedron
}

pub fn new_polyhedron(p &Polyhedron) &Polyhedron {
	mut res := &Polyhedron{
		name:     p.name
		vertexes: p.vertexes
		faces:    p.faces
	}

	res.to_vertexes_()
	res.normals()
	res.areas()
	res.colors()
	res.centers()
	unsafe {
		*res = res.scale_unit()
	}
	return res
}

pub fn new_poly_by_name(initial char) &Polyhedron {
	match rune(initial) {
		`T` { return new_polyhedron(tetrahedron) }
		`C` { return new_polyhedron(cube) }
		`I` { return new_polyhedron(icosahedron) }
		`O` { return new_polyhedron(octahedron) }
		`D` { return new_polyhedron(dodecahedron) }
		else { return new_polyhedron(tetrahedron) }
	}
}

// normals
pub fn (mut p Polyhedron) normals() []Vertex {
	for face in p.faces {
		v0 := p.vertexes_[face[0]]
		v1 := p.vertexes_[face[1]]
		v2 := p.vertexes_[face[2]]

		p.normals << normal(v0, v1, v2).unit()
	}
	return p.normals
}

// areas (requires normals)
pub fn (mut p Polyhedron) areas() {
	p.areas = []f32{cap: p.faces.len}
	for f, face in p.faces {
		mut vsum := Vertex{0, 0, 0}
		fl := face.len
		mut v1 := p.vertexes_[face[fl - 2]]
		mut v2 := p.vertexes_[face[fl - 1]]

		for v in face {
			vsum += v1.cross(v2)
			v1, v2 = v2, p.vertexes_[v]
		}
		p.areas << abs(p.normals[f].dot(vsum)) / 2
	}
}

// colors (must have areas)
pub fn (mut p Polyhedron) colors() {
	p.colors = []Vertex{cap: p.faces.len} // assign p.colors

	mut color_dict := map[int]Vertex{} // color dictionary
	for a in p.areas {
		sf := sigfigs(a, 2)
		if sf !in color_dict { // new color to sf
			color_dict[sf] = new_vertex(rand.f32(), rand.f32(), rand.f32())
		}
		p.colors << color_dict[sf]
	}
}

// centers
pub fn (mut p Polyhedron) centers() []Vertex {
	p.centers = []Vertex{cap: p.faces.len}

	for face in p.faces {
		mut fcenter := Vertex{}
		for v in face {
			fcenter += p.vertexes_[v]
		}
		p.centers << fcenter.scale(1 / f32(face.len))
	}
	return p.centers
}

// avg normals
pub fn (mut p Polyhedron) avg_normals() []Vertex {
	mut normals := []Vertex{cap: p.faces.len}

	for face in p.faces {
		fl := face.len
		mut normal_v := Vertex{}
		mut v1 := p.vertexes_[face[fl - 2]]
		mut v2 := p.vertexes_[face[fl - 1]]
		for v in face {
			v3 := p.vertexes_[v]
			normal_v += normal(v1, v2, v3)
			v1, v2 = v2, v3
		}
		normals << normal_v.unit()
	}
	return normals
}

pub fn (mut p Polyhedron) recalc() Polyhedron {
	p.normals()
	p.areas()
	p.colors()
	p.centers()

	return p
}

pub fn (mut p Polyhedron) clear() {
	p.normals = []Vertex{}
	p.colors = []Vertex{}
	p.centers = []Vertex{}
	p.areas = []f32{}
}

fn sigfigs(f f32, nsigs int) int { // returns w. nsigs digits ignoring magnitude
	if f == 0 {
		return 0
	}
	mantissa := f / powf(10, f32(floor(log10(f))))
	return int(round(mantissa * powf(10, (nsigs - 1))))
}

pub fn (p Polyhedron) count_points() int { // count # points used in all faces
	mut np := 0
	for face in p.faces {
		np += face.len
	}
	return np
}

fn (p Polyhedron) max_face_index() int {
	mut max := -1
	for face in p.faces {
		for ix in face {
			if ix > max {
				max = ix
			}
		}
	}
	return max
}

pub fn (p_ Polyhedron) normalize() Polyhedron {
	mut p := p_

	mut old_new := []int{len: p.max_face_index() + 1, init: -1}
	mut nvdx := 0
	mut used_vtx := []Vertex{}

	for face in p.faces {
		for ix in face {
			if old_new[ix] == -1 {
				old_new[ix] = nvdx
				used_vtx << p.vertexes_[ix]
				nvdx++
			}
		}
	}

	for ix in 0 .. p.faces.len { // assign faces
		for i in 0 .. p.faces[ix].len {
			p.faces[ix][i] = old_new[p.faces[ix][i]]
		}
	}
	p.vertexes_ = used_vtx

	p.clear()
	return p.scale_unit()
}

pub fn (p_ Polyhedron) scale_unit() Polyhedron {
	mut p := p_
	mut max := f32(-1e38)

	for v in p.vertexes_ { // find max abs component of any vertex
		max = max(v.max_abs(), max)
	}
	if max != 0 { // scale all vertexes
		for mut v in p.vertexes_ {
			v = v.scale(1 / max)
		}
	}

	return p
}

// create an array of the face index of each vertex
fn (p Polyhedron) index_faces() []int {
	mut face_ix := []int{len: p.vertexes_.len, init: -1}
	for iface, face in p.faces {
		for v in face {
			face_ix[v] = iface
		}
	}
	return face_ix
}

// writers
pub fn (p Polyhedron) write_obj() ! {
	mut file := create(p.name + '.obj')!
	file.write_string('#Produced by polyHédronisme http://levskaya.github.com/polyhedronisme\n')!

	file.write_string('group ${p.name}\n')!
	file.write_string('#vertices\n')!

	face_ix := p.index_faces()
	for i, v in p.vertexes_ {
		color := p.colors[face_ix[i]]
		file.write_string('v ${v.x} ${v.y} ${v.z} ${color.x} ${color.y} ${color.z}\n')!
	}
	file.write_string('#normal vector defs \n')!
	for i, _ in p.faces {
		norm := p.normals[i]
		file.write_string('vn ${norm.x} ${norm.y} ${norm.z}\n')!
	}
	file.write_string('#face defs \n')!
	for i, _ in p.faces {
		file.write_string('f ')!
		for v in p.faces[i] {
			file.write_string('${v + 1}//${i + 1} ')!
		}
		file.write_string('\n')!
	}
	file.close()
}

pub fn (p Polyhedron) write_vrml() ! {
	scale_factor := f32(0.03)
	mut file := create(p.name + '.vrml')!
	file.write_string('#VRML V2.0 utf8\n')!
	file.write_string('#Generated by Polyhedronisme\n')!
	file.write_string('NavigationInfo {\n')!
	file.write_string('\ttype [ "EXAMINE", "ANY" ]\n')!
	file.write_string('}')!
	file.write_string('Transform {\n')!
	file.write_string('\tscale 1 1 1\n')!
	file.write_string('\ttranslation 0 0 0\n')!
	file.write_string('\tchildren\n')!
	file.write_string('  [\n')!
	file.write_string('    Shape\n')!
	file.write_string('    {\n')!
	file.write_string('      geometry IndexedFaceSet\n')!
	file.write_string('      {\n')!
	file.write_string('        creaseAngle .5\n')!
	file.write_string('        solid FALSE\n')!
	file.write_string('        coord Coordinate\n')!
	file.write_string('        {\n')!
	file.write_string('          point\n')!
	file.write_string('          [\n')!

	for v in p.vertexes_ {
		file.write_string('${v.x * scale_factor} ${v.y * scale_factor} ${v.z * scale_factor},\n')!
	}
	file.write_string(']
}
color Color
{
  color
  [')!

	// per-face Color
	for c in p.colors {
		file.write_string('${c.x} ${c.y} ${c.z},\n')!
	}

	file.write_string(']
}
colorPerVertex FALSE
coordIndex
[')!
	for face in p.faces {
		for v in face {
			file.write_string('${v},')!
		}
		file.write_string('-1,\n')!
	}

	file.write_string(']
}
      appearance Appearance
      {
        material Material
        {
	       ambientIntensity 0.2
	       diffuseColor 0.9 0.9 0.9
	       specularColor .1 .1 .1
	       shininess .5
        }
      }
    }
  ]	
}
')!
	file.close()
}
