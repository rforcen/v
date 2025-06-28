module noaa

// read noaa aux data files ( countries, states, elements{not in original noaa def.}, stations)
import os
import math

struct Fld { // aux file struct def. (zero releated pos, length)
	pos int
	len int
}

// aux files definition
const country_fs = [Fld{0, 2}, Fld{3, 80}]
const states_fs = [Fld{0, 2}, Fld{3, 80}]
const elements_fs = [Fld{0, 4}, Fld{5, 100}]
const stations_fs = [Fld{0, 11}, Fld{12, 8}, Fld{21, 9}, Fld{31, 6},
	Fld{38, 2}, Fld{41, 30}, Fld{72, 3}, Fld{76, 3}, Fld{80, 5}] // 11, 1, 8, 1, 9, 1, 6, 1, 2, 1, 30, 1, 3, 1, 3, 1, 5

// inventory has dupes, use FileArray type
const inventory_fs = [Fld{0, 11}, Fld{12, 8}, Fld{21, 9}, Fld{31, 4},
	Fld{36, 4}, Fld{41, 4}] // 11, 1, 8, 1, 9, 1, 4, 1, 4, 1, 4

// noaa file names
const noaa_countries = 'ghcnd-countries.txt'
const noaa_states = 'ghcnd-states.txt'
const noaa_elements = 'ghcnd-elements.txt'
const noaa_stations = 'ghcnd-stations.txt'
const noaa_inventory = 'ghcnd-inventory.txt'

// names
pub const countries_name = 'countries'
pub const states_name = 'states'
pub const elements_name = 'elements'
pub const stations_name = 'stations'
pub const inventory_name = 'inventory'

// map & array file data types
type FileMap = map[string][]string // first field is key rest of fields data
type FileArray = [][]string

// pub fn
pub fn read_aux_map(file_name string, fsa []Fld) FileMap {
	mut aux_map := FileMap(map[string][]string{})

	for line in get_lines(file_name) {
		if line != '' {
			mut fline := []string{}
			for r in fsa {
				fld := line[r.pos..math.min(r.pos + r.len, line.len)]
				fline << fld
			}
			aux_map[fline[0]] = fline[1..].clone() // must clone to create a copy of content
		}
	}
	return aux_map
}

pub fn read_aux_array(file_name string, fsa []Fld) FileArray {
	mut aux_arr := FileArray{}

	for line in get_lines(file_name) {
		if line != '' {
			mut fline := []string{}
			for r in fsa {
				fld := line[r.pos..math.min(r.pos + r.len, line.len)]
				fline << fld
			}
			aux_arr << fline.clone()
		}
	}
	return aux_arr
}

pub fn read_inventory() FileArray {
	return read_aux_array(get_data_path() + noaa_inventory, inventory_fs)
}

pub fn read_all_aux() map[string]FileMap { // read all except inventory into a map of FileMap
	np := get_data_path()

	countries := read_aux_map(np + noaa_countries, country_fs)
	states := read_aux_map(np + noaa_states, states_fs)
	elements := read_aux_map(np + noaa_elements, elements_fs)
	stations := read_aux_map(np + noaa_stations, stations_fs)

	return {
		countries_name: countries
		states_name:    states
		elements_name:  elements
		stations_name:  stations
	}
}

pub fn print_aux_map(fc FileMap, n int) {
	mut c := 0
	for k, v in fc {
		println('${k} ${v}')
		if n > 0 && c >= n {
			break
		}
		c++
	}
}

pub fn print_aux_arr(fc FileArray, n int) {
	mut c := 0
	for f in fc {
		println(f)
		if n > 0 && c >= n {
			break
		}
		c++
	}
}

// helpers
fn read_text_file(file_name string) string {
	content := os.read_file(file_name) or {
		panic('Error reading file: ${err}')
		return ''
	}
	return content
}

fn get_lines(file_name string) []string {
	return read_text_file(file_name).split('\n')
}
