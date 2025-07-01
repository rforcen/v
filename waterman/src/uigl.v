// plain valilla glfw / opengl ui

module waterman

import time { now }
import rand
import math

const win_width = 800 * 2
const win_height = 800 * 2
const bg_color = [f32(0.7), f32(0.7), f32(0.7), f32(1.0)] // background color, fashion gray

const magic_app = 314159265
// shared data
@[heap]
struct App {
mut:
	magic int = magic_app
	// geo
	mouse_x    int = -1
	mouse_y    int = -1
	zoom       f32 = f32(-4)
	is_pressed bool
	// waterman
	rad  f64 = 90
	poly Polyhedron

	lap time.Duration
}

fn get_app(window voidptr) &App { // get the app object from window user pointer
	app := unsafe { &App(C.glfwGetWindowUserPointer(window)) }
	if app.magic != magic_app {
		panic('invalid app object')
	}
	return app
}

fn key_callback(window voidptr, key int, scancode int, action int, mods int) {
	mut app := get_app(window)

	if action == C.GLFW_RELEASE {
		match to_key_code(key) {
			.escape {
				C.glfwSetWindowShouldClose(window, C.GLFW_TRUE)
			}
			.up {
				app.rad++
			}
			.down {
				app.rad--
				if app.rad < 0 {
					app.rad = 0
				}
			}
			.page_down {
				app.rad -= 10.0
				if app.rad < 10 {
					app.rad = 0
				}
			}
			.page_up {
				app.rad += 10.0
			}
			.space {
				app.rad = math.round(rand.f64() * 10000.0)
			}
			.v {
				app.poly.write_vrml() or { println('error writing vrml') }
			}
			.r { // recolor
				// app.poly.colors()
			}
			.n1 {
				app.rad = 16
			}
			.n2 {
				app.rad = 20
			}
			.n3 {
				app.rad = 30
			}
			.n4 {
				app.rad = 40
			}
			.n9 {
				app.rad = 9000
			}
			else {}
		}
		build_poly(window)
	}
}

fn cursor_position_callback(window voidptr, xpos f64, ypos f64) {
	mut app := get_app(window)
	if app.is_pressed {
		app.mouse_x = int(xpos)
		app.mouse_y = int(ypos)
	}
}

fn mouse_button_callback(window voidptr, button int, action int, mods int) {
	mut app := get_app(window)
	if button == C.GLFW_MOUSE_BUTTON_LEFT && action == C.GLFW_PRESS {
		app.is_pressed = true
	}
	if button == C.GLFW_MOUSE_BUTTON_LEFT && action == C.GLFW_RELEASE {
		app.is_pressed = false
	}
}

fn scroll_callback(window voidptr, xoffset f64, yoffset f64) {
	mut app := get_app(window)
	app.zoom += f32(yoffset)
}

fn draw_gl(poly Polyhedron) {
	for ix_face, face in poly.faces {
		C.glBegin(C.GL_POLYGON)

		C.glColor3f(poly.colors[ix_face].x, poly.colors[ix_face].y, poly.colors[ix_face].z)
		C.glNormal3f(poly.normals[ix_face].x, poly.normals[ix_face].y, poly.normals[ix_face].z)

		for v in face {
			C.glVertex3f(poly.vertexes[v].x, poly.vertexes[v].y, poly.vertexes[v].z)
		}

		C.glEnd()
	}
	draw_gl_lines(poly)
}

fn draw_gl_lines(poly Polyhedron) {
	C.glColor3f(0, 0, 0)

	for face in poly.faces {
		C.glBegin(C.GL_LINE_LOOP)

		for v in face {
			C.glVertex3f(poly.vertexes[v].x, poly.vertexes[v].y, poly.vertexes[v].z)
		}

		C.glEnd()
	}
}

fn build_poly(window voidptr) {
	mut app := get_app(window)
	t0 := now()

	faces, vertexes := waterman(app.rad)
	app.poly = new_polyhedron(faces, vertexes)

	app.lap = now() - t0

	C.glfwSetWindowTitle(window, 'waterman polyhedron, rad: ${app.rad:.0}, faces: ${app.poly.faces.len}, vertexes: ${app.poly.vertexes.len}, lap: ${app.lap}'.str)
}

pub fn ui_glfw() {
	glfw_init()

	// Create a windowed mode window and its OpenGL context
	window := create_window(win_width, win_height, 'waterman polyhedron')

	vm := C.glfwGetVideoMode(C.glfwGetPrimaryMonitor())
	set_window_pos(window, (vm.width - win_width), (vm.height - win_height))

	mut app := App{} // create app obj and set as window's user pointer
	C.glfwSetWindowUserPointer(window, &app)

	C.glfwMakeContextCurrent(window) // Make the window's context current
	// callbacks
	C.glfwSetKeyCallback(window, key_callback) // key callback
	C.glfwSetCursorPosCallback(window, cursor_position_callback) // cursor position callback
	C.glfwSetMouseButtonCallback(window, mouse_button_callback) // mouse button callback
	C.glfwSetScrollCallback(window, scroll_callback) // scroll callback

	C.glfwSwapInterval(1)

	// scene_init()
	simple_scene()

	build_poly(window)

	// Loop until the user closes the window
	for C.glfwWindowShouldClose(window) == 0 {
		init_render(window, bg_color) // bg color

		C.glTranslatef(0.0, 0.0, app.zoom)
		C.glRotatef(app.mouse_y, 1, 0, 0)
		C.glRotatef(app.mouse_x, 0, 1, 0)

		draw_gl(app.poly) // render poly

		C.glfwSwapBuffers(window) // Swap front and back buffers	
		C.glfwPollEvents() // Poll for and process events
	}

	C.glfwTerminate()
}
