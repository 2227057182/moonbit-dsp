///|
/// Coefficients of a second-order IIR filter in direct form II:
/// `y[n] = b0*x[n] + b1*x[n-1] + b2*x[n-2] - a1*y[n-1] - a2*y[n-2]`.
pub struct IirCoeffs2 {
  b0 : Double
  b1 : Double
  b2 : Double
  a1 : Double
  a2 : Double
}

///|
/// Designs a low-pass FIR filter with the window method.
///
/// Parameters:
///
/// * `cutoff_norm` : normalized cutoff frequency in `(0, 0.5)`, i.e. the
///   ratio `fc / fs`. Frequencies above this are attenuated.
/// * `taps` : number of filter taps (odd values give a symmetric, linear-phase
///   filter).
/// * `window_type` : window used to truncate the ideal impulse response.
///
/// Returns normalized coefficients whose DC gain is exactly 1.
pub fn fir_lowpass_coeffs(
  cutoff_norm : Double,
  taps : Int32,
  window_type : WindowType,
) -> Array[Double] {
  if taps <= 1 {
    return [1.0]
  }
  let center = (taps - 1) / 2
  let w = 2.0 * cutoff_norm
  let ideal = Array::makei(taps, fn(i) {
    let k = (i - center).to_double()
    if k == 0.0 {
      w
    } else {
      let arg = @math.PI * w * k
      w * @math.sin(arg) / arg
    }
  })
  let win = window(window_type, taps)
  let mut sum = 0.0
  for i in 0..<taps {
    sum = sum + ideal[i] * win[i]
  }
  if sum.abs() < 1.0e-12 {
    return Array::make(taps, 0.0)
  }
  Array::makei(taps, fn(i) { ideal[i] * win[i] / sum })
}

///|
/// Applies the FIR filter with impulse response `h` to `x` by full
/// convolution. The output length is `x.length() + h.length() - 1`.
pub fn fir_filter(x : Array[Double], h : Array[Double]) -> Array[Double] {
  convolve(x, h)
}

///|
/// First-order IIR low-pass filter.
///
/// `y[n] = alpha * x[n] + (1 - alpha) * y[n-1]`. Use
/// [`alpha_from_cutoff`](https://mooncakes.io/docs/2227057182/moonbit-dsp/latest/#~2227057182%2Fmoonbit-dsp.alpha_from_cutoff)
/// to pick `alpha` from a normalized cutoff frequency.
pub fn iir_lowpass_1(x : Array[Double], alpha : Double) -> Array[Double] {
  let n = x.length()
  let y = Array::make(n, 0.0)
  let mut prev = 0.0
  for i in 0..<n {
    let yi = alpha * x[i] + (1.0 - alpha) * prev
    y[i] = yi
    prev = yi
  }
  y
}

///|
/// Maps a normalized cutoff frequency `fc/fs in (0, 0.5)` to the `alpha`
/// parameter of a first-order IIR low-pass filter:
/// `alpha = 1 - exp(-2*pi*fc/fs)`.
pub fn alpha_from_cutoff(cutoff_norm : Double) -> Double {
  1.0 - @math.exp(-2.0 * @math.PI * cutoff_norm)
}

///|
/// Designs a second-order Butterworth low-pass filter with the bilinear
/// transform.
///
/// `cutoff_norm` is the normalized cutoff `fc/fs` in `(0, 0.5)`.
pub fn butterworth_lowpass_2(cutoff_norm : Double) -> IirCoeffs2 {
  let wc = 2.0 * @math.PI * cutoff_norm
  let k = @math.tan(wc / 2.0)
  let sqrt2 = 2.0.sqrt()
  let den = 1.0 + sqrt2 * k + k * k
  let b0 = k * k / den
  {
    b0,
    b1: 2.0 * b0,
    b2: b0,
    a1: 2.0 * (k * k - 1.0) / den,
    a2: (1.0 - sqrt2 * k + k * k) / den,
  }
}

///|
/// Applies a second-order IIR filter in direct form II.
pub fn iir_filter_2(x : Array[Double], c : IirCoeffs2) -> Array[Double] {
  let n = x.length()
  let y = Array::make(n, 0.0)
  let mut x1 = 0.0
  let mut x2 = 0.0
  let mut y1 = 0.0
  let mut y2 = 0.0
  for i in 0..<n {
    let xi = x[i]
    let yi = c.b0 * xi + c.b1 * x1 + c.b2 * x2 - c.a1 * y1 - c.a2 * y2
    y[i] = yi
    x2 = x1
    x1 = xi
    y2 = y1
    y1 = yi
  }
  y
}
