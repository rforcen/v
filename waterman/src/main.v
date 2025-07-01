module main

import waterman { ui_glfw, waterman, new_polyhedron }

fn test01() {
	for rad := 100.0; rad <= 1700.0; rad += 10.0 {
		faces, vertexes := waterman(rad)
		poly := new_polyhedron(faces, vertexes)
		poly.write_vrml() or {
			println('error: ${err}')
		}
	}
}

fn main() {
	ui_glfw()
}
