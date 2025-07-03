module queens

import math { abs, min, pow }
import arrays { fold }

pub struct Queens {
pub mut:
	n int

	ld    []bool // left, right, columns set
	rd    []bool
	cl    []bool
	board []int

	ld_    &bool = unsafe { nil } // l,r,c pointers to avoid bounds checks
	rd_    &bool = unsafe { nil }
	cl_    &bool = unsafe { nil }
	board_ &int  = unsafe { nil }

	n_cases         f64
	count_solutions int
	count_evals     int
	last_val        int
	n_perm          int
	n_permutations  f64
	abort           bool
	solutions       [][]int
	stop_solutions  int

	queens []Queens // mt support, 1 per thread
}

pub fn new_queens(n int) Queens {
	mut q := Queens{
		n:              n
		ld:             []bool{len: 2 * n}
		rd:             []bool{len: 2 * n}
		cl:             []bool{len: 2 * n}
		board:          []int{len: n}
		n_cases:        pow(n, n)
		n_permutations: factorial(n)
		stop_solutions: 0
		abort:          false
	}
	q.set_pointers() // ld_, rd_, cl_, board_

	return q
}

pub fn (mut q Queens) scan(nsols int) {
	q = new_queens(q.n)
	q.find_first(nsols)
}

pub fn (mut q Queens) find_first(n_sols int) {
	q.stop_solutions = n_sols
	q.scan_(0)
}

pub fn (mut q Queens) scan_mt(nthreads int, n_sols int) {
	q = new_queens(q.n)
	q.stop_solutions = n_sols
	nth := min(nthreads, q.n)

	q.queens = []Queens{len: nth}.map(q.clone())
	for i in 0 .. nth {
		q.queens[i].set(0, i)
		q.queens[i].set(1, ((q.n / 2) + i + 1) % q.n)
		q.queens[i].queens = q.queens
	}

	mut threads := []thread{len: nth}
	for i in 0 .. nth {
		threads[i] = spawn q.scan_q(i)
	}
	threads.wait()

	// merge solutions
	for s in q.queens {
		q.solutions << s.solutions
	}
	q.count_evals = fold[Queens, int](q.queens, 0, fn (a int, b Queens) int {
		return a + b.count_evals
	})
	q.count_solutions = q.solutions.len
}

pub fn (mut q Queens) set_solution(n int) {
	if n < q.solutions.len {
		q.board = q.solutions[n].clone()
	}
}

fn (mut q Queens) scan_(col int) {
	if !q.abort {
		if col >= q.n {
			q.save_solution()
		} else {
			for i in 0 .. q.n {
				if q.is_valid_position(col, i) {
					q.set(col, i) // move

					q.count_evals++

					q.scan_(col + 1) // recur to place rest

					q.reset(col, i) // unmove
				}
			}
		}
	}
}

fn (mut q Queens) scan_q(nq int) {
	q.queens[nq].scan_(2)
}

fn (mut q Queens) clone() Queens {
	mut res := Queens{
		n:              q.n
		ld:             q.ld.clone()
		rd:             q.rd.clone()
		cl:             q.cl.clone()
		board:          q.board.clone()
		n_cases:        q.n_cases
		n_permutations: q.n_permutations
		solutions:      q.solutions.clone()
		stop_solutions: q.stop_solutions
		abort:          q.abort
	}
	res.set_pointers()
	return res
}

fn (mut q Queens) save_solution() bool {
	if !q.abort && q.is_valid() {
		q.solutions << q.board.clone()
		q.count_solutions++

		if q.queens.len > 0 { // mt -> fold count_solutions
			if q.stop_solutions != 0 && fold[Queens, int](q.queens, 0, fn (a int, b Queens) int {
				return a + b.count_solutions
			}) >= q.stop_solutions {
				q.abort()
			}
		} else {
			if q.stop_solutions != 0 && q.solutions.len >= q.stop_solutions {
				q.abort()
			}
		}
	}
	return q.abort
}

@[inline]
fn (mut q Queens) set(col int, i int) {
	unsafe { // use pointers to avoid check bounds
		q.board_[col] = i
		q.ld_[i - col + q.n - 1], q.rd_[i + col], q.cl_[i] = true, true, true
	}
}

@[inline]
fn (mut q Queens) reset(col int, i int) {
	unsafe { // use pointer to avoid check bounds	
		q.board_[col] = 0
		q.ld_[i - col + q.n - 1], q.rd_[i + col], q.cl_[i] = false, false, false
	}
}

@[inline]
fn (q Queens) is_valid_position(col int, i int) bool {
	unsafe { // use pointers to avoid check bounds
		return !q.ld_[i - col + q.n - 1] && !q.rd_[i + col] && !q.cl_[i]
	}
}

fn (q Queens) is_valid() bool {
	mut ok := true

	for i in 0 .. q.n - 1 {
		for j in i + 1 .. q.n {
			if q.board[i] == q.board[j] { // horizontal -> ci=cj
				ok = false
				break
			}
			if i - q.board[i] == j - q.board[j] { // vertical  / ri-ci = rj-cj
				ok = false
				break
			}
			if abs(q.board[i] - q.board[j]) == abs(i - j) { // vertical \ |ci-cj| = |i-j|
				ok = false
				break
			}
		}
	}
	return ok
}

fn (mut q Queens) abort() {
	q.abort = true // this &
	for mut qq in q.queens { // and all the rest
		qq.abort = true
	}
}

fn (mut q Queens) set_pointers() Queens {
	q.ld_ = &q.ld[0]
	q.rd_ = &q.rd[0]
	q.cl_ = &q.cl[0]
	q.board_ = &q.board[0]

	return q
}
