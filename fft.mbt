///|
/// Returns `true` when `n` is a positive power of two.
pub fn is_power_of_two(n : Int32) -> Bool {
  n > 0 && (n & (n - 1)) == 0
}

///|
/// Returns the smallest power of two that is at least `n`.
///
/// `next_power_of_two(0)` is `1`.
pub fn next_power_of_two(n : Int32) -> Int32 {
  let mut k = 1
  while k < n {
    k = k * 2
  }
  k
}

///|
/// Computes the discrete Fourier transform directly in `O(n^2)`.
///
/// `X[k] = sum_{i=0}^{n-1} x[i] * exp(-2*pi*i*k*j/n)` with `j` the imaginary
/// unit. Works for any positive length.
pub fn dft(x : Array[Double]) -> Array[Complex] {
  let n = x.length()
  let nf = n.to_double()
  let out = Array::make(n, Complex::zero())
  for k in 0..<n {
    let mut re = 0.0
    let mut im = 0.0
    let kf = k.to_double()
    for i in 0..<n {
      let angle = 2.0 * @math.PI * kf * i.to_double() / nf
      let w_re = @math.cos(angle)
      let w_im = -@math.sin(angle)
      re = re + x[i] * w_re
      im = im + x[i] * w_im
    }
    out[k] = Complex::new(re, im)
  }
  out
}

///|
/// Computes the fast Fourier transform with an iterative radix-2
/// Cooley-Tukey algorithm in `O(n log n)`.
///
/// The length `n` of `x` must be a power of two. For other lengths use
/// [`dft`](https://mooncakes.io/docs/2227057182/moonbit-dsp/latest/#~2227057182%2Fmoonbit-dsp.dft).
pub fn fft(x : Array[Double]) -> Array[Complex] {
  let n = x.length()
  let data = Array::makei(n, fn(i) { Complex::new(x[i], 0.0) })
  fft_inplace(data)
  data
}

///|
/// In-place radix-2 decimation-in-time FFT over an array of complex numbers.
///
/// The input length must be a power of two; otherwise the result is undefined.
fn fft_inplace(x : Array[Complex]) -> Unit {
  let n = x.length()
  // Bit-reversal permutation.
  let mut j = 0
  for i in 0..<n {
    if i < j {
      let tmp = x[i]
      x[i] = x[j]
      x[j] = tmp
    }
    let mut m = n >> 1
    while m >= 1 && j >= m {
      j = j - m
      m = m >> 1
    }
    j = j + m
  }
  // Butterfly stages.
  let mut len = 2
  while len <= n {
    let angle = -2.0 * @math.PI / len.to_double()
    let wlen_re = @math.cos(angle)
    let wlen_im = @math.sin(angle)
    let half = len / 2
    let mut i = 0
    while i < n {
      let mut w_re = 1.0
      let mut w_im = 0.0
      for k in 0..<half {
        let a = x[i + k]
        let b = x[i + k + half]
        let b_re = b.re * w_re - b.im * w_im
        let b_im = b.re * w_im + b.im * w_re
        x[i + k] = Complex::new(a.re + b_re, a.im + b_im)
        x[i + k + half] = Complex::new(a.re - b_re, a.im - b_im)
        let next_re = w_re * wlen_re - w_im * wlen_im
        let next_im = w_re * wlen_im + w_im * wlen_re
        w_re = next_re
        w_im = next_im
      }
      i = i + len
    }
    len = len * 2
  }
}

///|
/// Zero-pads `x` to the next power of two and returns the padded copy.
///
/// Padded samples are set to `0.0`.
pub fn pad_to_power_of_two(x : Array[Double]) -> Array[Double] {
  let target = next_power_of_two(x.length())
  let out = Array::make(target, 0.0)
  for i in 0..<x.length() {
    out[i] = x[i]
  }
  out
}
