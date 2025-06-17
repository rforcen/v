module poly

import math { abs, max, sqrtf }
import rand

pub struct Vertex {
pub mut:
	x f32
	y f32
	z f32
}

pub fn new_vertex(x f32, y f32, z f32) Vertex {
	return Vertex{
		x: x
		y: y
		z: z
	}
}

pub fn (v Vertex) get(i int) f32 {
	match i {
		0 {
			return v.x
		}
		1 {
			return v.y
		}
		2 {
			return v.z
		}
		else {
			println('Index out of bounds')
			return 0.0
		}
	}
}

pub fn (mut v Vertex) set(i int, value f32) {
	match i {
		0 { v.x = value }
		1 { v.y = value }
		2 { v.z = value }
		else { println('Index out of bounds') }
	}
}

pub fn (v Vertex) + (other Vertex) Vertex {
	return Vertex{
		x: v.x + other.x
		y: v.y + other.y
		z: v.z + other.z
	}
}

pub fn (v Vertex) - (other Vertex) Vertex {
	return Vertex{
		x: v.x - other.x
		y: v.y - other.y
		z: v.z - other.z
	}
}

pub fn (v Vertex) / (other Vertex) Vertex {
	return Vertex{
		x: v.x / other.x
		y: v.y / other.y
		z: v.z / other.z
	}
}

pub fn (v Vertex) mulc(other f32) Vertex {
	return Vertex{
		x: v.x * other
		y: v.y * other
		z: v.z * other
	}
}

pub fn (v Vertex) scale(s f32) Vertex {
	return Vertex{
		x: v.x * s
		y: v.y * s
		z: v.z * s
	}
}

pub fn normal(v0 Vertex, v1 Vertex, v2 Vertex) Vertex {
	return (v1 - v0).cross(v2 - v1).unit()
}

pub fn (v Vertex) max_abs() f32 {
	return max(max(abs(v.x), abs(v.y)), abs(v.z))
}

pub fn (v Vertex) norm() f32 {
	return sqrtf(v.norm_squared())
}

pub fn (v Vertex) unit() Vertex {
	nrm := v.norm()
	return if nrm != 0 { v.scale(1 / nrm) } else { v }
}

pub fn (v Vertex) norm_squared() f32 {
	return v.x * v.x + v.y * v.y + v.z * v.z
}

pub fn (v Vertex) distance_squared(other Vertex) f32 {
	return (v.x - other.x) * (v.x - other.x) + (v.y - other.y) * (v.y - other.y) +
		(v.z - other.z) * (v.z - other.z)
}

pub fn (v Vertex) distance(other Vertex) f32 {
	return sqrtf(v.distance_squared(other))
}

pub fn (v Vertex) dot(other Vertex) f32 {
	return v.x * other.x + v.y * other.y + v.z * other.z
}

pub fn (mut v Vertex) normalize() {
	v = v.unit()
}

pub fn (v Vertex) cross(other Vertex) Vertex {
	return Vertex{
		x: v.y * other.z - v.z * other.y
		y: v.z * other.x - v.x * other.z
		z: v.x * other.y - v.y * other.x
	}
}

pub fn (mut v Vertex) set_random() {
	v.x = rand.f32()
	v.y = rand.f32()
	v.z = rand.f32()
}

pub fn (mut v Vertex) set_zero() {
	v.x = 0.0
	v.y = 0.0
	v.z = 0.0
}

pub fn (v Vertex) str() string {
	return 'Vertex(x: ${v.x}, y: ${v.y}, z: ${v.z})'
}
