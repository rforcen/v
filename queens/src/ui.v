/*
 * queens problem

key codes:

	.space: update
	.kp_add: increase board size
	.kp_subtract: decrease board size
	.left: previous solution
	.right: next solution
	.page_up: increase max solutions
	.page_down: decrease max solutions
	.escape: quit
*/
module queens

import time
import runtime { nr_cpus }
import gg
import gx
import math { min }

const initial_size = 16 // init board size
const n_auto_update = 25 // auto update board size
const n_min_board = 4 // min board size
const inital_width = 800 * 2
const inital_height = 800 * 2

struct App {
mut:
	gg &gg.Context = unsafe { nil }

	q       Queens
	n       int = initial_size // board size (n queens)
	nsol    int // current solution displayed
	max_sol int = 10 // max solutions to display
	lap     time.Duration
}

fn (mut app App) gen_queens() {
	app.q = new_queens(app.n)

	t0 := time.now()

	if app.n < nr_cpus() { // sweet point to launch mt
		app.q.scan(app.max_sol)
	} else {
		app.q.scan_mt(nr_cpus(), app.max_sol)
	}
	app.lap = time.now() - t0

	app.nsol = 0
	app.q.set_solution(app.nsol)
}

fn init(mut app App) {
	app.gen_queens()
}

fn (mut app App) draw() {
	gg.set_window_title('queens problem ${app.n}, solution: ${app.nsol + 1}/${app.q.count_solutions}, max solutions: ${app.max_sol}, evals: ${app.q.count_evals}, lap: ${app.lap}')

	w, h := app.gg.window_size().width, app.gg.window_size().height
	l := min(w, h) // avoid distorsion, squared cells

	d := l / f32(app.n) // square size
	d2:=d/2
	xoff, yoff := (w - l) / 2, (h - l) / 2 // offset in window

	app.gg.draw_rect_filled(0, 0, w, h, gx.white) // clear
	app.gg.draw_rect_empty(xoff, yoff, l, l, gx.black) // frame

	// board grid
	for i in 0 .. app.n {
		app.gg.draw_line(xoff, i * d + yoff, xoff + l, i * d + yoff, gx.black) // horz
		app.gg.draw_line(i * d + xoff, yoff, i * d + xoff, yoff + l, gx.black) // vert
	}

	// queens as circles
	for i in 0 .. app.n {
		app.gg.draw_circle_filled(xoff + i * d + d2, yoff + (app.n - 1 - app.q.board[i]) * d +
			d2, 0.8 * d2, gx.red)
		app.gg.draw_circle_filled(xoff + i * d + d2, yoff + (app.n - 1 - app.q.board[i]) * d +
			d2, 0.2 * d2, gx.yellow)
	}
}

fn frame(mut app App) {
	app.gg.begin()
	app.draw()
	app.gg.end()
}

fn (mut app App) update() {
	app.gen_queens()
}

fn (mut app App) on_key_down(key gg.KeyCode) {
	match key {
		.space {
			app.update()
		}
		.w {
			println('${app.n}: ${app.q.board}')
		}
		.kp_add {
			app.n++
			if app.n < n_auto_update {
				app.update()
			} else {
				app.q = new_queens(app.n)
			}
		}
		.kp_subtract {
			app.n--
			if app.n < n_min_board {
				app.n = n_min_board
			}
			if app.n < n_auto_update {
				app.update()
			} else {
				app.q = new_queens(app.n)
			}
		}
		.left {
			app.nsol--
			if app.nsol < 0 {
				app.nsol = app.q.count_solutions - 1
			}
			app.q.set_solution(app.nsol)
		}
		.right {
			app.nsol++
			if app.nsol >= app.q.count_solutions {
				app.nsol = 0
			}
			app.q.set_solution(app.nsol)
		}
		.page_up {
			app.max_sol++
		}
		.page_down {
			app.max_sol--
			if app.max_sol < 0 {
				app.max_sol = 0
			}
		}
		//
		.escape {
			app.gg.quit()
		}
		else {}
	}
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.key_down {
			app.on_key_down(e.key_code)
		}
		else {}
	}
}

pub fn gui() {
	mut app := &App{}

	app.gg = gg.new_context(
		width:        inital_width
		height:       inital_height
		window_title: 'queens problem'

		init_fn:  init
		frame_fn: frame
		event_fn: on_event

		user_data: app
	)

	app.gg.run()
}
