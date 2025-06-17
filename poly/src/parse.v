// parse polyhedron definition file from dmccooey.com/polyhedra/

module poly

import os
import strconv

// parse_polyhedron_file reads a .txt file and returns a Polyhedron struct
pub fn parse_polyhedron_file(filepath string) !Polyhedron {
	file_content := os.read_file(filepath)!

	lines := file_content.split_into_lines()

	mut polyhedron := Polyhedron{}
	mut current_section := '' // To track if we're parsing constants, vertices or faces
	mut constants := map[string]f32{} // Map to store constants: "C0" -> 0.207...

	for i, line in lines {
		trimmed_line := line.trim_space()

		if trimmed_line.len == 0 {
			continue // Skip empty lines
		}
		if trimmed_line.starts_with('#') {
			continue // Skip comment lines
		}

		if i == 0 {
			// First line is the polyhedron name
			polyhedron.name = trimmed_line.replace(' ', '')
			current_section = 'constants' // After name, expect constants
			continue
		}

		// --- Constant Section ---
		if current_section == 'constants' && trimmed_line.starts_with('C')
			&& trimmed_line.contains('=') {
			// Example: C0 = 0.2071067811865475244008443621048 = (sqrt(2) - 1) / 2
			// We need the part before the second '='
			parts := trimmed_line.split('=')
			if parts.len < 2 {
				return error('Invalid constant line format: ${trimmed_line}')
			}
			// Key is 'C0', 'C1', etc.
			key := parts[0].trim_space()

			if key in constants {
				continue // skip duplicate constants -> explanation constants
			}

			// Value is '0.2071067811865475244008443621048'
			mut value_str := parts[1].trim_space()

			// If there's a second '=', take only the first numeric part
			if value_str.contains(' ') { // Heuristic: if spaces, assume second assignment or formula
				value_str = value_str.split(' ')[0] // Take '0.207...' from '0.207... = (sqrt...'
			}

			// Using f32(strconv.atof64(value_str)!) as specified
			val := f32(strconv.atof64(value_str)!)
			constants[key] = val
		} else if trimmed_line.starts_with('V') && trimmed_line.contains('=') {
			// --- Vertex Section (starts when we hit a V line) ---
			current_section = 'vertices'
			// Example: V0 = ( C0, C1, -C1) or V0 = ( 0.5, 0.5, 0.5)
			parts := trimmed_line.split('=')
			if parts.len < 2 {
				return error('Invalid vertex line format: ${trimmed_line}')
			}
			coords_str := parts[1].trim_space().trim_left('(').trim_right(')')
			coords_str_parts := coords_str.split(',')

			if coords_str_parts.len != 3 {
				return error('Invalid vertex coordinates format: ${trimmed_line}')
			}

			mut x_val := f32(0.0)
			mut y_val := f32(0.0)
			mut z_val := f32(0.0)

			// Helper function to resolve coordinate from string (constant or literal)
			resolve_coord := fn [constants, trimmed_line] (coord_part string) !f32 {
				trimmed_coord := coord_part.trim_space()
				is_negative := trimmed_coord.starts_with('-')
				clean_coord := if is_negative { trimmed_coord[1..] } else { trimmed_coord }

				if clean_coord.starts_with('C') {
					// It's a constant
					if clean_coord !in constants {
						return error('Undefined constant: ${clean_coord} in line: ${trimmed_line}')
					}
					val := constants[clean_coord]
					return if is_negative { -val } else { val }
				} else {
					// It's a literal float
					// Using f32(strconv.atof64(trimmed_coord)!) as specified
					val := f32(strconv.atof64(trimmed_coord)!)
					return val // The negative sign is already included if present
				}
			}

			x_val = resolve_coord(coords_str_parts[0])!
			y_val = resolve_coord(coords_str_parts[1])!
			z_val = resolve_coord(coords_str_parts[2])!

			polyhedron.vertexes_ << Vertex{
				x: x_val
				y: y_val
				z: z_val
			}
		} else if trimmed_line == 'Faces:' {
			// --- Face Section (starts when we hit 'Faces:') ---
			current_section = 'faces'
			continue // Skip the "Faces:" line itself
		} else if current_section == 'faces' && trimmed_line.starts_with('{') {
			// Example: { 0, 1, 5, 4 }
			indices_str := trimmed_line.trim_left('{').trim_right('}').trim_space()
			indices_str_parts := indices_str.split(',')

			mut face_indices := []int{}
			for index_str in indices_str_parts {
				idx := strconv.atoi(index_str.trim_space())!
				face_indices << idx
			}
			polyhedron.faces << face_indices
		}
	}

	return polyhedron
}

// create a []Polyhedron with all .txt files in the given folder
pub fn load_parse_all(home_folder string) []Polyhedron {
	entries := os.ls(home_folder) or { [] }
	mut result := []Polyhedron{}
	for entry in entries {
		mut p := parse_polyhedron_file(home_folder + entry) or { Polyhedron{} }
		result << p // load the raw one need to recalc
	}
	return result
}
