// ui
module poly

import gg
import gx
import sokol.sapp
import sokol.gfx
import sokol.sgl as gl
import rand
import rand.seed { time_seed_array }
import time { now }

const win_width = 800 * 2
const win_height = 800 * 2
const bg_color = gx.rgb(174, 198, 255) // Light blue background

struct App {
mut:
	gg     &gg.Context = unsafe { nil }
	pip_3d gl.Pipeline

	init_flag   bool
	frame_count int
	mouse_x     int = -1
	mouse_y     int = -1

	poly_ Polyhedron = *new_polyhedron(tetrahedron) // johnson[81])
	lap   time.Duration
	zoom  f32 = f32(-4)
}

// vertex specification for a draw_polyhedron with colored sides and texture coords
fn draw_lines_loop(face []int, vertex []Vertex) {
	dr_vtx := fn (v int, vertex []Vertex) {
		vx := vertex[v]
		gl.v3f(vx.x, vx.y, vx.z)
	}

	gl.begin_line_strip()
	{
		for v in face {
			dr_vtx(v, vertex)
		}
		dr_vtx(face[0], vertex) // line_loop
	}
	gl.end()
}

fn draw_polygon(face []int, ixf int, vertex []Vertex, colors []Vertex) {
	dr_vtx := fn (v int, vertex []Vertex) {
		vx := vertex[v]
		gl.v3f(vx.x, vx.y, vx.z)
	}

	gl.begin_triangles()
	{
		gl.c3f(colors[ixf].x, colors[ixf].y, colors[ixf].z)
		for f in tesselate(face) {
			for v in f {
				dr_vtx(v, vertex)
			}
		}
	}
	gl.end()
}

fn draw_normals(face []int, ixf int, centers []Vertex) {
	gl.c3f(0, 0, 0)
	gl.begin_lines()
	gl.v3f(centers[ixf].x, centers[ixf].y, centers[ixf].z)
	gl.v3f(centers[ixf].x * 1.05, centers[ixf].y * 1.05, centers[ixf].z * 1.05)
	gl.end()
}

fn draw_polyhedron(p &Polyhedron) {
	for ixf, face in p.faces {
		draw_polygon(face, ixf, p.vertexes_, p.colors)

		gl.c3f(0, 0, 0)
		if p.vertexes_.len < 100 {
			draw_lines_loop(face, p.vertexes_)
		}
	}
}

fn draw(app App) {
	gl.defaults()
	gl.load_pipeline(app.pip_3d)

	gl.matrix_mode_projection()
	gl.perspective(gl.rad(45.0), 1, 0.1, 100)

	gl.matrix_mode_modelview()
	gl.translate(0, 0, app.zoom)
	gl.rotate(gl.rad(app.mouse_x), 1, 0, 0)
	gl.rotate(gl.rad(app.mouse_y), 0, 1, 0)

	if app.poly_.has_vertexes() {
		draw_polyhedron(app.poly_)
	}
}

fn frame(mut app App) {
	app.gg.begin()

	app.frame_count++

	draw(app)
	gg.set_window_title('${app.poly_.name}, faces: ${app.poly_.faces.len}, vertexes: ${app.poly_.vertexes_.len}, lap: ${app.lap}')

	app.gg.end()
}

fn my_init(mut app App) {
	app.init_flag = true

	// set max vertices,
	// for a large number of the same type of object it is better use the instances!!
	desc := sapp.create_desc()
	gfx.setup(&desc)
	sgl_desc := gl.Desc{
		max_vertices: 500 * 65536
	}
	gl.setup(&sgl_desc)

	// 3d pipeline
	mut pipdesc := gfx.PipelineDesc{}
	unsafe { vmemset(&pipdesc, 0, int(sizeof(pipdesc))) }

	color_state := gfx.ColorTargetState{
		blend: gfx.BlendState{
			enabled:        true
			src_factor_rgb: .src_alpha
			dst_factor_rgb: .one_minus_src_alpha
		}
	}
	pipdesc.colors[0] = color_state

	pipdesc.depth = gfx.DepthState{
		write_enabled: true
		compare:       .less_equal
	}
	pipdesc.cull_mode = .none // .back
	app.pip_3d = gl.make_pipeline(&pipdesc)
}

fn (mut app App) rebuild_poly() {
	app.poly_ = app.poly_.rebuild()
}

fn my_event_manager(mut ev gg.Event, mut app App) {
	match ev.typ {
		.mouse_move {
			app.mouse_x = int(ev.mouse_y)
			app.mouse_y = int(ev.mouse_x)
		}
		.mouse_scroll {
			app.zoom += ev.scroll_y
		}
		// .touches_began, .touches_moved {
		// 	if ev.num_touches > 0 {
		// 		touch_point := ev.touches[0]
		// 		app.mouse_x = int(touch_point.pos_x)
		// 		app.mouse_y = int(touch_point.pos_y)
		// 	}
		// }
		.key_down {
			is_shift := fn [ev] () bool {
				return ev.modifiers & 0x1 != 0
			}

			if is_shift() { // polyhedron code
				match ev.key_code {
					.t {
						app.poly_ = new_polyhedron(tetrahedron)
					}
					.c {
						app.poly_ = new_polyhedron(cube)
					}
					.i {
						app.poly_ = new_polyhedron(icosahedron)
					}
					.o {
						app.poly_ = new_polyhedron(octahedron)
					}
					.d {
						app.poly_ = new_polyhedron(dodecahedron)
					}
					.j {
						rj := rand.int_in_range(0, 92) or { 0 }
						app.poly_ = new_polyhedron(johnson[rj])
					}
					.s {
						app.poly_ = sphere(1, 25)
						app.poly_.recalc()
					}
					.l { // load from depot
						mut ps := depot[rand.int_in_range(0, depot.len - 1) or { 0 }].scale_unit()
						app.poly_ = ps.recalc()
					}
					else {}
				}
			} else {
				start := now()

				match ev.key_code {
					.escape {
						app.gg.quit()
					}
					.backspace {
						if 'kaqghpci'.contains(rune(app.poly_.name[0]).str()) {
							app.poly_.name = app.poly_.name[1..app.poly_.name.len]
							app.rebuild_poly()
						}
					}
					.x {
						app.rebuild_poly()
					}
					.z{
						app.poly_=build_rand(5)
					}
					.r { // recolor poly
						app.poly_.colors()
					}
					.o { // save obj
						app.poly_.write_obj() or { println('error writing obj') }
					}
					.v { // save vrml
						app.poly_.write_vrml() or { println('error writing vrml') }
					}
					// transformations
					.k {
						app.poly_ = kiss_n(mut app.poly_, 0, 0.1)
					}
					.a {
						app.poly_ = ambo(mut app.poly_)
					}
					.q {
						app.poly_ = quinto(mut app.poly_)
					}
					.g {
						app.poly_ = gyro(mut app.poly_)
					}
					.h {
						app.poly_ = hollow(mut app.poly_)
					}
					.p {
						app.poly_ = propellor(mut app.poly_)
					}
					.c {
						app.poly_ = chamfer(mut app.poly_)
					}
					.i {
						app.poly_ = inset(mut app.poly_)
					}
					else {}
				}
				if ev.key_code in [.k, .a, .q, .g, .h, .p, .d, .c, .i, .z] {
					app.poly_.recalc()
				}
				app.lap = now() - start
			}
		}
		else {}
	}
}

pub fn ui() {
	rand.seed(time_seed_array(2))

	mut app := &App{}
	app.gg = gg.new_context(
		width:         win_width
		height:        win_height
		create_window: true
		window_title:  'polyhedronisme'
		user_data:     app
		bg_color:      bg_color
		frame_fn:      frame
		init_fn:       my_init
		event_fn:      my_event_manager
	)
	app.gg.run()
}
