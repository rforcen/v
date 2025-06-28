module noaa

import os

const env_noaa_data = 'NOAA_DATA' // env var noaa data path
const noaa_path = '/media/asd/data/code/noaadata/' // default value

type TableMap = map[string]string
type StationMap = map[string]Station

pub struct Station {
	id           string
	latitude     f32
	longitude    f32
	elevation    f32
	state        string
	name         string
	gsn_flag     string
	hcn_crn_flag string
	wmo_id       string
}

pub struct Noaa_db {
pub mut:
	// aux files
	countries TableMap
	states    TableMap
	elements  TableMap
	stations  StationMap
	daily     Daily
	station   Station

	cp     Compiler
	cps    []Compiler
	dbs    []Noaa_db
	nevals []int

	daily_obs DailyObs
}

// helpers
pub fn get_data_path() string {
	mut np := os.getenv(env_noaa_data) // get the data path
	if np == '' {
		if !os.exists(noaa_countries) { // current folder
			np = noaa_path
		}
	}
	return np
}

pub fn daily_obs_file() string {
	return get_data_path() + 'ghcnd_all.tar.gz'
}

fn file_map_2_table_map(fm FileMap) TableMap {
	mut t := TableMap(map[string]string{})
	for k, v in fm {
		t[k] = v[0]
	}
	return t
}

pub fn stations_2_struct(fm FileMap) StationMap {
	mut sm := StationMap(map[string]Station{})
	{}

	for k, v in fm {
		st := Station{
			id:           k
			latitude:     v[0].f32()
			longitude:    v[1].f32()
			elevation:    v[2].f32()
			state:        v[3].trim(' ')
			name:         v[4].trim(' ')
			gsn_flag:     v[5].trim(' ')
			hcn_crn_flag: v[6].trim(' ')
			wmo_id:       v[7].trim(' ')
		}
		sm[k] = st
	}
	return sm
}

//
pub fn create_db() Noaa_db {
	mut db := Noaa_db{
		daily_obs: new_daily_obs()
	}

	xf := read_all_aux()

	db.countries = file_map_2_table_map(xf[countries_name])
	db.states = file_map_2_table_map(xf[states_name])
	db.elements = file_map_2_table_map(xf[elements_name])
	db.stations = stations_2_struct(xf[stations_name])
	db.daily = Daily{}
	db.station = Station{}

	db.daily_obs = open_daily_obs() or {
		panic('create_db: error opening daily obs')
	}
	return db
}

pub fn (mut db Noaa_db) close() {
	db.daily_obs.close()
}

pub fn (mut db Noaa_db) reset() {
	db.daily_obs.reset()
}

pub fn (mut db Noaa_db) set_daily(d &Daily) {
	db.daily = d
}

pub fn (mut db Noaa_db) set_mt(n_cpu int) {
	db.cps = []Compiler{len: n_cpu, init: db.cp}
	db.nevals = []int{len: n_cpu}
	db.dbs = []Noaa_db{}
	for _ in 0 .. n_cpu {
		db.dbs << db
	}
}

pub fn print_stations(st StationMap, n int) {
	mut c := 0
	for _, v in st {
		if c == n {
			break
		}
		c++

		println(v)
	}
}

pub fn (mut db Noaa_db) load_station(daily Daily) {
	db.station = db.stations[daily.get_station().str()]
}

pub fn (mut db Noaa_db) load_station_ifrequired(daily Daily) {
	if db.cp.uses_station {
		db.station = db.stations[daily.get_station().str()]
	}
}
