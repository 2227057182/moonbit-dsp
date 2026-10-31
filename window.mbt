///|
/// The type of a window function used to taper a finite signal before
/// spectral analysis or FIR filter design.
pub(all) enum WindowType {
  ///
  /// Rectangular window (no tapering; every sample weighted by 1).
  Rectangular
  ///
  /// Hann window: `0.5 - 0.5*cos(2*pi*i/(n-1))`.
  Hann
  ///
  /// Hamming window: `0.54 - 0.46*cos(2*pi*i/(n-1))`.
  Hamming
  ///
  /// Blackman window: `0.42 - 0.5*cos(2*pi*i/(n-1)) + 0.08*cos(4*pi*i/(n-1))`.
  Blackman
}

///|
/// Generates a symmetric window of length `n` for the given `window_type`.
///
/// Parameters:
///
/// * `window_type` : the kind of window to generate.
/// * `n` : the window length in samples. A length of `1` yields `[1.0]`.
///
/// Returns an array of `n` weights in `[0, 1]`.
pub fn window(window_type : WindowType, n : Int32) -> Array[Double] {
  if n <= 1 {
    return [1.0]
  }
  let nf = (n - 1).to_double()
  match window_type {
    Rectangular => Array::make(n, 1.0)
    Hann =>
      Array::makei(n, fn(i) {
        0.5 - 0.5 * @math.cos(2.0 * @math.PI * i.to_double() / nf)
      })
    Hamming =>
      Array::makei(n, fn(i) {
        0.54 - 0.46 * @math.cos(2.0 * @math.PI * i.to_double() / nf)
      })
    Blackman =>
      Array::makei(n, fn(i) {
        let t = 2.0 * @math.PI * i.to_double() / nf
        0.42 - 0.5 * @math.cos(t) + 0.08 * @math.cos(2.0 * t)
      })
  }
}

///|
/// Applies `window_type` to `x` sample by sample and returns the result.
///
/// The input array is not modified.
pub fn apply_window(
  x : Array[Double],
  window_type : WindowType,
) -> Array[Double] {
  let w = window(window_type, x.length())
  Array::makei(x.length(), fn(i) { x[i] * w[i] })
}

///|
/// Shortcut for [`window`](https://mooncakes.io/docs/2227057182/moonbit-dsp/latest/#~2227057182%2Fmoonbit-dsp.window)`(Rectangular, n)`.
pub fn rectangular_window(n : Int32) -> Array[Double] {
  window(Rectangular, n)
}

///|
/// Shortcut for [`window`](https://mooncakes.io/docs/2227057182/moonbit-dsp/latest/#~2227057182%2Fmoonbit-dsp.window)`(Hann, n)`.
pub fn hann_window(n : Int32) -> Array[Double] {
  window(Hann, n)
}

///|
/// Shortcut for [`window`](https://mooncakes.io/docs/2227057182/moonbit-dsp/latest/#~2227057182%2Fmoonbit-dsp.window)`(Hamming, n)`.
pub fn hamming_window(n : Int32) -> Array[Double] {
  window(Hamming, n)
}

///|
/// Shortcut for [`window`](https://mooncakes.io/docs/2227057182/moonbit-dsp/latest/#~2227057182%2Fmoonbit-dsp.window)`(Blackman, n)`.
pub fn blackman_window(n : Int32) -> Array[Double] {
  window(Blackman, n)
}
