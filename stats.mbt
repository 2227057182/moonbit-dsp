///|
/// Returns the arithmetic mean of `x`. Returns `0.0` for an empty array.
pub fn mean(x : Array[Double]) -> Double {
  let n = x.length()
  if n == 0 {
    return 0.0
  }
  let mut sum = 0.0
  for i in 0..<n {
    sum = sum + x[i]
  }
  sum / n.to_double()
}

///|
/// Variance of `x`.
///
/// `sample~ = false` (default) computes the population variance
/// (`/n`); `sample~ = true` computes the sample variance (`/(n-1)`).
/// Returns `0.0` for an empty array.
pub fn variance(x : Array[Double], sample~ : Bool = false) -> Double {
  let n = x.length()
  if n == 0 {
    return 0.0
  }
  let m = mean(x)
  let mut s = 0.0
  for i in 0..<n {
    let d = x[i] - m
    s = s + d * d
  }
  let den = if sample { (n - 1).to_double() } else { n.to_double() }
  s / den
}

///|
/// Standard deviation of `x`; the square root of
/// [`variance`](https://mooncakes.io/docs/2227057182/moonbit-dsp/latest/#~2227057182%2Fmoonbit-dsp.variance).
pub fn stddev(x : Array[Double], sample~ : Bool = false) -> Double {
  variance(x, sample~).sqrt()
}

///|
/// Root-mean-square value of `x`: `sqrt(mean(x^2))`.
pub fn rms(x : Array[Double]) -> Double {
  let n = x.length()
  if n == 0 {
    return 0.0
  }
  let mut s = 0.0
  for i in 0..<n {
    s = s + x[i] * x[i]
  }
  (s / n.to_double()).sqrt()
}

///|
/// Total energy of `x`: `sum(x[i]^2)`.
pub fn energy(x : Array[Double]) -> Double {
  let mut s = 0.0
  for i in 0..<x.length() {
    s = s + x[i] * x[i]
  }
  s
}

///|
/// The maximum absolute value of `x` (`0.0` for an empty array).
pub fn max_abs(x : Array[Double]) -> Double {
  let mut m = 0.0
  for i in 0..<x.length() {
    let a = x[i].abs()
    if a > m {
      m = a
    }
  }
  m
}

///|
/// Scales `x` so that its maximum absolute value becomes `1.0`.
///
/// Returns a copy; the input is not modified. An all-zero (or empty) input
/// is returned unchanged.
pub fn normalize(x : Array[Double]) -> Array[Double] {
  let m = max_abs(x)
  if m <= 1.0e-15 {
    return x.copy()
  }
  Array::makei(x.length(), fn(i) { x[i] / m })
}
