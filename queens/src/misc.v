module queens

fn factorial(n int) f64 {
	if n == 0 {
		return 1
	}
	return f64(n) * factorial(n - 1)
}
