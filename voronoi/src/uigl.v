// plain valilla glfw / opengl ui

module voronoi

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
	zoom       f32 = f32(-3)
	is_pressed bool
	// voronoi
	voronoi_ Voronoi
	npts     int = 150

	single_thread bool

	lap time.Duration
}

fn get_app(window voidptr) &App { // get the app object from window user pointer
	app := unsafe { &App(C.glfwGetWindowUserPointer(window)) }
	if app.magic != magic_app { // check it
		panic('invalid app object, magic:${app.magic}, expected:${magic_app}')
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
				app.npts += 10
			}
			.down {
				app.npts -= 10
			}
			.page_down {
				app.npts += 100
			}
			.page_up {
				app.npts -= 100
			}
			.s {
				app.single_thread = true
			}
			.m {
				app.single_thread = false
			}
			else {}
		}

		build_voronoi(window)
	}
}

fn draw_gl(app App) {
	C.glColor3f(1, 1, 1) // max color contrast
	panel(1.3) // with texture assigned just draw a squared panel
}

fn build_voronoi(window voidptr) {
	mut app := get_app(window)
	w, h := get_window_size(window)

	t0 := now()

	app.voronoi_ = new_voronoi(w, h, app.npts, app.single_thread)

	app.lap = now() - t0

	C.glfwSetWindowTitle(window, 'voronoi, w: ${w}, h: ${h}, [${if app.single_thread {
		'ST'
	} else {
		'MT'
	}}] #points: ${app.npts} lap: ${app.lap}'.str)

	// assign to texture
	set_argb_data(app.voronoi_.w, app.voronoi_.h, 1, app.voronoi_.image)
}

pub fn ui_glfw() {
	glfw_init()

	// Create a windowed mode window and its OpenGL context
	window := create_window(win_width, win_height, 'voronoi')

	vm := C.glfwGetVideoMode(C.glfwGetPrimaryMonitor())
	set_window_pos(window, (vm.width - win_width), (vm.height - win_height))

	C.glfwMakeContextCurrent(window) // Make the window's context current
	C.glfwSetKeyCallback(window, key_callback) // key callback

	mut app := App{} // create app obj and set as window's user pointer
	C.glfwSetWindowUserPointer(window, &app)

	build_voronoi(window)

	C.glfwSwapInterval(0.5)

	// Loop until the user closes the window
	for C.glfwWindowShouldClose(window) == 0 {
		init_render(window, bg_color) // bg color

		C.glTranslatef(0.0, 0.0, app.zoom)
		C.glRotatef(app.mouse_y, 1, 0, 0)
		C.glRotatef(app.mouse_x, 0, 1, 0)

		draw_gl(app) // render voronoi

		C.glfwSwapBuffers(window) // Swap front and back buffers	
		C.glfwPollEvents() // Poll for and process events
	}

	C.glfwTerminate()
}
