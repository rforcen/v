// glfw3 & opengl minimal wrapper for this app
//
module sh

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

fn set_perspective(fovy f64, aspect f64, z_near f64, z_far f64) {
	ymax := z_near * tan(fovy * math.pi / 360.0)
	ymin := -ymax
	xmin := ymin * aspect
	xmax := ymax * aspect

	C.glFrustum(xmin, xmax, ymin, ymax, z_near, z_far)
}

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

fn init_render(window voidptr, bg_color []f32) {
	mut w := 0
	mut h := 0
	C.glfwGetWindowSize(window, &w, &h)
	C.glClear(C.GL_COLOR_BUFFER_BIT | C.GL_DEPTH_BUFFER_BIT)
	C.glClearColor(bg_color[0], bg_color[1], bg_color[2], bg_color[3])

	C.glMatrixMode(C.GL_PROJECTION)
	C.glLoadIdentity()
	// set_perspective(45.0, f64(w) / f64(h), 0.1, 100.0)
	set_perspective(45.0, 1.0, 1.0, 100.0)

	C.glMatrixMode(C.GL_MODELVIEW)
	C.glLoadIdentity()
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
