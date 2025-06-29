module voronoi

import rand { int_in_range }
import runtime { nr_cpus }

struct Point {
mut:
	x     int
	y     int
	color u32
}

struct Voronoi {
mut:
	w      int
	h      int
	points []Point
	image  []u32

	single_thread bool = true
}

pub fn new_voronoi(w int, h int, n int, single_thread bool) Voronoi {
	mut v := Voronoi{
		w:             w
		h:             h
		points:        create_rand_points(w, h, n)
		image:         []u32{len: w * h}
		single_thread: single_thread
	}
	if single_thread {
		v.gen_image_st()
	} else {
		v.gen_image_mt()
	}	
	return v
}

fn (voronoi_ Voronoi) dist_sq(i int, j int, p Point) int {
	xd := i - p.x
	yd := j - p.y
	return xd * xd + yd * yd
}

fn (voronoi_ Voronoi) gen_pixel(index int) u32 {
	i := index % voronoi_.w
	j := index / voronoi_.w

	mut min_dist := 2_147_483_647
	mut color := u32(0)

	for p in voronoi_.points {
		dist := voronoi_.dist_sq(i, j, p)
		if dist < 3 {
			color = u32(0)
			break
		}
		if dist < min_dist {
			min_dist = dist
			color = p.color
		}
	}
	return if color == u32(0) { u32(0xff000000) } else { color }
}

fn (mut voronoi_ Voronoi) gen_image_st() {
	for i in 0 .. voronoi_.w * voronoi_.h {
		voronoi_.image[i] = voronoi_.gen_pixel(i)
	}
}

fn (mut voronoi_ Voronoi) gen_image_mt() {
	mut threads := []thread{cap: nr_cpus()}
	size := voronoi_.w * voronoi_.h
	for th in 0 .. nr_cpus() {
		threads << spawn voronoi_.gen_pixel_range(th * size / nr_cpus(), (th + 1) * size / nr_cpus())
	}
	threads.wait()
}

fn (mut voronoi_ Voronoi) gen_pixel_range(start int, end int) {
	for i in start .. end {
		voronoi_.image[i] = voronoi_.gen_pixel(i)
	}
}

pub fn create_rand_points(w int, h int, n int) []Point {
	mut points := []Point{}
	for _ in 0 .. n {
		points << Point{
			x:     int_in_range(0, w) or {0}
			y:     int_in_range(0, h) or {0}
			color: u32(0xff000000 | int_in_range(0, 0x00ffffff) or {0})
		}
	}
	return points
}
