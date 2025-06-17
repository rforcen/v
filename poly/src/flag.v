// transform a set of linked list of faces into a polygon
module poly

@[heap]
struct Flag {
pub mut:
	vertexes []Vertex
	faces    [][]int

	fcs       [][]Int4
	faceindex int
	valid     bool = true

	facemap map[u64]VertexIndex  // [Int4.hash()] VertexIndex
	m_map   map[u64]map[u64]Int4 // [Int4.hash()] [Int4.hash()] Int4
}

fn (mut f Flag) set_vertexes(vs []Vertex) {
	for i, v in vs {
		f.add_vertex(to_int4_1(i), v)
	}
}

fn (mut f Flag) add_vertex(ix Int4, vtx Vertex) {
	f.facemap[ix.hash()] = VertexIndex{f.faceindex, vtx}
	f.faceindex++
}

fn (mut f Flag) add_face(i0 Int4, i1 Int4, i2 Int4) {
	f.m_map[i0.hash()][i1.hash()] = i2
}

fn (mut f Flag) add_face_vect(v []Int4) {
	f.fcs << v
}

fn (mut f Flag) reindex_vertexes() { // using facemap, vertexes=v
	f.vertexes = []Vertex{len: f.facemap.len}

	mut i := 0
	for _, mut v in f.facemap { // enumerate facemap & copy vertexes
		v.index = i
		f.vertexes[i] = v.vertex
		i++
	}
}

fn (mut f Flag) process_m_map() bool { // m_map -> faces
	max_iters := 100
	f.valid = true

	if f.m_map.len > 0 { // ! empty
		f.faces = [][]int{cap: f.m_map.len}

		for i, face in f.m_map { // MapIndex
			v0 := face.values()[0] // starting point
			mut v := v0

			// traverse m0
			mut face_ := []int{cap: face.len}

			for cnt := 0; cnt < max_iters; cnt++ {
				face_ << f.facemap[v.hash()].index
				v = f.m_map[i][v.hash()]

				if v == v0 { // found, closed loop
					break
				}
			}
			if v != v0 { // couldn't close loop -> invalid
				f.valid = false
				f.faces = [][]int{}
				println('dead loop')
				return f.valid
			}
			f.faces << face_
		}
	}
	return f.valid
}

fn (mut f Flag) process_fcs() { // fcs -> faces
	// faces << fcs[index_vertex]
	for fc in f.fcs {
		mut face := []int{cap: fc.len}
		for vix in fc {
			face << f.facemap[vix.hash()].index
		}
		f.faces << face
	}
}

fn cmp_dualfaces(a &DualFaces, b &DualFaces) int {
	if a.face_sorted.len != b.face_sorted.len {
		return a.face_sorted.len - b.face_sorted.len
	}

	// This is fast: just a linear scan of already sorted data
	for i in 0 .. a.face_sorted.len {
		if a.face_sorted[i] != b.face_sorted[i] {
			return a.face_sorted[i] - b.face_sorted[i]
		}
	}
	return 0
}

// remove faces dupes comparing with sorted faces:
// creates  a presorted array of faces to optimize comparision
fn (mut f Flag) unique_faces() {
	// use DualFaces to keep original faces and sorted faces
	mut dual_faces := []DualFaces{len: f.faces.len}
	for i, face in f.faces {
		dual_faces[i] = DualFaces{
			face_org:    face
			face_sorted: sort_clone(face)
		}
	}

	dual_faces.sort_with_compare(cmp_dualfaces)

	// copy orginal faces from dual_faces in sorted order
	f.faces = [][]int{len: dual_faces.len}
	for i, df in dual_faces {
		f.faces[i] = df.face_org
	}
	f.faces.uniquev()
}

fn (mut f Flag) check() { // consistency polyhedron check
	for face in f.faces {
		if face.len < 3 {
			f.valid = false
			return
		}
		for iv in face {
			if iv >= f.vertexes.len {
				f.valid = false
				return
			}
		}
	}
}

fn (mut f Flag) to_poly() bool {
	f.reindex_vertexes() // and sort for lower_bound search
	if f.process_m_map() {
		f.process_fcs()
		f.unique_faces() // remove dupes preserving face order
		f.check()
	}
	return f.valid
}

fn (mut f Flag) create_poly(tr string, p &Polyhedron) &Polyhedron {
	if !f.to_poly() {
		return p
	} else {
		mut pp := Polyhedron{
			name:      tr + p.name
			vertexes_: f.vertexes
			faces:     f.faces
		}.normalize()
		return &pp
	}
}
