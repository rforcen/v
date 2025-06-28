module noaa

// daily

struct Items {
	value [5]u8
	mflag u8
	qflag u8
	sflag u8
}

pub struct Daily {
	id      [11]u8
	year    [4]u8
	month   [2]u8
	element [4]u8
	items   [31]Items
mut:
	lf u8 // filler and used for all/any values
}

// getters / setters
fn (d Daily) get_station() Fstring {
	return fstring11(d.id)
}

fn (d Daily) get_country() Fstring {
	return fstring(d.id[0..2])
}

fn (d Daily) get_year() int {
	return year2int(d.year)
}

fn (d Daily) get_month() int {
	return month2int(d.month)
}

fn (d Daily) get_element() Fstring {
	return fstring4(d.element)
}

fn (d Daily) get_value(day int) int {
	return value2int(d.items[day].value)
}

pub fn (dly Daily) valid_value(d int) (bool, int) {
	v := dly.get_value(d)
	return v != -9999 && dly.items[d].qflag == ` `, v
}

pub fn (dly Daily) max_min_values() (bool, int, int) {
	mut max:=-max_int
	mut min:=max_int
	for i in 0..31 {
		ok, v := dly.valid_value(i)
		if ok {
			if v>max { max=v }
			if v<min { min=v }
		}
	}
	return max != -max_int && min != max_int, max, min
}

pub fn (dly Daily) avg_value() f64 {
	mut sum := 0.0
	mut n := 0
	for i in 0..31 {
		ok, v := dly.valid_value(i)
		if ok {
			sum += f64(v)
			n++
		}
	}
	return if n > 0 { sum / n } else { 0.0 }
}

fn new_daily(s string) Daily {
	mut daily := Daily{}
	unsafe { C.memcpy(&daily, s.str, sizeof(Daily)) }
	return daily
}

// daily observation, links to "ghcnd_all.tar.gz"
pub struct DailyObs {
pub mut:
	targz TarGz
	daily Daily

	uses_values bool
}

pub fn open_daily_obs() !DailyObs {
	file_path := daily_obs_file()

	tgz := open_targz(file_path) or { return error('daily.v: error opening file: ${file_path}') }
	mut do := DailyObs{
		targz: tgz
		daily: Daily{}
	}

	return do
}

pub fn new_daily_obs() DailyObs {
	return DailyObs{
		targz: new_targz()
	}
}

// convert raw data from a file in tar.gz to a Daily array
fn (mut do DailyObs) get_daily_array(data string) []Daily {
	sz_dr := int(sizeof(Daily))
	nrecs := data.len / sz_dr

	mut da := []Daily{len: nrecs}

	mut id := 0 // index in data chunks
	for i := 0; i < nrecs; i++ { // traverse in Daily chunks
		da[i] = new_daily(data[id..id + sz_dr])
		id += sz_dr
	}
	return da
}

pub fn (mut do DailyObs) next() ?[]Daily {
	for {
		if !do.targz.get_next() {
			return none
		}
		if do.targz.is_daily() {
			if !do.targz.read() {
				return none
			} else {
				break
			}
		}
	}
	// convert do.targz.buff string to []Daily
	return do.get_daily_array(do.targz.get_data())
}

pub fn (mut do DailyObs) close() {
	do.targz.close()
}

pub fn (mut do DailyObs) reset() {
	do.targz.reset()
	do.daily = Daily{}
}

///////////////////////////////

fn u8str(u []u8) string {
	return u.bytestr()
}

// fn u8int(u []u8) int    { return strconv.atoi(u.bytestr().trim(' ')) or { return -7777 } }
// fast dedicated to int converter
fn month2int(u [2]u8) int {
	return int(u[0] - 48) * 10 + (u[1] - 48)
}

fn year2int(u [4]u8) int {
	mut res := 0
	mut mlt := 1000

	for c in u {
		res += mlt * (c - 48)
		mlt /= 10
	}
	return res
}

fn value2int_user(u [5]u8) int {
	mut res := 0
	mut sign := 1
	for c in u {
		match c {
			`-` {
				sign = -1
			}
			`0`...`9` {
				res = res * 10 + (c - 48)
			}
			else {} // ignore
		}
	}
	return if sign == -1 { -res } else { res }
}

fn value2int(u [5]u8) int {
	mut res := 0
	mut sign := 1
	for c in u {
		if c >= 48 && c <= 57 { // ASCII 48-57 = '0'-'9'
			res = res * 10 + int(c - 48)
		} else if c == 45 { // ASCII 45 = '-'
			sign = -1
		}
	}
	return res * sign
}

fn (d Daily) print() {
	println('id     :${d.id[..].bytestr()}')
	println('year   :${d.year[..].bytestr()}')
	println('month  :${d.month[..].bytestr()}')
	println('element:${d.element[..].bytestr()}')

	print('values : (')
	for ix, i in d.items {
		print('${value2int(i.value)}')
		print('[${i.mflag.ascii_str()}${i.qflag.ascii_str()}${i.sflag.ascii_str()}]${if ix < 30 {
			', '
		} else {
			''
		}}')
	}
	println(')')
}
