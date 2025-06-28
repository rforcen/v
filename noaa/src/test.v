/*
compile a generated "v -o file.c file.v"

    gcc -I/home/asd/Downloads/v/thirdparty/libgc/include -Inoaa -w -O3 test_noaa.c -o test_noaa -larchive -L/home/asd/Downloads/v/thirdparty/tcc/lib/ -lgc

mt versions of cp.evaluate are slower than st as it uses dynamic mem. objects as strings

*/

module noaa

import os
import time { now }
import runtime
// import sync

// daily
pub fn test_daily(n int) {
	file_path := daily_obs_file()

	mut t := open_targz(file_path) or {
		println('error opening file: ${file_path}')
		return
	}
	mut nc := 0
	mut nfiles := 0

	t0 := now()

	for i, t_ in t {
		if i >= n {
			break
		}
		if i % 1000 == 0 {
			regs := t_.get_lines()
			eprint('${i:06} : ${nc:6} ${t_.get_file_name()}  ${t_.get_file_size():9}, data: ${regs[0][..70]}\r')
		}
		daily := new_daily(t_.buff)
		if daily.get_year() >= 1950 {
			nc++
		}
		nfiles = i
	}
	eprintln('\ndone, lap:${now() - t0} ${nfiles:06} files read, >=1950 : ${nc}')

	t.close()
}

/////////////////////////////

pub fn test_targz_org(n int) {
	file_path := daily_obs_file()

	mut t := open_targz(file_path) or {
		println('error opening file: ${file_path}')
		return
	}
	for t.get_next() && t.file_idx < n {
		if t.is_daily() {
			if t.read() {
				if t.file_idx % 1000 == 0 {
					// regs := t.get_data()
					eprint('${t.file_idx:06}, ${t.fname}, ${t.file_size:9} ${t.file_type:6x}, ${t.buff[..50]}\r')
				}
			}
		}
	}
	eprintln('\ndone, ${t.file_idx} files read')

	t.close()
}

pub fn test_targz(n int) {
	file_path := daily_obs_file()

	mut t_ := open_targz(file_path) or {
		println('error opening file: ${file_path}')
		return
	}
	for i, t in t_ {
		if i % 1000 == 0 {
			eprint('** ${i:06}, ${t.fname}, ${t.file_size:9} ${t.file_type:6x}, ${t.buff[..50]}\r')
		}
		t_.file_idx = i
	}
	eprintln('\ndone, ${t_.file_idx} files read')

	t_.close()
}

////////////////////////////
fn test_targz_all() {
	file_path := daily_obs_file() // Replace with your tar.gz file
	println('reading file: ${file_path}')

	if !os.exists(file_path) {
		eprintln('file ${file_path} not available')
		return
	}

	// Open the archive
	archive := C.archive_read_new()
	unsafe {
		if archive == nil {
			eprintln('Error: Failed to create archive read object.')
			return
		}
	}
	C.archive_read_support_filter_all(archive) // Enable all supported decompression filters
	C.archive_read_support_format_tar(archive) // Enable TAR format

	if C.archive_read_open_filename(archive, file_path.str, 1024 * 10) == archive_ok {
		// Read the archive entries
		entry := C.archive_entry_new()

		mut fix := 0
		for C.archive_read_next_header(archive, &entry) != archive_eof {
			// Get information about the entry
			fn_ptr := C.archive_entry_pathname(entry)

			file_size := C.archive_entry_size(entry)
			file_type := C.archive_entry_filetype(entry)
			file_name := unsafe { fn_ptr.vstring() } // convert &char to string

			if fix % 1000 == 0 {
				eprint('${fix:05}:${file_name:27}, Size: ${file_size:7}, Type: oct${file_type:7o}')
			}

			//  read the data
			if file_type == ae_ifreg && file_name.contains('.dly') { // Regular daily file

				buffer := []u8{len: file_size} // read buffer
				buff_addr := &buffer[0]

				mut read_len := C.archive_read_data(archive, buff_addr, file_size)
				read_len = read_len

				if fix % 1000 == 0 {
					daily_content := buffer.bytestr() // convert []u8 -> string
					lines := daily_content.split('\n')
					eprint(', data:${lines[0][..60]}\r')
				}
			} else {
				eprintln(', no daily file, skipped')
			}

			C.archive_entry_clear(entry) // Clear entry for the next iteration		

			fix++
		}
		C.archive_entry_free(entry)

		// // 4. Close the archive
		C.archive_read_close(archive)
		println('\ndone, read ${fix} files')
	} else {
		eprintln('Error: Could not open archive: ${archive_error_string(archive)}')
		C.archive_read_free(archive)
	}
}

// Helper function to get error string
fn archive_error_string(archive &C.archive) string {
	unsafe {
		return C.archive_error_string(archive).vstring()
	}
}

fn test_read_all() {
	test_read_aux(5)
	test_targz(100)
}

fn daily_trv() {
	println('noaa daily traverse')

	n := 40
	t0 := now()
	test_daily(n)
	println('${n} items lap: ${now() - t0}')
}

fn ndb() {
	println('loding aux files...')
	// db := noaa.create_db()
	// println(db.countries)
	// println(db.states)
	// println(db.elements)
	// noaa.print_stations(db.stations,3)
	test_daily(3000)
}

pub fn test_read_aux(n int) {
	aux_files := read_all_aux()

	print_aux_map(aux_files[countries_name], n)
	print_aux_map(aux_files[states_name], n)
	print_aux_map(aux_files[elements_name], n)
	print_aux_map(aux_files[stations_name], n)

	inventory := read_inventory()
	print_aux_arr(inventory, n)
}

// traverse daily obs tar.gz file
pub fn test_daily_obs(n int) {
	mut daily_obs := open_daily_obs() or {
		eprintln('error creating daily obs ')
		return
	}

	// traverse daily obs
	t0 := now()
	for i, recs in daily_obs {
		if i == n {
			break
		}

		if i % 1000 == 0 {
			eprint('${i:6} : ${recs[0].get_station()} ${recs[0].get_year()} ${recs[0].get_month()} ${recs[0].get_element()}\r')
		}

		for j, daily in recs { // traverse array of daily recs	
			if j == n {
				if daily.get_year() > n + 6000 {
					eprint('${i:6} : ${daily.id} ${daily.year} ${daily.month} ${daily.element}\r')
				}
			}
		}
	}
	eprintln('\nlap for ${n} files: ${now() - t0}')
	daily_obs.close()
}

pub fn test_daily_obs_raw(n int) { // 1.77
	println('test_daily_obs_raw')
	mut daily_obs := open_daily_obs() or {
		eprintln('error creating daily obs ')
		return
	}

	// traverse daily obs
	t0 := now()
	for i, recs in daily_obs {
		if i == n {
			break
		}

		if i % 1000 == 0 {
			eprint('${i:6} : ${recs[0].get_station()} ${recs[0].get_year()} ${recs[0].get_month()} ${recs[0].get_element()}\r')
		}
	}
	eprintln('\nlap for ${n} files: ${now() - t0}')
	daily_obs.close()
}

pub fn test_daily_obs_daily_array(n int) { // 2.32
	println('test_daily_obs_daily_array')
	mut daily_obs := open_daily_obs() or {
		eprintln('error creating daily obs ')
		return
	}
	mut dailies := []Daily{}
	// traverse daily obs
	t0 := now()
	for i, recs in daily_obs {
		if i == n {
			break
		}
		dailies << recs
		if dailies.len > 30000 {
			dailies = []Daily{}
		}
		if i % 1000 == 0 {
			eprint('${i:6} : ${recs[0].get_station()} ${recs[0].get_year()} ${recs[0].get_month()} ${recs[0].get_element()}\r')
		}
	}
	eprintln('\nlap for ${n} files: ${now() - t0}')
	daily_obs.close()
}

const daily_cap = 30000

pub fn test_daily_obs_daily_array_cp(n int) { //
	println('test_daily_obs_daily_array_cp')
	mut db := create_db()
	mut dailies := []Daily{cap: daily_cap}
	mut daily_obs := open_daily_obs() or {
		eprintln('error creating daily obs ')
		return
	}
	expr := "country='US' and year=2024 and month>6 and month<9 and element='TMAX'"
	mut cp := compile(expr)
	if !cp.ok() {
		eprintln('error compiling expression: ${expr}')
		return
	}

	// traverse daily obs
	mut nrecs := 0
	mut eval_found := 0
	t0 := now()
	for i, recs in daily_obs {
		if i > n {
			break
		}
		nrecs += recs.len

		if cp.uses_station { // load station if required, once per file
			db.load_station(recs[0])
		}
		dailies << recs
		if dailies.len > daily_cap {
			for r in dailies {
				db.daily = r
				if cp.evaluate(mut db) {
					eval_found++
				}
			}
			dailies = []Daily{cap: daily_cap}
		}

		if i % 1000 == 0 {
			eprint('${i:6}/${nrecs} : ${recs[0].get_station()} ${recs[0].get_year()} ${recs[0].get_month()} ${recs[0].get_element()}\r')
		}
	}
	for r in dailies {
		db.daily = r
		if cp.evaluate(mut db) {
			eval_found++
		}
	}
	dailies = []Daily{}

	eprintln('\nlap for ${n} files/${nrecs} recs.: ${now() - t0}, found ${eval_found} recs.')
	daily_obs.close()
}

pub fn test_cp_st(n int) { //
	println('test_cp_st')
	mut db := create_db()
	mut daily_obs := open_daily_obs() or {
		eprintln('error creating daily obs ')
		return
	}
	expr := "country='US' and year=2024 and month>6 and month<9 and element='TMAX'"
	mut cp := compile(expr)
	if !cp.ok() {
		eprintln('error compiling expression: ${expr}')
		return
	}

	// traverse daily obs

	t0 := now()
	for _ in 0 .. n {
		cp.evaluate(mut db)
	}

	eprintln('\nlap for ${n} : ${now() - t0}')
	daily_obs.close()
}

pub fn test_cp_mt(n int) { // when using dynamic mem. objects as strings mt is slower than st
	println('test_cp_mt')
	mut db := create_db()
	mut daily_obs := open_daily_obs() or {
		eprintln('error creating daily obs ')
		return
	}
	expr := "country='US' and year=2024 and month>6 and month<9 and element='TMAX'"
	mut cp := compile(expr)
	if !cp.ok() {
		eprintln('error compiling expression: ${expr}')
		return
	}

	n_threads := runtime.nr_cpus()
	chunk_size := n / n_threads
	println('threads: ${n_threads}, chunk_size: ${chunk_size}, n: ${n}')

	t0 := now()

	mut threads := []thread int{cap: n_threads}
	for th in 0 .. n_threads {
		threads << spawn fn [mut cp, mut db] (th int, chunk_size int) int {
			for _ in 0 .. chunk_size {
				cp.evaluate(mut db) // uses dynamic mem. objects as strings -> slower than st
			}
			return chunk_size
		}(th, chunk_size)
	}
	nevals := threads.wait()

	eprintln('\nlap for ${n} : ${now() - t0}, nevals: ${sum(nevals)}')
	daily_obs.close()
}

// sequence of performance test
pub fn test_perf_daily_obs() {
	test_daily_obs_raw(3000)
	test_daily_obs_daily_array(3000)
	test_daily_obs_daily_array_cp(3000)
}

// compiler test
fn cp_test(expr string) {
	println('compiler test for:${expr}')
	mut cp := compile(expr)
	println('compiler result: ${cp.ok()}, msg:"${cp.err_message}"')
	println('code: ${cp.code}')
	for c in cp.code {
		unsafe { println('${Token(c)} (${c})') }
	}
	cp = cp
}

fn cp_eval_test_st(mut db Noaa_db, n int, expr string) {
	println('ST - evaluating: ${expr}')

	db.cp = compile(expr)

	if db.cp.ok() {
		mut eval_found := 0
		mut nrecs := 0

		println('syntax ok, uses_values:${db.cp.uses_values}, uses_station: ${db.cp.uses_station}')

		db.daily_obs.uses_values = db.cp.uses_values

		for i, recs in db.daily_obs { // traverse daily obs

			nrecs += recs.len

			if i % 1000 == 0 || i == n {
				eprint('${i:6}/${nrecs} : (${eval_found}) ${recs[0].get_station()} ${recs[0].get_year()} ${recs[0].get_month()} ${recs[0].get_element()}\r')
			}
			if i == n {
				break
			}

			db.load_station_ifrequired(recs[0])

			for daily in recs { // traverse array of daily recs			
				db.set_daily(&daily)

				if db.cp.evaluate(mut db) {
					eval_found++
				}
			}
		}

		println('\nevaluated: ${nrecs}, found ${eval_found} recs.')
	} else {
		eprintln('syntax error in ${expr}\n${db.cp.get_err_msg()}')
	}
}

fn sum(arr []int) int {
	mut total := 0
	for item in arr {
		total += item
	}
	return total
}

fn process_daily_chunk(mut cps []Compiler, mut recs []Daily, mut dbs []Noaa_db, mut eval_found []int, th int, from int, to int) {
	mut current_station := Fstring{}

	if cps[th].uses_station {
		dbs[th].load_station(recs[0])
		current_station = recs[0].get_station()
	}

	for i in from .. to {
		dbs[th].daily = recs[i]
		if cps[th].uses_station && recs[i].get_station() != current_station {
			dbs[th].load_station(recs[i])
			current_station = recs[i].get_station()
		}

		if cps[th].evaluate(mut dbs[th]) {
			eval_found[th]++
		}
	}
}

fn cp_eval_test_mt(mut db Noaa_db, n int, expr string) {
	n_threads := runtime.nr_cpus()
	println('MT - evaluating: ${expr}, using ${n_threads} threads')
	ncap := 400000

	db.cp = compile(expr)

	if db.cp.ok() {
		print('syntax ok')

		db.set_mt(n_threads)
		mut dailies := []Daily{cap: ncap}

		mut eval_found := []int{len: n_threads, init: 0}
		mut real_found := []int{len: n_threads, init: 0}
		mut nrecs := []int{len: n_threads, init: 0}

		for i, recs in db.daily_obs { // traverse daily obs

			if i % 1000 == 0 || i == n {
				eprint('${i:6} : (${sum(eval_found)}/${sum(real_found)}) ${recs[0].get_station()} ${recs[0].get_year()} ${recs[0].get_month()} ${recs[0].get_element()}\r')
			}
			if i == n {
				break
			}

			dailies << recs // append recs

			if dailies.len > ncap { // thread'em		
				// eprintln('\nthreading ${dailies.len} files')		
				mut threads := []thread{cap: n_threads}
				chunk_size := dailies.len / n_threads
				nrecs[0] += dailies.len

				for th in 0 .. n_threads {
					threads << spawn process_daily_chunk(mut db.cps, mut dailies, mut
						db.dbs, mut eval_found, th, th * chunk_size, (if th == n_threads - 1 {
						dailies.len
					} else {
						(th + 1) * chunk_size
					}))
				}
				threads.wait()

				dailies = []Daily{cap: ncap}
			}
		}

		// pending dailies
		process_daily_chunk(mut db.cps, mut dailies, mut db.dbs, mut eval_found, 0, 0,
			dailies.len)
		nrecs[0] += dailies.len

		println('\nresult: evaluated: ${sum(nrecs)}, found ${sum(eval_found)}')
	} else {
		eprintln('syntax error in ${expr}\n${db.cp.get_err_msg()}')
	}
}

fn basic_compiler_test() {
	cp_test('+')
	cp_test("'asdb' 345..345  'dfgdfgfdg'  and or not any all value values in abs   id year month element latitude longitude elevation state")
	cp_test('123 345.56 34e45')
	cp_test('&+-*/<>=!(),and')
}

fn check_db(db Noaa_db) bool {
	return db.daily.get_year() in 2000..2010 + 1 && db.daily.get_month() > 3
}

pub fn compiler_test_perf() { // in -prod mode st is faster, possibly due cache overrun
	mut db := create_db()
	db.daily_obs = open_daily_obs() or {
		eprintln('error creating daily obs ')
		return
	}

	n := 6000
	mut expr := 'year in (2000, 2010) and elevation>1500'
	expr = "country='US' and year in(2000, 2001) and month in (6,8) and element='TMAX'"
	expr = "country='US' and year=2024 and month>6 and month<9 and element='TMAX'"

	mut t0 := now()
	// st
	cp_eval_test_st(mut db, n, expr)
	println('lap ST:${now() - t0}')
	db.reset()

	// mt -threads
	t0 = now()
	cp_eval_test_mt(mut db, n, expr)
	println('lap MT:${now() - t0}')

	db.close()
}

pub fn test_var_type() {
	mut a := VarType{}
	a.set_f(Float(0.0))
	a.set_daily(&Daily{})

	println(a)
}
