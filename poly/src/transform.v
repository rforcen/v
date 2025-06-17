// poly transformations
module poly

pub fn kiss_n(mut p Polyhedron, n int, apex_dist f32) &Polyhedron {
	mut flag := Flag{}

	normals := p.normals()
	centers := p.centers()
	f_ := str2int('f___')

	for nface, face in p.faces {
		mut v1 := face[face.len - 1]
		fname := to_int4_2(f_, nface)

		for v2 in face {
			iv2 := to_int4_1(v2)
			flag.add_vertex(iv2, p.vertexes_[v2])

			if face.len == n || n == 0 {
				flag.add_vertex(fname, centers[nface] + normals[nface].mulc(apex_dist))
				flag.add_face_vect([to_int4_1(v1), iv2, fname])
			} else {
				flag.add_face(to_int4_1(nface), to_int4_1(v1), iv2)
			}
			v1 = v2
		}
	}

	return flag.create_poly('k', &p)
}

pub fn ambo(mut p Polyhedron) &Polyhedron {
	mut flag := Flag{}

	dual_ := str2int('dual')
	orig_ := str2int('orig')

	for iface, face in p.faces {
		mut v1 := face[face.len - 2]
		mut v2 := face[face.len - 1]

		mut f_orig := []Int4{cap: face.len}

		for v3 in face {
			m12 := i4_min(v1, v2)
			m23 := i4_min(v2, v3)

			if v1 < v2 {
				flag.add_vertex(m12, midpoint(p.vertexes_[v1], p.vertexes_[v2]))
			}
			f_orig << m12

			flag.add_face(to_int4_2(orig_, iface), m12, m23)
			flag.add_face(to_int4_2(dual_, v2), m23, m12)

			v1, v2 = v2, v3
		}
		flag.add_face_vect(f_orig)
	}

	return flag.create_poly('a', &p)
}

pub fn quinto(mut p Polyhedron) &Polyhedron {
	mut flag := Flag{}
	centers := p.centers()

	for nface, face in p.faces {
		centroid := centers[nface]
		mut v1 := face[face.len - 2]
		mut v2 := face[face.len - 1]

		mut vi4 := []Int4{cap: face.len}

		for v3 in face {
			t12 := i4_min(v1, v2)
			ti12 := i4_min3(nface, v1, v2)
			t23 := i4_min(v2, v3)
			ti23 := i4_min3(nface, v2, v3)
			iv2 := to_int4_1(v2)

			midpt := midpoint(p.vertexes_[v1], p.vertexes_[v2])
			innerpt := midpoint(midpt, centroid)

			flag.add_vertex(t12, midpt)
			flag.add_vertex(ti12, innerpt)

			flag.add_vertex(iv2, p.vertexes_[v2])

			flag.add_face_vect([ti12, t12, iv2, t23, ti23])

			vi4 << ti12

			v1, v2 = v2, v3
		}
		flag.add_face_vect(vi4)
	}

	return flag.create_poly('q', &p)
}

pub fn hollow(mut p Polyhedron) &Polyhedron {
	inset_dist := f32(0.2)
	thickness := f32(0.1)

	mut flag := Flag{}
	flag.set_vertexes(p.vertexes_)

	avgnormals := p.avg_normals()
	centers := p.centers()

	fin_ := str2int('fin_')
	fdwn_ := str2int('fdwn')
	v_ := str2int('v__')

	for i, face in p.faces {
		mut v1 := face[face.len - 1]

		for v2 in face {
			tw := tween(p.vertexes_[v2], centers[i], inset_dist)

			flag.add_vertex(to_int4(fin_, i, v_, v2), tw)
			flag.add_vertex(to_int4(fdwn_, i, v_, v2), tw - (avgnormals[i].mulc(thickness)))

			flag.add_face_vect([to_int4_1(v1), to_int4_1(v2), to_int4(fin_, i, v_, v2),
				to_int4(fin_, i, v_, v1)])
			flag.add_face_vect([to_int4(fin_, i, v_, v1), to_int4(fin_, i, v_, v2),
				to_int4(fdwn_, i, v_, v2), to_int4(fdwn_, i, v_, v1)])

			v1 = v2
		}
	}

	return flag.create_poly('h', &p)
}

pub fn gyro(mut p Polyhedron) &Polyhedron {
	cntr_ := str2int('cntr')

	mut flag := Flag{}
	flag.set_vertexes(p.vertexes_)

	centers := p.centers()

	for i, face in p.faces {
		mut v1 := face[face.len - 2]
		mut v2 := face[face.len - 1]

		flag.add_vertex(to_int4_2(cntr_, i), centers[i].unit())

		for v3 in face {
			flag.add_vertex(to_int4_2(v1, v2), one_third(p.vertexes_[v1], p.vertexes_[v2])) // new v in face

			// 5 new faces
			flag.add_face_vect([to_int4_2(cntr_, i), to_int4_2(v1, v2),
				to_int4_2(v2, v1), to_int4_1(v2), to_int4_2(v2, v3)])

			// shift over one
			v1, v2 = v2, v3
		}
	}

	return flag.create_poly('g', &p)
}

pub fn propellor(mut p Polyhedron) &Polyhedron {
	mut flag := Flag{}
	flag.set_vertexes(p.vertexes_)

	for i, face in p.faces {
		mut v1 := face[face.len - 2]
		mut v2 := face[face.len - 1]

		for v3 in face {
			flag.add_vertex(to_int4_2(v1, v2), one_third(p.vertexes_[v1], p.vertexes_[v2])) // new v in face, 1/3rd along edge

			flag.add_face(to_int4_1(i), to_int4_2(v1, v2), to_int4_2(v2, v3))
			flag.add_face_vect([to_int4_2(v1, v2), to_int4_2(v2, v1),
				to_int4_1(v2), to_int4_2(v2, v3)])

			v1, v2 = v2, v3
		}
	}

	return flag.create_poly('p', &p)
}

pub fn dual(mut p Polyhedron) &Polyhedron {
	mut flag := Flag{}
	face_map := new_face_map(&p)
	centers := p.centers()

	for i, face in p.faces {
		mut v1 := face[face.len - 1]
		flag.add_vertex(to_int4_1(i), centers[i])

		for v2 in face {
			flag.add_face(to_int4_1(v1), face_map.find(to_int4_2(v2, v1)), to_int4_1(i))
			v1 = v2
		}
	}

	return flag.create_poly('d', &p)
}

pub fn chamfer(mut p Polyhedron) &Polyhedron {
	dist := f32(0.1)

	orig_ := str2int('orig')
	hex_ := str2int('hex_')

	mut flag := Flag{}
	normals := p.normals()

	for i, face in p.faces {
		mut v1 := face[face.len - 1]
		mut v1new := to_int4_2(i, v1)

		for v2 in face {
			flag.add_vertex(to_int4_1(v2), p.vertexes_[v2].mulc(1 + dist))
			// Add a new vertex, moved parallel to normal.
			mut v2new := to_int4_2(i, v2)

			flag.add_vertex(v2new, p.vertexes_[v2] + normals[i].mulc(dist * 1.5))

			// Four new flags:
			// One whose face corresponds to the original face:
			flag.add_face(to_int4_2(orig_, i), v1new, v2new)

			// And three for the edges of the new hexagon:			
			facename := i4_min3(hex_, v1, v2)
			flag.add_face(facename, to_int4_1(v2), v2new)
			flag.add_face(facename, v2new, v1new)
			flag.add_face(facename, v1new, to_int4_1(v1))

			v1, v1new = v2, v2new
		}
	}
	return flag.create_poly('c', &p)
}

pub fn inset(mut p Polyhedron) &Polyhedron {
	n := 0 // parameters
	inset_dist := f32(0.3)
	popout_dist := f32(-0.1)

	f_:=str2int('f__')
	ex_:=str2int('ex__')

	mut flag := Flag{}
	flag.set_vertexes(p.vertexes_)
	normals := p.normals()
	centers := p.centers()

	mut found_any := false
	for i, face in p.faces {
		mut v1 := face[face.len - 1]
		for v2 in face {
			if face.len == n || n == 0 {
				found_any = true

				flag.add_vertex(to_int4_3(f_, i, v2), tween(p.vertexes_[v2], centers[i], inset_dist) +
					(normals[i].mulc(popout_dist)))

				flag.add_face_vect([to_int4_1(v1), to_int4_1(v2), to_int4_3(f_, i, v2), to_int4_3(f_, i, v1)])
				// new inset, extruded face
				flag.add_face(to_int4_2(ex_, i), to_int4_3(f_, i, v1), to_int4_3(f_, i, v2))
			} else {
				flag.add_face(to_int4_1(i), to_int4_1(v1), to_int4_1(v2)) // same old flag, if non-n
			}

			v1 = v2
		}
	}
	if !found_any {
		println('no ${n} components where found')
	}

	return flag.create_poly('n', &p)
}
