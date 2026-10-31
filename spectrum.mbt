///|
/// Computes the one-sided magnitude spectrum of `x`.
///
/// The input is zero-padded to a power of two when necessary and analyzed
/// with the FFT. The result has length `n/2 + 1` (bins `0..=n/2`), where bin
/// `k` corresponds to the frequency `k * fs / n`. Non-DC and non-Nyquist bins
/// are scaled by `2` to fold the energy of the mirrored half.
pub fn magnitude_spectrum(x : Array[Double]) -> Array[Double] {
  let n = next_power_of_two(x.length())
  let padded = if n == x.length() { x } else { pad_to_power_of_two(x) }
  let spec = fft(padded)
  let bins = n / 2 + 1
  Array::makei(bins, fn(k) {
    let re = spec[k].re
    let im = spec[k].im
    let mag = (re * re + im * im).sqrt()
    if k == 0 || k == n / 2 {
      mag
    } else {
      2.0 * mag
    }
  })
}

///|
/// Computes the one-sided power spectrum (periodogram) of `x`.
///
/// `power[k] = |X[k]|^2 / N` with the same one-sided scaling as
/// [`magnitude_spectrum`](https://mooncakes.io/docs/2227057182/moonbit-dsp/latest/#~2227057182%2Fmoonbit-dsp.magnitude_spectrum).
pub fn power_spectrum(x : Array[Double]) -> Array[Double] {
  let n = next_power_of_two(x.length())
  let padded = if n == x.length() { x } else { pad_to_power_of_two(x) }
  let spec = fft(padded)
  let bins = n / 2 + 1
  let nf = n.to_double()
  Array::makei(bins, fn(k) {
    let re = spec[k].re
    let im = spec[k].im
    let p = (re * re + im * im) / nf
    if k == 0 || k == n / 2 {
      p
    } else {
      2.0 * p
    }
  })
}

///|
/// Finds the dominant (strongest non-DC) frequency and its magnitude.
///
/// Parameters:
///
/// * `x` : the time-domain samples.
/// * `sample_rate` : samples per second.
///
/// Returns `(frequency_hz, magnitude)` of the peak bin. Returns `(0.0, 0.0)`
/// when the spectrum has no usable peak.
pub fn dominant_frequency(
  x : Array[Double],
  sample_rate : Double,
) -> (Double, Double) {
  let n = next_power_of_two(x.length())
  let padded = if n == x.length() { x } else { pad_to_power_of_two(x) }
  let spec = fft(padded)
  let nf = n.to_double()
  let mut best_bin = -1
  let mut best_mag = 0.0
  for k in 1..<(n / 2) {
    let re = spec[k].re
    let im = spec[k].im
    let mag = (re * re + im * im).sqrt()
    if mag > best_mag {
      best_mag = mag
      best_bin = k
    }
  }
  if best_bin < 0 {
    return (0.0, 0.0)
  }
  let freq = best_bin.to_double() * sample_rate / nf
  let mag = if best_bin == n / 2 { best_mag } else { 2.0 * best_mag }
  (freq, mag)
}

///|
/// Returns the indices of local maxima in `values`.
///
/// An index `i` with `0 < i < n-1` is a peak when `values[i]` is strictly
/// greater than both neighbours. Endpoints are never reported.
pub fn find_peaks(values : Array[Double]) -> Array[Int32] {
  let n = values.length()
  let out = Array(capacity=0)
  for i in 1..<(n - 1) {
    if values[i] > values[i - 1] && values[i] > values[i + 1] {
      out.push(i)
    }
  }
  out
}

///|
/// Returns the `count` strongest `(index, value)` pairs of `values`, sorted
/// by value in descending order. Indices of equal values are ordered by
/// ascending index.
pub fn top_k(values : Array[Double], count : Int32) -> Array[(Int32, Double)] {
  let n = values.length()
  let pairs = Array::makei(n, fn(i) { (i, values[i]) })
  pairs.sort_by(fn(a, b) {
    if a.1 > b.1 {
      -1
    } else if a.1 < b.1 {
      1
    } else if a.0 < b.0 {
      -1
    } else {
      1
    }
  })
  let take = if count < n { count } else { n }
  let out = Array(capacity=0)
  for i in 0..<take {
    out.push(pairs[i])
  }
  out
}
