// glfw3 & opengl minimal wrapper for this app
//
module voronoi

import math { tan }

#include <GLFW/glfw3.h>
#flag -lGL -lglfw3 -lm

// open gl wrapper
fn C.glBegin(int)
fn C.glEnd()
fn C.glColor3f(f32, f32, f32)
fn C.glVertex3f(f32, f32, f32)
fn C.glVertex3d(f64, f64, f64)
fn C.glVertex2f(f32, f32)
fn C.glVertex2d(f64, f64)
fn C.glNormal3f(f32, f32, f32)
fn C.glNormal3d(f64, f64, f64)
fn C.glColor3f(f32, f32, f32)
fn C.glColor3d(f64, f64, f64)
fn C.glClear(int)
fn C.glClearColor(f32, f32, f32, f32)
fn C.glLoadIdentity()
fn C.glTranslatef(f32, f32, f32)
fn C.glRotatef(f32, f32, f32, f32)
fn C.glRotatef(f32, f32, f32, f32)
fn C.glFlush()
fn C.glLightfv(int, int, &f32)
fn C.glEnable(int)
fn C.glDisable(int)
fn C.glLightModelfv(int, &f32)
fn C.glMaterialfv(int, int, &f32)
fn C.glShadeModel(int)
fn C.glHint(int, int)
fn C.glClearDepth(f64)

fn C.glFlush()
fn C.glClear(int)
fn C.glViewport(int, int, int, int)
fn C.glMatrixMode(int)
fn C.glLoadIdentity()
fn C.glRotatef(f32, f32, f32, f32)
fn C.glTranslatef(f32, f32, f32)
fn C.glPerspective(f32, f32, f32, f32)
fn C.glDepthFunc(int)
fn C.glDepthMask(int)
fn C.glCullFace(int)
fn C.glFrontFace(int)
fn C.glEnable(int)
fn C.glDisable(int)
fn C.glFrustum(f64, f64, f64, f64, f64, f64)
fn C.glTexCoord2d(f64, f64)
fn C.glTexCoord2f(f32, f32)
fn C.glTexCoord2d(f64, f64)
fn C.glTexImage2D(int, int, int, int, int, int, int, int, &u32)
fn C.glTexParameteri(int, int, int)
fn C.glDeleteTextures(int, &int)
fn C.glGenTextures(int, &int)
fn C.glBindTexture(int, int)
fn C.glTexEnvi(int, int, int)
fn C.glTexEnvi(int, int, int)
fn C.glGetIntegerv(int, &int)

// glfw wrapper
fn C.glfwInit() int
fn C.glfwTerminate()
fn C.glfwCreateWindow(int, int, &char, &char, &char) voidptr
fn C.glfwMakeContextCurrent(voidptr)
fn C.glfwSwapBuffers(voidptr)
fn C.glfwPollEvents()
fn C.glfwWindowShouldClose(voidptr) int
fn C.glfwTerminate()
fn C.glfwGetProcAddress(&char) &char
fn C.glfwSetKeyCallback(&char, fn (&char, int, int, int, int))
fn C.glfwSetCursorPosCallback(&char, fn (&char, f64, f64))
fn C.glfwSetMouseButtonCallback(&char, fn (&char, int, int, int))
fn C.glfwSetWindowShouldClose(&char, int)
fn C.glfwSwapInterval(int)
fn C.glfwSetWindowUserPointer(voidptr, voidptr) // win, user
fn C.glfwGetWindowUserPointer(voidptr) voidptr
fn C.glfwSetWindowTitle(window voidptr, title &char)
fn C.glfwSetScrollCallback(window voidptr, scroll_callback fn (voidptr, f64, f64))
fn C.glfwGetPrimaryMonitor() voidptr
fn C.glfwGetWindowSize(window voidptr, width &int, height &int)

struct C.GLFWvidmode {
	width        int
	height       int
	red_bits     int
	green_bits   int
	blue_bits    int
	refresh_rate int
}

fn C.glfwGetVideoMode(voidptr monitor) &C.GLFWvidmode
fn C.glfwSetWindowPos(window voidptr, int, int)

fn scene_init() { // works nice for golden solid colors (requires normals)
	lmodel_ambient := [f32(0), f32(0), f32(0), f32(0)]
	lmodel_twoside := [f32(C.GL_FALSE)]
	light0_ambient := [f32(0.1), f32(0.1), f32(0.1), f32(1)]
	light0_diffuse := [f32(1), f32(1), f32(1), f32(0)]
	light0_position := [f32(1), 0.5, 1, 0]
	light1_position := [f32(-1), 0.5, -1, 0]
	light0_specular := [f32(1), 1, 1, 0]
	bevel_mat_ambient := [f32(0), 0, 0, 1]
	bevel_mat_shininess := [f32(40)]
	bevel_mat_specular := [f32(1), 1, 1, 0]
	bevel_mat_diffuse := [f32(1), 0, 0, 0]

	//  glClearColor((color.redF()), (color.greenF()), (color.blueF()),               1);

	C.glLightfv(C.GL_LIGHT0, C.GL_AMBIENT, &light0_ambient[0])
	C.glLightfv(C.GL_LIGHT0, C.GL_DIFFUSE, &light0_diffuse[0])
	C.glLightfv(C.GL_LIGHT0, C.GL_SPECULAR, &light0_specular[0])
	C.glLightfv(C.GL_LIGHT0, C.GL_POSITION, &light0_position[0])
	C.glEnable(C.GL_LIGHT0)

	C.glLightfv(C.GL_LIGHT1, C.GL_AMBIENT, &light0_ambient[0])
	C.glLightfv(C.GL_LIGHT1, C.GL_DIFFUSE, &light0_diffuse[0])
	C.glLightfv(C.GL_LIGHT1, C.GL_SPECULAR, &light0_specular[0])
	C.glLightfv(C.GL_LIGHT1, C.GL_POSITION, &light1_position[0])
	C.glEnable(C.GL_LIGHT1)

	C.glLightModelfv(C.GL_LIGHT_MODEL_TWO_SIDE, &lmodel_twoside[0])
	C.glLightModelfv(C.GL_LIGHT_MODEL_AMBIENT, &lmodel_ambient[0])
	C.glEnable(C.GL_LIGHTING)

	C.glMaterialfv(C.GL_FRONT, C.GL_AMBIENT, &bevel_mat_ambient[0])
	C.glMaterialfv(C.GL_FRONT, C.GL_SHININESS, &bevel_mat_shininess[0])
	C.glMaterialfv(C.GL_FRONT, C.GL_SPECULAR, &bevel_mat_specular[0])
	C.glMaterialfv(C.GL_FRONT, C.GL_DIFFUSE, &bevel_mat_diffuse[0])

	C.glEnable(C.GL_COLOR_MATERIAL)
	C.glShadeModel(C.GL_SMOOTH)

	C.glEnable(C.GL_LINE_SMOOTH)

	C.glHint(C.GL_LINE_SMOOTH_HINT, C.GL_NICEST)
	C.glHint(C.GL_POLYGON_SMOOTH_HINT, C.GL_NICEST)

	C.glClearDepth(f64(1.0)) // Set background depth to farthest
	C.glEnable(C.GL_DEPTH_TEST) // Enable depth testing for z-culling
	C.glDepthFunc(C.GL_LEQUAL) // Set the type of depth-test
	C.glShadeModel(C.GL_SMOOTH) // Enable smooth shading
	C.glHint(C.GL_PERSPECTIVE_CORRECTION_HINT, C.GL_NICEST) //  Nice perspective corrections
}

fn perspective_gl(fov_y f64, aspect f64, z_near f64, z_far f64) {
	f_h := tan(fov_y / 360.0 * math.pi) * z_near
	f_w := f_h * aspect
	C.glFrustum(-f_w, f_w, -f_h, f_h, z_near, z_far)
}

fn panel(l f64) {
	lx := l
	ly := l

	//    if (w>h) lx = l * (float)w/h;
	//    else ly = l * (float)h/w;

	C.glBegin(C.GL_QUADS)

	C.glTexCoord2d(0, 0)
	C.glVertex2d(-lx, -ly)
	C.glTexCoord2d(0, 1)
	C.glVertex2d(-lx, ly)
	C.glTexCoord2d(1, 1)
	C.glVertex2d(lx, ly)
	C.glTexCoord2d(1, 0)
	C.glVertex2d(lx, -ly)

	C.glEnd()
}

fn get_active_texture() int {
	mut act_text_unit := 0
	C.glGetIntegerv(C.GL_ACTIVE_TEXTURE, &act_text_unit)
	// activeTextureUnit will be GL_TEXTURE0, GL_TEXTURE1, etc.
	// To get the index (0, 1, 2, ...), subtract GL_TEXTURE0:
	return act_text_unit - C.GL_TEXTURE0
}

fn set_argb_data(w int, h int, text_num int, image []u32) { // texture = w, h, image
	C.glEnable(C.GL_TEXTURE_2D)

	if get_active_texture() == text_num {
		C.glDeleteTextures(1, &text_num)
	}

	C.glGenTextures(1, &text_num) // generate 1 texture in text_id
	C.glBindTexture(C.GL_TEXTURE_2D, text_num)
	C.glTexEnvi(C.GL_TEXTURE_ENV, C.GL_TEXTURE_ENV_MODE, C.GL_MODULATE) // Texture blends with object background

	C.glTexImage2D(C.GL_TEXTURE_2D, 0, C.GL_RGBA, w, h, 0, C.GL_RGBA, C.GL_UNSIGNED_BYTE,
		&image[0])
	C.glTexParameteri(C.GL_TEXTURE_2D, C.GL_TEXTURE_MIN_FILTER, C.GL_LINEAR)
	C.glTexParameteri(C.GL_TEXTURE_2D, C.GL_TEXTURE_MAG_FILTER, C.GL_LINEAR)
}

fn set_texture(text_num int) {
	C.glEnable(C.GL_TEXTURE_2D)
	C.glBindTexture(C.GL_TEXTURE_2D, text_num)
}

fn enable_textures() {
	C.glEnable(C.GL_TEXTURE_2D)
}

fn disable_textures() {
	C.glDisable(C.GL_TEXTURE_2D)
}

// glfw

fn glfw_init() {
	if C.glfwInit() == 0 {
		panic("can't init glfw")
	}
}

fn create_window(w int, h int, title string) voidptr {
	win := C.glfwCreateWindow(w, h, title.str, unsafe { nil }, unsafe { nil })
	if win == unsafe { nil } {
		panic("can't create window")
	}
	return win
}

fn set_window_pos(window voidptr, x int, y int) {
	C.glfwSetWindowPos(window, x, y)
}

fn get_window_size(window voidptr) (int, int) {
	mut w := 0
	mut h := 0
	C.glfwGetWindowSize(window, &w, &h)
	return w, h
}

fn set_geo(window voidptr) {
	mut w := 0
	mut h := 0
	C.glfwGetWindowSize(window, &w, &h)

	C.glViewport(0, 0, w, h)
	C.glMatrixMode(C.GL_PROJECTION)
	C.glLoadIdentity()
	perspective_gl(45, f64(w) / f64(h), 0.1, 100)
	C.glMatrixMode(C.GL_MODELVIEW)
	C.glLoadIdentity()
}

fn init_render(window voidptr, bg_color []f32) {
	C.glClear(C.GL_COLOR_BUFFER_BIT | C.GL_DEPTH_BUFFER_BIT)
	C.glClearColor(bg_color[0], bg_color[1], bg_color[2], bg_color[3])

	set_geo(window)
}

pub enum KeyCodes {
	up        = C.GLFW_KEY_UP
	down      = C.GLFW_KEY_DOWN
	page_down = C.GLFW_KEY_PAGE_DOWN
	page_up   = C.GLFW_KEY_PAGE_UP
	space     = C.GLFW_KEY_SPACE
	r         = C.GLFW_KEY_R
	s         = C.GLFW_KEY_S
	m         = C.GLFW_KEY_M
	o         = C.GLFW_KEY_O
	left      = C.GLFW_KEY_LEFT
	right     = C.GLFW_KEY_RIGHT
	escape    = C.GLFW_KEY_ESCAPE
	n0        = C.GLFW_KEY_0
	n1        = C.GLFW_KEY_1
	n2        = C.GLFW_KEY_2
	n3        = C.GLFW_KEY_3
	n4        = C.GLFW_KEY_4
	n5        = C.GLFW_KEY_5
	n6        = C.GLFW_KEY_6
	n7        = C.GLFW_KEY_7
	n8        = C.GLFW_KEY_8
	n9        = C.GLFW_KEY_9
}

pub fn to_key_code(key int) KeyCodes {
	return unsafe { KeyCodes(key) }
}

pub fn mouse_pressed(button int, action int) bool {
	return button == C.GLFW_MOUSE_BUTTON_LEFT && action == C.GLFW_PRESS
}

pub fn mouse_released(button int, action int) bool {
	return button == C.GLFW_MOUSE_BUTTON_LEFT && action == C.GLFW_RELEASE
}
