// variable type support

module noaa

// VarType
pub enum VarDataType {
	dt_float
	dt_fstring
	dt_bool
	dt_daily
}

pub struct VarType {
pub mut:
	// not a sum type as i want direct access to fields without creating a new instance
	f  Float
	fs Fstring
	b  bool
	d  Daily

	tp VarDataType
}

pub fn new_vt_fstring(fs &Fstring) VarType {
	return VarType{
		fs: fs
		tp: VarDataType.dt_fstring
	}
}

// setters / getters
pub fn (mut vt VarType) set_fs(v &Fstring) {
	vt.fs.set(v)
	vt.tp = VarDataType.dt_fstring
}

pub fn (mut vt VarType) set_f(v Float) {
	vt.f = v
	vt.tp = VarDataType.dt_float
}

pub fn (mut vt VarType) set_bool(v bool) {
	vt.b = v
	vt.tp = VarDataType.dt_bool
}

pub fn (mut vt VarType) set_daily(v &Daily) {
	vt.d = *v
	vt.tp = VarDataType.dt_daily
}

pub fn (vt VarType) get_fs() &Fstring {
	return &vt.fs
}

pub fn (vt VarType) get_f() Float {
	return vt.f
}

pub fn (vt VarType) get_bool() bool {
	return vt.b
}

pub fn (vt VarType) get_daily() &Daily {
	return &vt.d
}

// cmp
pub fn (vt VarType) eq(vt1 &VarType) bool {
	match vt.tp {
		.dt_float {
			return vt.f == vt1.f
		}
		.dt_fstring {
			return vt.fs.eq(vt1.fs)
		}
		.dt_bool {
			return vt.b == vt1.b
		}
		else {
			return false
		}
	}
	return false
}

pub fn (vt VarType) ne(vt1 &VarType) bool {
	return !vt.eq(vt1)
}

pub fn (vt VarType) gt(vt1 &VarType) bool {
	match vt.tp {
		.dt_float {
			return vt.f > vt1.f
		}
		.dt_fstring {
			return vt.fs.gt(vt1.fs)
		}
		else {
			return false
		}
	}
	return false
}

pub fn (vt VarType) ge(vt1 &VarType) bool {
	match vt.tp {
		.dt_float {
			return vt.f >= vt1.f
		}
		.dt_fstring {
			return vt.fs.ge(vt1.fs)
		}
		else {
			return false
		}
	}
	return false
}

pub fn (vt VarType) lt(vt1 &VarType) bool {
	return !vt.ge(vt1)
}

pub fn (vt VarType) le(vt1 &VarType) bool {
	return !vt.gt(vt1)
}
