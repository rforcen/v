/*
	tailored searchs
*/

module noaa

import os
import math

// most expreme station tmax, tmin diff -> polar stations

struct StationStat {
mut:
	station Fstring
	tmax    int
	tmin    int
	tdiff   int
}

struct StationMostExtreme {
	ns    int
	tmaxs Fstring
	tmins Fstring
mut:
	db      &Noaa_db
	st_stat []StationStat
}

fn new_st_most_extr(ns int, db &Noaa_db) StationMostExtreme {
	unsafe {
		return StationMostExtreme{
			ns:      ns
			st_stat: []StationStat{cap: ns}
			tmaxs:   fstr('TMAX')
			tmins:   fstr('TMIN')
			db:      db
		}
	}
}

fn new_station_stat(min int, max int, daily &Daily) StationStat {
	return StationStat{
		station: daily.get_station()
		tmax:    max
		tmin:    min
		tdiff:   max - min
	}
}

fn (mut st_most StationMostExtreme) is_element(element &Fstring) bool {
	return element.eq(st_most.tmaxs) || element.eq(st_most.tmins) // is tmax or tmin
}

fn (mut st_most StationMostExtreme) process_daily(daily &Daily) {
	if st_most.is_element(daily.get_element()) {
		ok, max, min := daily.max_min_values()

		if ok {
			for mut s in st_most.st_stat {
				if s.tdiff < max - min { // greater diff?
					s = new_station_stat(min, max, daily)
					return
				}
			}
			if st_most.st_stat.len < st_most.ns {
				st_most.st_stat << new_station_stat(min, max, daily)
			}
		}
	}
}

fn (mut st_most StationMostExtreme) sort() {
	st_most.st_stat.sort_with_compare(fn (a &StationStat, b &StationStat) int {
		return -(a.tdiff) + (b.tdiff)
	})
}

fn (mut st_most StationMostExtreme) print() {
	sep := '+--+-----------+------------------------+------------------------+----+----+----+'
	println(sep)
	println('  #     station                     name                 country   max  min  dif')
	println(sep)
	for i, s in st_most.st_stat {
		id := s.station.str()
		country := id[0..2]
		eprintln('|${i + 1:02}|${id:11}|${st_most.db.stations[id].name:24}|${st_most.db.countries[country]:24}|${s.tmax:4}|${s.tmin:4}|${s.tdiff:4}|')
	}
	println(sep)
}

fn (mut st_most StationMostExtreme) next() ?[]Daily {
	return st_most.db.daily_obs.next()
}

pub fn stations_with_greater_variations_in_tmax_tmin(n int, ns int) {
	eprintln('stations_with_greater_variations_in_tmax_tmin ${n} files, ${ns} stations')

	mut st_most := new_st_most_extr(ns, create_db())

	for i, recs in st_most { // traverse daily obs

		if i % 1000 == 0 || i == n {
			eprint('${i:7} ${recs[0].get_station():12}${recs[0].get_year():5}${recs[0].get_month():3}${recs[0].get_element():8}\r')
		}
		if n != -1 && i == n {
			break
		}

		for daily in recs { // traverse array of daily recs			
			st_most.process_daily(&daily)
		}
	}
	st_most.sort()
	st_most.print()

	st_most.db.daily_obs.close()
}

/////////////////////////
// average tmax per id

type Year_map = map[int]f64 // year -> mean value
type St_year_map = map[string]Year_map // station -> year map
type St_group = map[string]f64 // station -> mean value

struct St_group_item { // station -> mean value
	id  string
	mean f64
}

fn (st_group []St_group_item) write_to_file(file_name string) {
	mut file := os.create(file_name) or { panic('error creating file ${file_name}') }
	for item in st_group {
		file.write_string('${item.id:12} ${item.mean:6.2}\n') or {
			panic('error writing to file ${file_name}')
		}
	}
	file.close()
}

pub fn avg_tmax_per_id(n int) {
	eprintln('avg_tmax_per_year ${n} files')

	mut db := create_db()
	mut nrecs := 0

	mut st_year_map := St_year_map(map[string]Year_map{})

	for i, recs in db.daily_obs { // traverse daily obs creating St_year_map
		nrecs += recs.len
		id := recs[0].get_station()

		if i % 1000 == 0 || i == n {
			eprint('${i:6}/${nrecs} ${st_year_map.len} : ${recs[0].get_station():12}${recs[0].get_year():5}${recs[0].get_month():3}${recs[0].get_element():5}\r')
		}
		if i == n {
			break
		}

		mut year_map := Year_map(map[int]f64{})
		for daily in recs { // traverse array of daily recs		
			if daily.get_element().eq(fstr('TMAX')) {
				year := daily.get_year()
				if year in year_map {
					year_map[year] = (year_map[year] + daily.avg_value()) / 2.0
				} else {
					year_map[year] = daily.avg_value()
				}
			}
		}
		if year_map.len > 0 {
			st_year_map[id.str()] = year_map
		}
	}
	eprintln('\n')

	mut st_group_items := []St_group_item{cap: st_year_map.len} // sort by mean
	for id, year_map in st_year_map {
		mut cavg := 0.0
		mut cn := 0
		for _, mean in year_map { // traverse year map
			cavg += mean
			cn++
		}
		st_group_items << St_group_item{
			id:  id
			mean: cavg / cn
		}
	}

	st_group_items.sort_with_compare(fn (a &St_group_item, b &St_group_item) int {
		return if a.mean > b.mean { 1 } else { -1 }
	})

	st_group_items.write_to_file('avg_tmax_per_year.txt')
}

/////////////////////////////
// mean tmax per	 year
/////////////////////////////
type Year = int
struct Sum_n {
mut:
	sum f64
	n   int
}
type Year_avg = map[Year]Sum_n

struct Year_st {
mut:
	year Year
	mean  f64
}

fn (mut year_st []Year_st) write_to_file(file_name string) {
	mut file := os.create(file_name) or { panic('error creating file ${file_name}') }
	for item in year_st {
		file.write_string('${item.year:12} ${item.mean:6.2}\n') or {
			panic('error writing to file ${file_name}')
		}
	}
	file.close()
}

pub fn avg_tmax_per_year(n int) {
	eprintln('avg_tmax_per_year ${n} files')

	mut db := create_db()
	mut nrecs := 0

	mut year_map := Year_avg(map[Year]Sum_n{})

	for i, recs in db.daily_obs { // traverse daily obs creating St_year_map
		nrecs += recs.len

		if i % 1000 == 0 || i == n {
			eprint('${i:6}/${nrecs} ${year_map.len} : ${recs[0].get_station():12}${recs[0].get_year():5}${recs[0].get_month():3}${recs[0].get_element():5}\r')
		}
		if n!=-1 && i == n {
			break
		}

		for daily in recs { // traverse array of daily recs		
			if daily.get_element().eq(fstr('TMAX')) {
				year := daily.get_year()
				if year in year_map {
					year_map[year].sum += daily.avg_value()
					year_map[year].n++
				} else {
					year_map[year] = Sum_n{
						sum: daily.avg_value()
						n:   1
					}
				}
			}
		}
	}
	eprintln('\n')

	mut std_dev := 0.0 // calc stddev
	mut mean := 0.0
	mut year_st := []Year_st{cap: year_map.len} // convert to array and sort by year
	for year, sum_n in year_map {
		mean += sum_n.sum / f64(sum_n.n)
		year_st << Year_st{
			year: year
			mean:  sum_n.sum / f64(sum_n.n)
		}
	}
	mean /= year_st.len
	for y in year_st {
		std_dev += math.pow(y.mean - mean, 2)
	}
	std_dev = math.sqrt(std_dev)
	eprintln('mean: ${mean:6.2}, std_dev: ${std_dev:6.2}, cv: ${100*std_dev/mean:6.2}%')	

	year_st.sort_with_compare(fn (a &Year_st, b &Year_st) int {
		return if a.year > b.year { 1 } else { -1 }
	})

	year_st.write_to_file('avg_tmax_per_year.txt') // write to file
}



/////////////////////////////

pub fn basic_traverse(n int) {
	mut db := create_db()
	mut nrecs := 0

	for i, recs in db.daily_obs { // traverse daily obs
		nrecs += recs.len

		if i % 1000 == 0 || i == n {
			eprint('${i:6}/${nrecs} : ${recs[0].get_station():12}${recs[0].get_year():5}${recs[0].get_month():3}${recs[0].get_element():5}\r')
		}
		if i == n {
			break
		}

		for daily in recs { // traverse array of daily recs			
			db.set_daily(&daily)
		}
	}
	eprintln('\n')
}
