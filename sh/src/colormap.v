// color map fn 
module sh

pub const max_color_map = 25

pub fn color_map(v_ f64, vmin_ f64, vmax_ f64, type_ int) Color {
	mut v := v_
	mut vmin := vmin_
	mut vmax := vmax_

	mut dv := f64(0.0)
	mut vmid := f64(0.0)

	mut c := Color{
		r: 1
		g: 1
		b: 1
	}

	mut c1 := Color{}
	mut c2 := Color{}
	mut c3 := Color{}

	mut ratio := f64(0.0)
	if vmax < vmin {
		dv = vmin
		vmin = vmax
		vmax = dv
	}
	if vmax - vmin < 9.99999997E-7 {
		vmin -= f64(1)
		vmax += f64(1)
	}
	if v < vmin {
		v = vmin
	}
	if v > vmax {
		v = vmax
	}
	dv = vmax - vmin
	match type_ {
		1 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + 0.25 * dv) {
				c.r = f64(0)
				c.g = f64(4) * (v - vmin) / dv
				c.b = f64(1)
			} else if v < (vmin + 0.5 * dv) {
				c.r = f64(0)
				c.g = f64(1)
				c.b = f64(1) + f64(4) * (vmin + 0.25 * dv - v) / dv
			} else if v < (vmin + 0.75 * dv) {
				c.r = f64(4) * (v - vmin - 0.5 * dv) / dv
				c.g = f64(1)
				c.b = f64(0)
			} else {
				c.r = f64(1)
				c.g = f64(1) + f64(4) * (vmin + 0.75 * dv - v) / dv
				c.b = f64(0)
			}
		}
		2 { // case comp body kind=BinaryOperator is_enum=false
			c.r = (v - vmin) / dv
			c.g = f64(0)
			c.b = (vmax - v) / dv
		}
		3 { // case comp body kind=BinaryOperator is_enum=false
			c.r = (v - vmin) / dv
			c.b = c.r
			c.g = c.r
		}
		4 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + dv / f64(6)) {
				c.r = f64(1)
				c.g = f64(6) * (v - vmin) / dv
				c.b = f64(0)
			} else if v < (vmin + f64(2) * dv / f64(6)) {
				c.r = f64(1) + f64(6) * (vmin + dv / f64(6) - v) / dv
				c.g = f64(1)
				c.b = f64(0)
			} else if v < (vmin + f64(3) * dv / f64(6)) {
				c.r = f64(0)
				c.g = f64(1)
				c.b = f64(6) * (v - vmin - f64(2) * dv / f64(6)) / dv
			} else if v < (vmin + f64(4) * dv / f64(6)) {
				c.r = f64(0)
				c.g = f64(1) + f64(6) * (vmin + f64(3) * dv / f64(6) - v) / dv
				c.b = f64(1)
			} else if v < (vmin + f64(5) * dv / f64(6)) {
				c.r = f64(6) * (v - vmin - f64(4) * dv / f64(6)) / dv
				c.g = f64(0)
				c.b = f64(1)
			} else {
				c.r = f64(1)
				c.g = f64(0)
				c.b = f64(1) + f64(6) * (vmin + f64(5) * dv / f64(6) - v) / dv
			}
		}
		5 { // case comp body kind=BinaryOperator is_enum=false
			c.r = (v - vmin) / (vmax - vmin)
			c.g = f64(1)
			c.b = f64(0)
		}
		6 { // case comp body kind=BinaryOperator is_enum=false
			c.r = (v - vmin) / (vmax - vmin)
			c.g = (vmax - v) / (vmax - vmin)
			c.b = c.r
		}
		7 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + 0.25 * dv) {
				c.r = f64(0)
				c.g = f64(4) * (v - vmin) / dv
				c.b = f64(1) - c.g
			} else if v < (vmin + 0.5 * dv) {
				c.r = f64(4) * (v - vmin - 0.25 * dv) / dv
				c.g = f64(1) - c.r
				c.b = f64(0)
			} else if v < (vmin + 0.75 * dv) {
				c.g = f64(4) * (v - vmin - 0.5 * dv) / dv
				c.r = f64(1) - c.g
				c.b = f64(0)
			} else {
				c.r = f64(0)
				c.b = f64(4) * (v - vmin - 0.75 * dv) / dv
				c.g = f64(1) - c.b
			}
		}
		8 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + 0.5 * dv) {
				c.r = f64(2) * (v - vmin) / dv
				c.g = c.r
				c.b = c.r
			} else {
				c.r = f64(1) - f64(2) * (v - vmin - 0.5 * dv) / dv
				c.g = c.r
				c.b = c.r
			}
		}
		9 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + dv / f64(3)) {
				c.b = f64(3) * (v - vmin) / dv
				c.g = f64(0)
				c.r = f64(1) - c.b
			} else if v < (vmin + f64(2) * dv / f64(3)) {
				c.r = f64(0)
				c.g = f64(3) * (v - vmin - dv / f64(3)) / dv
				c.b = f64(1)
			} else {
				c.r = f64(3) * (v - vmin - f64(2) * dv / f64(3)) / dv
				c.g = f64(1) - c.r
				c.b = f64(1)
			}
		}
		10 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + 0.200000003 * dv) {
				c.r = f64(0)
				c.g = f64(5) * (v - vmin) / dv
				c.b = f64(1)
			} else if v < (vmin + 0.400000006 * dv) {
				c.r = f64(0)
				c.g = f64(1)
				c.b = f64(1) + f64(5) * (vmin + 0.200000003 * dv - v) / dv
			} else if v < (vmin + 0.600000024 * dv) {
				c.r = f64(5) * (v - vmin - 0.400000006 * dv) / dv
				c.g = f64(1)
				c.b = f64(0)
			} else if v < (vmin + 0.800000011 * dv) {
				c.r = f64(1)
				c.g = f64(1) - f64(5) * (v - vmin - 0.600000024 * dv) / dv
				c.b = f64(0)
			} else {
				c.r = f64(1)
				c.g = f64(5) * (v - vmin - 0.800000011 * dv) / dv
				c.b = f64(5) * (v - vmin - 0.800000011 * dv) / dv
			}
		}
		11 { // case comp body kind=BinaryOperator is_enum=false
			c1.r = 200 / 255
			c1.g = 60 / 255
			c1.b = 0 / 255
			c2.r = 250 / 255
			c2.g = 160 / 255
			c2.b = 110 / 255
			c.r = (c2.r - c1.r) * (v - vmin) / dv + c1.r
			c.g = (c2.g - c1.g) * (v - vmin) / dv + c1.g
			c.b = (c2.b - c1.b) * (v - vmin) / dv + c1.b
		}
		12 { // case comp body kind=BinaryOperator is_enum=false
			c1.r = 55 / 255
			c1.g = 55 / 255
			c1.b = 45 / 255
			// c2.r = 200 / 255; c2.g =  60 / 255; c2.b =   0 / 255;
			c2.r = 235 / 255
			c2.g = 90 / 255
			c2.b = 30 / 255
			c3.r = 250 / 255
			c3.g = 160 / 255
			c3.b = 110 / 255
			ratio = 0.400000006
			vmid = vmin + ratio * dv
			if v < vmid {
				c.r = (c2.r - c1.r) * (v - vmin) / (ratio * dv) + c1.r
				c.g = (c2.g - c1.g) * (v - vmin) / (ratio * dv) + c1.g
				c.b = (c2.b - c1.b) * (v - vmin) / (ratio * dv) + c1.b
			} else {
				c.r = (c3.r - c2.r) * (v - vmid) / ((f64(1) - ratio) * dv) + c2.r
				c.g = (c3.g - c2.g) * (v - vmid) / ((f64(1) - ratio) * dv) + c2.g
				c.b = (c3.b - c2.b) * (v - vmid) / ((f64(1) - ratio) * dv) + c2.b
			}
		}
		13 { // case comp body kind=BinaryOperator is_enum=false
			c1.r = 0 / 255
			c1.g = 255 / 255
			c1.b = 0 / 255
			c2.r = 255 / 255
			c2.g = 150 / 255
			c2.b = 0 / 255
			c3.r = 255 / 255
			c3.g = 250 / 255
			c3.b = 240 / 255
			ratio = 0.300000012
			vmid = vmin + ratio * dv
			if v < vmid {
				c.r = (c2.r - c1.r) * (v - vmin) / (ratio * dv) + c1.r
				c.g = (c2.g - c1.g) * (v - vmin) / (ratio * dv) + c1.g
				c.b = (c2.b - c1.b) * (v - vmin) / (ratio * dv) + c1.b
			} else {
				c.r = (c3.r - c2.r) * (v - vmid) / ((f64(1) - ratio) * dv) + c2.r
				c.g = (c3.g - c2.g) * (v - vmid) / ((f64(1) - ratio) * dv) + c2.g
				c.b = (c3.b - c2.b) * (v - vmid) / ((f64(1) - ratio) * dv) + c2.b
			}
		}
		14 { // case comp body kind=BinaryOperator is_enum=false
			c.r = f64(1)
			c.g = f64(1) - (v - vmin) / dv
			c.b = f64(0)
		}
		15 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + 0.25 * dv) {
				c.r = f64(0)
				c.g = f64(4) * (v - vmin) / dv
				c.b = f64(1)
			} else if v < (vmin + 0.5 * dv) {
				c.r = f64(0)
				c.g = f64(1)
				c.b = f64(1) - f64(4) * (v - vmin - 0.25 * dv) / dv
			} else if v < (vmin + 0.75 * dv) {
				c.r = f64(4) * (v - vmin - 0.5 * dv) / dv
				c.g = f64(1)
				c.b = f64(0)
			} else {
				c.r = f64(1)
				c.g = f64(1)
				c.b = f64(4) * (v - vmin - 0.75 * dv) / dv
			}
		}
		16 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + 0.5 * dv) {
				c.r = 0.0
				c.g = f64(2) * (v - vmin) / dv
				c.b = f64(1) - f64(2) * (v - vmin) / dv
			} else {
				c.r = f64(2) * (v - vmin - 0.5 * dv) / dv
				c.g = f64(1) - f64(2) * (v - vmin - 0.5 * dv) / dv
				c.b = 0.0
			}
		}
		17 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + 0.5 * dv) {
				c.r = 1
				c.g = f64(1) - f64(2) * (v - vmin) / dv
				c.b = f64(2) * (v - vmin) / dv
			} else {
				c.r = f64(1) - f64(2) * (v - vmin - 0.5 * dv) / dv
				c.g = f64(2) * (v - vmin - 0.5 * dv) / dv
				c.b = 1
			}
		}
		18 { // case comp body kind=BinaryOperator is_enum=false
			c.r = f64(0)
			c.g = (v - vmin) / (vmax - vmin)
			c.b = f64(1)
		}
		19 { // case comp body kind=BinaryOperator is_enum=false
			c.r = (v - vmin) / (vmax - vmin)
			c.g = c.r
			c.b = f64(1)
		}
		20 { // case comp body kind=BinaryOperator is_enum=false
			c1.r = 0 / 255
			c1.g = 160 / 255
			c1.b = 0 / 255
			c2.r = 180 / 255
			c2.g = 220 / 255
			c2.b = 0 / 255
			c3.r = 250 / 255
			c3.g = 220 / 255
			c3.b = 170 / 255
			ratio = 0.300000012
			vmid = vmin + ratio * dv
			if v < vmid {
				c.r = (c2.r - c1.r) * (v - vmin) / (ratio * dv) + c1.r
				c.g = (c2.g - c1.g) * (v - vmin) / (ratio * dv) + c1.g
				c.b = (c2.b - c1.b) * (v - vmin) / (ratio * dv) + c1.b
			} else {
				c.r = (c3.r - c2.r) * (v - vmid) / ((f64(1) - ratio) * dv) + c2.r
				c.g = (c3.g - c2.g) * (v - vmid) / ((f64(1) - ratio) * dv) + c2.g
				c.b = (c3.b - c2.b) * (v - vmid) / ((f64(1) - ratio) * dv) + c2.b
			}
		}
		21 { // case comp body kind=BinaryOperator is_enum=false
			c1.r = 255 / 255
			c1.g = 255 / 255
			c1.b = 200 / 255
			c2.r = 150 / 255
			c2.g = 150 / 255
			c2.b = 255 / 255
			c.r = (c2.r - c1.r) * (v - vmin) / dv + c1.r
			c.g = (c2.g - c1.g) * (v - vmin) / dv + c1.g
			c.b = (c2.b - c1.b) * (v - vmin) / dv + c1.b
		}
		22 { // case comp body kind=BinaryOperator is_enum=false
			c.r = f64(1) - (v - vmin) / dv
			c.g = f64(1) - (v - vmin) / dv
			c.b = (v - vmin) / dv
		}
		23 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + 0.5 * dv) {
				c.r = f64(1)
				c.g = f64(2) * (v - vmin) / dv
				c.b = c.g
			} else {
				c.r = f64(1) - f64(2) * (v - vmin - 0.5 * dv) / dv
				c.g = c.r
				c.b = f64(1)
			}
		}
		24 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + 0.5 * dv) {
				c.r = f64(2) * (v - vmin) / dv
				c.g = c.r
				c.b = f64(1) - c.r
			} else {
				c.r = f64(1)
				c.g = f64(1) - f64(2) * (v - vmin - 0.5 * dv) / dv
				c.b = f64(0)
			}
		}
		25 { // case comp body kind=IfStmt is_enum=false
			if v < (vmin + dv / f64(3)) {
				c.r = f64(0)
				c.g = f64(3) * (v - vmin) / dv
				c.b = f64(1)
			} else if v < (vmin + f64(2) * dv / f64(3)) {
				c.r = f64(3) * (v - vmin - dv / f64(3)) / dv
				c.g = f64(1) - c.r
				c.b = f64(1)
			} else {
				c.r = f64(1)
				c.g = f64(0)
				c.b = f64(1) - f64(3) * (v - vmin - f64(2) * dv / f64(3)) / dv
			}
		}
		else {}
	}
	return c
}
