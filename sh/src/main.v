module main

import sh
import os
import time { now }

fn bench() {
	//lap1: 1.426s
	//lap2: 229.825ms, removing check_faces_trigs() & generate_trigs()
	n := 1024
	println('running sh on ${n}x${n}')
	t0 := now()
	_ := sh.new_sh(n, 7, 0)
	println('lap res:${n}: ${now() - t0}')
}

fn ui_obj() {
	if os.args.len > 1 {
		mut sh_ := sh.new_sh(256, 7, os.args[1].int())
		sh_.write_obj() or { println(err) }
	} else {
		sh.ui_glfw()
	}
}

fn main() {
	ui_obj()
}
