// plain valilla glfw / opengl ui

module sh

import time { now }

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
	// sh
	sh_           SH
	sh_code       int = rand_code()
	color_map     int = 7
	res           int = 256
	single_thread bool

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
				app.sh_code++
				if app.sh_code >= sh_codes.len {
					app.sh_code = 0
				}
				build_sh(window)
			}
			.down {
				app.sh_code--
				if app.sh_code < 0 {
					app.sh_code = sh_codes.len - 1
				}
				build_sh(window)
			}
			.page_down {
				app.res /= 2
				if app.res < 8 {
					app.res = 8
				}
				build_sh(window)
			}
			.page_up {
				app.res *= 2
				if app.res > 2048 {
					app.res = 2048
				}
				build_sh(window)
			}
			.space {
				app.sh_code = rand_code()
				build_sh(window)
			}
			.r {
				app.sh_code = rand_code()
				build_sh(window)
			}
			.s {
				app.single_thread = true
				build_sh(window)
			}
			.m {
				app.single_thread = false
				build_sh(window)
			}
			.o {
				app.sh_.write_obj() or { println('error writing obj') }
			}
			.right {
				app.color_map++
				if app.color_map > max_color_map {
					app.color_map = 0
				}
				build_sh(window)
			}
			.left {
				app.color_map--
				if app.color_map < 0 {
					app.color_map = max_color_map
				}
				build_sh(window)
			}
			.n1 {
				app.color_map = 1
				build_sh(window)
			}
			.n2 {
				app.color_map = 2
				build_sh(window)
			}
			.n3 {
				app.color_map = 3
				build_sh(window)
			}
			.n4 {
				app.color_map = 4
				build_sh(window)
			}
			.n5 {
				app.color_map = 5
				build_sh(window)
			}
			.n6 {
				app.color_map = 6
				build_sh(window)
			}
			.n7 {
				app.color_map = 7
				build_sh(window)
			}
			else {}
		}
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

fn draw_gl(sh_ SH) {
	for face in sh_.faces {
		C.glBegin(C.GL_QUADS)

		for v in face {
			mv := sh_.mesh[v]
			crd, nrm, col := mv.coord.tof32(), mv.normal.tof32(), mv.color.tof32()

			C.glColor3f(col.x, col.y, col.z)
			C.glNormal3f(nrm.x, nrm.y, nrm.z)
			C.glVertex3f(crd.x, crd.y, crd.z)
		}

		C.glEnd()
	}
}

fn build_sh(window voidptr) {
	mut app := get_app(window)
	t0 := now()

	app.sh_ = new_sh_mode(app.res, app.color_map, app.sh_code, app.single_thread)

	app.lap = now() - t0

	C.glfwSetWindowTitle(window, 'spherical harmonics, [${if app.single_thread {
		'ST'
	} else {
		'MT'
	}}] res: ${app.res}, code: ${sh_codes[app.sh_code]}, color map: ${app.color_map}, faces: ${app.sh_.faces.len}, vertexes: ${app.sh_.mesh.len}, lap: ${app.lap}'.str)
}

pub fn ui_glfw() {
	glfw_init()

	// Create a windowed mode window and its OpenGL context
	window := create_window(win_width, win_height, 'spherical harmonics')

	vm := C.glfwGetVideoMode(C.glfwGetPrimaryMonitor())
	set_window_pos(window, (vm.width - win_width), (vm.height - win_height))

	mut app := App{} // create app obj and set as window's user pointer
	C.glfwSetWindowUserPointer(window, &app)
	build_sh(window)

	C.glfwMakeContextCurrent(window) // Make the window's context current
	// callbacks
	C.glfwSetKeyCallback(window, key_callback) // key callback
	C.glfwSetCursorPosCallback(window, cursor_position_callback) // cursor position callback
	C.glfwSetMouseButtonCallback(window, mouse_button_callback) // mouse button callback
	C.glfwSetScrollCallback(window, scroll_callback) // scroll callback

	C.glfwSwapInterval(0.5)

	scene_init()

	// Loop until the user closes the window
	for C.glfwWindowShouldClose(window) == 0 {
		init_render(window, bg_color) // bg color

		C.glTranslatef(0.0, 0.0, app.zoom)
		C.glRotatef(app.mouse_y, 1, 0, 0)
		C.glRotatef(app.mouse_x, 0, 1, 0)

		draw_gl(app.sh_) // render sh

		C.glfwSwapBuffers(window) // Swap front and back buffers	
		C.glfwPollEvents() // Poll for and process events
	}

	C.glfwTerminate()
}
