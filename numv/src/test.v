module numv

import time { now }
import rand

pub fn test01() {
	mut a := new_numv(DataType.f64_, [3, 4, 4])

	a.ones()
	println(a)
	a.zeros()
	println(a)

	a.fill(1111.0)
	println(a)

	mut vv := 1.0
	for i in 0 .. 3 {
		for j in 0 .. 4 {
			for k in 0 .. 4 {
				a.set([i, j, k], vv)
				vv++
			}
		}
	}
	println(a)

	// v := a.get[f64]([3, 4, 4]) // index out of range
	println(a + a)
	println(a - a)
	println(a * a)
	println(a / a)

	a.rand()
	a.sort()
	println(a)

	mut b := a.clone() // does do a deep copy
	b += a
	println(b)
	println(a)

	n := 10
	mut c := new_numv(DataType.f64_, [n, n])
	c.rand()
	println('c:${c}')
	println('det:${c.det()}')

	println(combinations([8, 3, 5]))
}

pub fn test02() {
	mut d := rand_numv(DataType.f64_, [9, 10, 10])
	println('det for :${d.dims}')
	// println(combinations([8, 5, 5]))
	mut t0 := now()
	// mut s := 'a=${d}'
	// s = s
	println('time:${now() - t0}')
	// println(s)
	t0 = now()
	mut dt := d.det()
	println('time:${now() - t0}')

	d.save('d.npy') or { panic('save d.npy failed') }
	dt.save('dt.npy') or { panic('save dt.npy failed') }
	println("d=np.load('d.npy'); dt=np.load('dt.npy'); max(abs(np.linalg.det(d)-dt))")

	mut rd := load('d.npy') or { panic('load d.npy failed') }
	mut rdt := load('dt.npy') or { panic('load dt.npy failed') }
	println('rd:${rd}')
	println('rdt:${rdt}')

	mut inv := d.inv()
	println(inv)

	// println('det=${dt}')
	// println('np.max(abs(det - np.linalg.det(a)))')
}

pub fn test03() {
	mut d := rand_numv(DataType.f64_, [100, 90, 90])
	println('inv for :${d.dims}')

	mut t0 := now()
	di := d.inv()
	println('time inv:${now() - t0}')

	d.save('d.npy') or { panic('save d.npy failed') }
	di.save('di.npy') or { panic('save di.npy failed') }
	println('d=np.load("d.npy"); di=np.load("di.npy"); np.max(np.abs(np.linalg.inv(d)-di))')
}

pub fn test04() {
	mut a := rand_numv(DataType.f64_, [30, 10, 20, 20])
	println('dot of ${a.dims} * inv, size:${a.size}')
	mut b := a.inv()

	mut t0 := now()
	mut c := a.dot(b)
	println('time dot:${now() - t0}')

	a.save('a.npy') or { panic('save a.npy failed') }
	b.save('b.npy') or { panic('save b.npy failed') }
	c.save('c.npy') or { panic('save c.npy failed') }

	a.reshape([10, 30, 20 * 20])

	println(a == a)
	println(a < b)
	println(a > b)
	println(a <= b)
	println(a >= b)
}

pub fn test05() {
	mut a := new_numv(DataType.f64_, [5, 5])
	a.addc(1)
	println(a)
	a.mulc(2)
	println(a)
	a.subc(1)
	println(a)
	a.divc(2)
	println(a)
}

pub fn test06() {
	println('f128 test')
	mut a := new_numv(DataType.f128_, [5, 5])
	a.rand()

	a.sort()
	println(a)
	println('sum(a):${a.sum()}')
	println('det:${a.det()}')
	mut ai := a.inv()
	println('inv(a):${ai}')
	println('ai.dot(a):${ai.dot(a)}')

	mut b := a.retype(DataType.f64_)
	println('retype(f64) : ${b}')
	println('sum(b):${b.sum()}')
	println('det:${b.det()}')
	mut bi := b.inv()
	println('inv(b):${bi}')
	println('bi.dot(b):${bi.dot(b)}')
}

pub fn test07() {
	println('test07--------------')
	mut a := new_numv(DataType.f64_, [5, 5])
	a.rand()
	println(a)
	println(a.det())
}

fn rand_quad_dim() []int {
	mut dim := []int{}
	for _ in 0 .. rand.int_in_range(4, 5) or { 0 } {
		dim << rand.int_in_range(10, 20) or { 0 }
	}
	dim[dim.len - 1] = dim[dim.len - 2] // quadratic
	return dim
}

pub fn test08() {
	n := 100 // do n iters
	mut dim := rand_quad_dim()

	println('test07-------------- ')

	for i in 0 .. n {
		dim = rand_quad_dim()

		t0 := now()

		mut a := new_numv(DataType.f64_, dim)
		a.rand()
		_ := a.det()
		ai := a.inv()
		_ := ai.dot(a)

		mut b := a.retype(DataType.f128_)
		_ := b.det()
		mut bi := b.inv()
		_ := bi.dot(b)

		mut s := a + b.retype(DataType.f64_)
		_ := s.det()
		si := s.inv()
		_ := si.dot(s)

		b = a.retype(DataType.f32_)
		_ := b.det()
		bi = b.inv()
		ddd := bi.dot(b)

		println('iter ${i+1:3} ${dim:15}, size:${prod(dim):7}, dot size:${ddd.size:12}, lap:${now() - t0:9}')
	}
}
