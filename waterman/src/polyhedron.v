//  polyhedron
module waterman

import math { abs, floor, log10, max, powf, round }
import rand
import os { create }

@[heap]
pub struct Polyhedron {
pub mut:
	name      string
	vertexes  []Vertex
	faces     [][]int

	normals []Vertex
	colors  []Vertex
	centers []Vertex
	areas   []f32
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
	return p.vertexes.len > 0
}

pub fn new_polyhedron(faces [][]int, vertexes []f32) &Polyhedron {
	mut res := &Polyhedron{
		name:     'poly'
		vertexes: []Vertex{len: vertexes.len / 3}
		faces:    faces
	}

	for i in 0 .. vertexes.len / 3 {
		res.vertexes[i] = new_vertex(vertexes[i * 3], vertexes[i * 3 + 1], vertexes[i * 3 + 2])
	}

	res.recalc()
	unsafe {
		*res = res.scale_unit()
	}

	if !res.check() {
		panic('invalid polyhedron')
	}
	return res
}

pub fn (p Polyhedron) check() bool {
	for face in p.faces {
		for v in face {
			if v < 0 || v >= p.vertexes.len {
				return false
			}
		}
	}
	return true
}

// normals
pub fn (mut p Polyhedron) normals() []Vertex {
	p.normals = []Vertex{cap: p.faces.len}
	for face in p.faces {
		v0 := p.vertexes[face[0]]
		v1 := p.vertexes[face[1]]
		v2 := p.vertexes[face[2]]

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
		mut v1 := p.vertexes[face[fl - 2]]
		mut v2 := p.vertexes[face[fl - 1]]

		for v in face {
			vsum += v1.cross(v2)
			v1, v2 = v2, p.vertexes[v]
		}
		p.areas << abs(p.normals[f].dot(vsum)) / 2
	}
}

// colors (must have areas)
pub fn (mut p Polyhedron) colors() {
	p.colors = []Vertex{cap: p.faces.len} // assign p.colors

	mut color_dict := map[int]Vertex{} // color dictionary
	for a in p.areas {
		sf := sigfigs(a, 1)
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
			fcenter += p.vertexes[v]
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
		mut v1 := p.vertexes[face[fl - 2]]
		mut v2 := p.vertexes[face[fl - 1]]
		for v in face {
			v3 := p.vertexes[v]
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
				used_vtx << p.vertexes[ix]
				nvdx++
			}
		}
	}

	for ix in 0 .. p.faces.len { // assign faces
		for i in 0 .. p.faces[ix].len {
			p.faces[ix][i] = old_new[p.faces[ix][i]]
		}
	}
	p.vertexes = used_vtx

	p.clear()
	return p.scale_unit()
}

pub fn (p_ Polyhedron) scale_unit() Polyhedron {
	mut p := p_
	mut max := f32(-1e38)

	for v in p.vertexes { // find max abs component of any vertex
		max = max(v.max_abs(), max)
	}
	if max != 0 { // scale all vertexes
		for mut v in p.vertexes {
			v = v.scale(1 / max)
		}
	}

	return p
}

// create an array of the face index of each vertex
fn (p Polyhedron) index_faces() []int {
	mut face_ix := []int{len: p.vertexes.len, init: -1}
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
	file.write_string('#Produced by waterman\n')!

	file.write_string('group ${p.name}\n')!
	file.write_string('#vertices\n')!

	face_ix := p.index_faces()
	for i, v in p.vertexes {
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

	for v in p.vertexes {
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
