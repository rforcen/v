module main

import poly
import os

fn main() {
	if os.args.len < 2 {
		poly.ui()
	} else {
		poly.build(os.args[1]).write_obj() or { println('error writing obj') }
	}
}
