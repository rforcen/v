/*
    
*/

module main

import noaa
import os

fn main() {
	n := if os.args.len < 2 {
		2000
	} else {
		os.args[1].int()
	}
	noaa.avg_tmax_per_year(n)
}
