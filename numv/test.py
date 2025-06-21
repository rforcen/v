import time
import numpy as np


def test04():
    a = np.load("a.npy")
    b = np.load("b.npy")
    c = np.load("c.npy")
    t0 = time.perf_counter()
    dd = np.dot(a, b)
    t0 = time.perf_counter() - t0
    print("lap for", c.shape, " : ", t0 * 1000, " ms")
    print("max abs diff : ", np.max(np.abs(dd - c)))


if __name__ == "__main__":
    test04()
