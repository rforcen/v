module queens

import time { now }
import runtime { nr_cpus }
import os

fn t01(nq int) {
	mut q := new_queens(nq)
	t0 := now()
	q.find_first(5)

	println('nqueens: $nq, lap: ${now() - t0}, # solutions: ${q.count_solutions}, # evals: ${q.count_evals}')
	for i, s in q.solutions {
		println('${i + 1}: ${s}')
	}
}

fn t02(nq int) {
	// a:=[1,2,3,4]
	// println(unsafe{a[5]})

	mut q := new_queens(nq)

	t0 := now()
	q.scan_mt(nr_cpus(), 1)
	println('nqueens: $nq, lap: ${now() - t0}, # solutions: ${q.count_solutions}, # evals: ${q.count_evals}')
	for i, s in q.solutions {
		println('${i + 1}: ${s}')
	}
}
fn t03() {
	nq := if os.args.len > 1 { os.args[1].int() } else { 12 }
	//t01(nq)
	t02(nq)
}