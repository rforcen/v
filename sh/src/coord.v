// 3d coord and basic op.
// 
module sh

import math

struct Coord {
mut:
	x f64
	y f64
	z f64
}

struct Coord_f32 {
mut:
	x f32
	y f32
	z f32
}

struct Color {
mut:
	r f64
	g f64
	b f64
}

struct Color_f32 {
mut:
	r f32
	g f32
	b f32
}

// Coord methods
fn (c Coord) max() f64 {
	return math.max(math.max(c.x, c.y), c.z)
}
fn (c Coord) max_abs() f64 {
	return math.max(math.max(math.abs(c.x), math.abs(c.y)), math.abs(c.z))
}

fn (c Color) tof32() Color_f32 {
	return Color_f32{
		r: f32(c.r)
		g: f32(c.g)
		b: f32(c.b)
	}
}

fn (c Coord) tof32() Coord_f32 {
	return Coord_f32{
		x: f32(c.x)
		y: f32(c.y)
		z: f32(c.z)
	}
}

fn (c Color) to_coord() Coord {
	return Coord{
		x: c.r
		y: c.g
		z: c.b
	}
}

fn (c Coord) - (c2 Coord) Coord {
	return Coord{
		x: c.x - c2.x
		y: c.y - c2.y
		z: c.z - c2.z
	}
}

fn (c Coord) divc(l f64) Coord {
	return if l == 0 {
		c
	} else {
		Coord{
			x: c.x / l
			y: c.y / l
			z: c.z / l
		}
	}
}

fn (mut c Coord) mut_divc(l f64) {
	if l == 0 {
		return
	}
	c.x /= l
	c.y /= l
	c.z /= l
}

fn cross(c1 Coord, c2 Coord) Coord {
	return Coord{
		x: c1.y * c2.z - c1.z * c2.y
		y: c1.z * c2.x - c1.x * c2.z
		z: c1.x * c2.y - c1.y * c2.x
	}
}

fn (c Coord) length() f64 {
	return math.sqrt(c.x * c.x + c.y * c.y + c.z * c.z)
}

fn (c Coord) normalize() Coord {
	return c.divc(c.length())
}

fn normal(c0 Coord, c1 Coord, c2 Coord) Coord {
	return cross(c1 - c2, c1 - c0).normalize()
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
