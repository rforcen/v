// cpp wrapper
module waterman

// cpp convex hull wrapper
#flag -L./cpp -lwaterman -lstdc++ -lm 
#flag -I. -I./cpp
#include "convexhull.h"

// cpp funcs.
pub fn C.watermanPoly(radius f64, n_ix &int, nvertexes &int, faces &&int, vertexes &&f64)
pub fn C.freeCH(faces &int, vertexes &f64)

// waterman poly
pub fn waterman(radius f64) ([][]int, []f32) { // faces, vertexes
	n_ix := 0 // number of index to vertexes -> faces
	nvertexes := 0
	pfaces := &int(unsafe { nil })
	pvertexes := &f64(unsafe { nil })

	// println('rad:${radius}')
	unsafe { C.watermanPoly(radius, &n_ix, &nvertexes, &pfaces, &pvertexes) }
	// println('n_ix: ${n_ix}, nvertexes: ${nvertexes}')

	// extract faces and vertexes
	mut faces := [][]int{}
	mut vertexes := []f32{len: nvertexes }

	for i in 0 .. nvertexes { // convert vertexes
		vertexes[i] = f32(unsafe { pvertexes[i] })
	}

	for i := 0; i < n_ix; i += unsafe { pfaces[i] + 1 } { // convert linear len|data|len1|data... to [][]int
		len := unsafe { pfaces[i] } // current len
		mut face := []int{len: len} // make face
		unsafe { vmemmove(&face[0], &pfaces[i + 1], len * int(sizeof(int))) } // copy data

		faces << face
	}

	C.freeCH(pfaces, pvertexes) // release C stuff

	// check faces
	for face in faces {
		for v in face {
			if v < 0 || v >= nvertexes {
				println('error: v: ${v}, nvertexes: ${nvertexes}')
			}
		}
	}

	return faces, vertexes
}
