/*
 * mandelbrot set fractal generator
 *
 * This is a simple mandelbrot set fractal generator using V and gg library.
 * It uses the mandelbrot set algorithm to generate the fractal image.

*/
module main

import mandel
import math.complex as cmplx
import time
import runtime
import os
import gg
import gx

// fractal config.
const mandel_w = 1024
const mandel_h = 1024
const inc_iters = 50
const def_iters = 200

const def_center = cmplx.complex(0.5, 0.0)
const def_range = cmplx.complex(-2.0, 2.0)

const zoom_factor = 0.8

fn test_mandel(n int) {
	mut m := mandel.mandel(n, n, 200, cmplx.complex(0.5, 0.0), cmplx.complex(-2.0, 2.0))

	n_threads := runtime.nr_cpus()
	println('generating mandelbrot set ${n}x${n} = ${n * n} items, using ${n_threads} threads')
	t0 := time.now()
	m.gen_image(n_threads)

	println('done, lap:${time.now() - t0}\nwriting image.bin file')
	os.write_file_array('image.bin', m.get_image()) or {
		println('failed to write image.bin: ${err}')
		return
	}
}

struct App {
mut:
	gg     &gg.Context = unsafe { nil }
	mandel mandel.Mandel
	isi    int

	center cmplx.Complex = def_center
	range  cmplx.Complex = def_range
	iters  int           = def_iters
	lap    time.Duration
}

fn (mut app App) gen_mandel() { // fixed size (mandel_w, mandel_h)
	app.mandel = mandel.mandel(mandel_w, mandel_h, app.iters, app.center, app.range)
	t0 := time.now()
	app.mandel.gen_image(runtime.nr_cpus())
	app.lap = time.now() - t0

	mut img := app.gg.get_cached_image_by_idx(app.isi) // update image
	img.update_pixel_data(unsafe { &u8(&app.mandel.image[0]) })
}

fn (mut app App) win_size() (int, int) {
	win_sz := app.gg.window_size()
	return int(win_sz.width * app.gg.scale), int(win_sz.height * app.gg.scale)
}

fn (mut app App) recalculate_center_range(x f32, y f32) {
	w, h := app.win_size()
	dist := f64(w / 2)
	rx := dist / w
	ry := dist / h
	ratio := app.range.abs()

	app.center += cmplx.complex(ratio * (w / 2 - x) / w, ratio * (h / 2 - y) / h)
	app.range = cmplx.complex(app.range.re * rx, app.range.im * ry)

	app.update()
}

fn init(mut app App) {
	app.isi = app.gg.new_streaming_image(mandel_w, mandel_h, 4, pixel_format: .rgba8)
	app.gen_mandel()
}

fn (mut app App) draw() {
	win_sz := app.gg.window_size()

	app.gg.draw_image_by_id(0, 0, win_sz.width, win_sz.height, app.isi)
	app.gg.draw_rect_filled(0, 0, win_sz.width, 15, gx.white)
	app.gg.draw_text_def(0, 0, 'lap: ${app.lap}, center: ${app.center:.2}, range: ${app.range:.2}, iters: ${app.iters}, scale ${app.range.abs():.3e}')
}

fn frame(mut app App) {
	app.gg.begin()
	app.draw()
	app.gg.end()
}

fn (mut app App) update() {
	app.gen_mandel()
}

fn (mut app App) on_key_down(key gg.KeyCode) {
	match key {
		.home, .space { // restore to default

			app.center = def_center
			app.range = def_range
			app.iters = def_iters

			app.update()
		}
		.page_up { // zoom out
			app.range = cmplx.complex(app.range.re / zoom_factor, app.range.im / zoom_factor)
			app.update()
		}
		.page_down { // zoom in
			app.range = cmplx.complex(app.range.re * zoom_factor, app.range.im * zoom_factor)
			app.update()
		}
		.up {
			app.iters += inc_iters
			app.update()
		}
		.down {
			if app.iters > inc_iters {
				app.iters -= inc_iters
				app.update()
			}
		}
		//
		.escape {
			app.gg.quit()
		}
		.backspace {}
		.enter {
			app.range = cmplx.complex(app.range.re * zoom_factor, app.range.im * zoom_factor)
			app.update()
		}
		else {}
	}
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.key_down {
			app.on_key_down(e.key_code)
		}
		.resized {}
		.restored, .resumed {
			// app.resize()
		}
		.mouse_down {
			app.recalculate_center_range(e.mouse_x * app.gg.scale, e.mouse_y * app.gg.scale)
		}
		else {}
	}
}

fn gui() {
	mut app := &App{}

	app.gg = gg.new_context(
		width:        800 * 2 // mandel_w*2
		height:       800 * 2 // mandel_h*2
		window_title: 'mandelbrot set'

		init_fn:  init
		frame_fn: frame
		event_fn: on_event

		user_data: app
	)

	app.gg.run()
}

fn main() {
	// test_mandel(mandel_w)	
	gui()
}
