///|
/// Computes the full linear convolution of `x` and `h`.
///
/// `out[k] = sum_j x[j] * h[k-j]`, with length `x.length() + h.length() - 1`.
/// The input arrays are not modified.
pub fn convolve(x : Array[Double], h : Array[Double]) -> Array[Double] {
  let nx = x.length()
  let nh = h.length()
  if nx == 0 || nh == 0 {
    return []
  }
  let out = Array::make(nx + nh - 1, 0.0)
  for i in 0..<nx {
    for j in 0..<nh {
      out[i + j] = out[i + j] + x[i] * h[j]
    }
  }
  out
}

///|
/// Cross-correlation of `x` and `y`.
///
/// The result has length `nx + ny - 1`; index `ny - 1` corresponds to zero
/// lag. Positive lags (as `y` shifted right relative to `x`) are stored at
/// indices greater than `ny - 1`.
pub fn correlate(x : Array[Double], y : Array[Double]) -> Array[Double] {
  let nx = x.length()
  let ny = y.length()
  if nx == 0 || ny == 0 {
    return []
  }
  let total = nx + ny - 1
  let out = Array::make(total, 0.0)
  for k in 0..<total {
    let mut s = 0.0
    for i in 0..<nx {
      let j = i - k + (ny - 1)
      if j >= 0 && j < ny {
        s = s + x[i] * y[j]
      }
    }
    out[k] = s
  }
  out
}

///|
/// Autocorrelation of `x`.
///
/// Equivalent to `correlate(x, x)`. The zero-lag value is at index
/// `x.length() - 1`.
pub fn autocorrelate(x : Array[Double]) -> Array[Double] {
  correlate(x, x)
}
