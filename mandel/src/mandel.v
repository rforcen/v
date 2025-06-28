// mandelbrot fractal multithreaded

module mandel

import math.complex as cmplx
import math

const fire_pallete_256 = [u32(0), 0, 4, 12, 16, 24, 32, 36, 44, 48, 56, 64, 68, 76, 80, 88, 96,
	100, 108, 116, 120, 128, 132, 140, 148, 152, 160, 164, 172, 180, 184, 192, 200, 1224, 3272,
	4300, 6348, 7376, 9424, 10448, 12500, 14548, 15576, 17624, 18648, 20700, 21724, 23776, 25824,
	26848, 28900, 29924, 31976, 33000, 35048, 36076, 38124, 40176, 41200, 43248, 44276, 46324,
	47352, 49400, 51452, 313596, 837884, 1363196, 1887484, 2412796, 2937084, 3461372, 3986684,
	4510972, 5036284, 5560572, 6084860, 6610172, 7134460, 7659772, 8184060, 8708348, 9233660, 9757948,
	10283260, 10807548, 11331836, 11857148, 12381436, 12906748, 13431036, 13955324, 14480636,
	15004924, 15530236, 16054524, 16579836, 16317692, 16055548, 15793404, 15269116, 15006972,
	14744828, 14220540, 13958396, 13696252, 13171964, 12909820, 12647676, 12123388, 11861244,
	11599100, 11074812, 10812668, 10550524, 10288380, 9764092, 9501948, 9239804, 8715516, 8453372,
	8191228, 7666940, 7404796, 7142652, 6618364, 6356220, 6094076, 5569788, 5307644, 5045500, 4783356,
	4259068, 3996924, 3734780, 3210492, 2948348, 2686204, 2161916, 1899772, 1637628, 1113340, 851196,
	589052, 64764, 63740, 62716, 61692, 59644, 58620, 57596, 55548, 54524, 53500, 51452, 50428,
	49404, 47356, 46332, 45308, 43260, 42236, 41212, 40188, 38140, 37116, 36092, 34044, 33020,
	31996, 29948, 28924, 27900, 25852, 24828, 23804, 21756, 20732, 19708, 18684, 16636, 15612,
	14588, 12540, 11516, 10492, 8444, 7420, 6396, 4348, 3324, 2300, 252, 248, 244, 240, 236, 232,
	228, 224, 220, 216, 212, 208, 204, 200, 196, 192, 188, 184, 180, 176, 172, 168, 164, 160, 156,
	152, 148, 144, 140, 136, 132, 128, 124, 120, 116, 112, 108, 104, 100, 96, 92, 88, 84, 80, 76,
	72, 68, 64, 60, 56, 52, 48, 44, 40, 36, 32, 28, 24, 20, 16, 12, 8, 0, 0]

// Mandel
pub struct Mandel {
	w     int
	h     int
	iters int
	size  int

	center cmplx.Complex
	range  cmplx.Complex
	cr     cmplx.Complex
	rir    f64
	scale  f64

	fire_pallete []u32
pub mut:
	image []u32
}

fn generate_gradient(n int, start_color u32, end_color u32) []u32 {
	mut palette := []u32{len: n}

	start_r := (start_color >> 16) & 0xFF
	start_g := (start_color >> 8) & 0xFF
	start_b := start_color & 0xFF

	end_r := (end_color >> 16) & 0xFF
	end_g := (end_color >> 8) & 0xFF
	end_b := end_color & 0xFF

	for i := 0; i < n; i++ {
		ratio := f32(i) / f32(n - 1)

		current_r := u8(f32(start_r) + (f32(end_r) - f32(start_r)) * ratio)
		current_g := u8(f32(start_g) + (f32(end_g) - f32(start_g)) * ratio)
		current_b := u8(f32(start_b) + (f32(end_b) - f32(start_b)) * ratio)

		color := u32(current_b) << 16 | u32(current_g) << 8 | u32(current_r)
		palette[i] = color
	}

	return palette
}

fn generate_fractal_palette_sin(n int) []u32 {
	if n <= 0 {
		return []u32{}
	}

	mut palette := []u32{len: n}

	for i := 0; i < n; i++ {
		ratio := f64(i) / f64(n) // Normalize to 0.0 - 1.0 (exclusive of 1.0)

		red := u8(127.5 * (1.0 + math.sin(0.3 * math.pi * ratio)))
		green := u8(127.5 * (1.0 + math.sin(0.3 * math.pi * ratio + 2.0 * math.pi / 3.0)))
		blue := u8(127.5 * (1.0 + math.sin(0.3 * math.pi * ratio + 4.0 * math.pi / 3.0)))

		color := u32(red) << 16 | u32(green) << 8 | u32(blue)
		palette[i] = color
	}

	return palette
}

fn generate_fractal_palette_linear(n int, key_colors []u32) []u32 {
	if n <= 0 || key_colors.len == 0 {
		return []u32{}
	}

	mut palette := []u32{len: n}
	num_keys := key_colors.len

	if num_keys == 1 {
		// If only one key color, the whole palette is that color.
		for i := 0; i < n; i++ {
			palette[i] = key_colors[0]
		}
		return palette
	}

	segment_length := n / (num_keys - 1)
	remainder := n % (num_keys - 1)
	mut current_index := 0

	for i := 0; i < num_keys - 1; i++ {
		start_color := key_colors[i]
		end_color := key_colors[i + 1]
		segment_len := segment_length + (if i < remainder { 1 } else { 0 })

		start_r := (start_color >> 16) & 0xFF
		start_g := (start_color >> 8) & 0xFF
		start_b := start_color & 0xFF

		end_r := (end_color >> 16) & 0xFF
		end_g := (end_color >> 8) & 0xFF
		end_b := end_color & 0xFF

		for j := 0; j < segment_len; j++ {
			ratio := f32(j) / f32(segment_len - 1)

			current_r := u8(f32(start_r) + (f32(end_r) - f32(start_r)) * ratio)
			current_g := u8(f32(start_g) + (f32(end_g) - f32(start_g)) * ratio)
			current_b := u8(f32(start_b) + (f32(end_b) - f32(start_b)) * ratio)

			palette[current_index] = u32(current_b) << 16 | u32(current_g) << 8 | u32(current_r)
			current_index++
		}
	}

	return palette
}

// constructor
pub fn mandel(w int, h int, iters int, center cmplx.Complex, range cmplx.Complex) Mandel {
	return Mandel{
		w:     w
		h:     h
		size:  w * h
		iters: iters

		center: center
		range:  range

		cr:    cmplx.complex(range.re, range.re)
		rir:   range.im - range.re
		scale: 0.8 * f64(w) / h

		image: []u32{len: w * h}

		fire_pallete: fire_pallete_256 
	}
}

fn (m Mandel) do_scale(iw int, jh int) cmplx.Complex {
	c00 := m.cr + cmplx.complex(m.rir * f64(iw) / f64(m.w), m.rir * f64(jh) / f64(m.h))
	return cmplx.complex(c00.re * m.scale - m.center.re, c00.im * m.scale - m.center.im)
}

fn (mut m Mandel) gen_pixels(th int, n_threads int) {
	for index in th * m.size / n_threads .. (th + 1) * m.size / n_threads {
		c0 := m.do_scale(index % m.w, index / m.w)

		mut z := c0
		mut i := 0

		for i < m.iters && z.norm() < 4.0 {
			z = z * z + c0
			i++
		}

		if i == m.iters {
			m.image[index] = 0xff000000
		} else {
			m.image[index] = 0xff000000 | m.fire_pallete[(u32(i) << 2) % u32(m.fire_pallete.len)]
		}
	}
}

pub fn (mut m Mandel) gen_image(n_threads int) []u32 {
	mut threads := []thread{}

	for th in 0 .. n_threads {
		threads << spawn m.gen_pixels(th, n_threads)
	}

	threads.wait()

	return m.image
}

pub fn (m Mandel) get_image() []u32 {
	return m.image
}

//////////
