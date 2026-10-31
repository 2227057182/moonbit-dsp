///|
/// Generates a sine wave of length `n` samples.
///
/// Parameters:
///
/// * `n` : number of samples.
/// * `freq_hz` : frequency in hertz.
/// * `sample_rate` : samples per second.
/// * `phase` : initial phase in radians (defaults to `0.0`).
pub fn sine_wave(
  n : Int32,
  freq_hz : Double,
  sample_rate : Double,
  phase~ : Double = 0.0,
) -> Array[Double] {
  let f = freq_hz / sample_rate
  Array::makei(n, fn(i) {
    @math.sin(2.0 * @math.PI * f * i.to_double() + phase)
  })
}

///|
/// Generates a square wave of length `n` samples with amplitude in
/// `[-1, 1]` and the given duty cycle (fraction of one period spent at `+1`,
/// defaults to `0.5`).
pub fn square_wave(
  n : Int32,
  freq_hz : Double,
  sample_rate : Double,
  duty~ : Double = 0.5,
) -> Array[Double] {
  let f = freq_hz / sample_rate
  Array::makei(n, fn(i) {
    let p = phase_fraction(f * i.to_double())
    if p < duty {
      1.0
    } else {
      -1.0
    }
  })
}

///|
/// Generates a triangle wave of length `n` samples, amplitude in `[-1, 1]`.
pub fn triangle_wave(
  n : Int32,
  freq_hz : Double,
  sample_rate : Double,
) -> Array[Double] {
  let f = freq_hz / sample_rate
  Array::makei(n, fn(i) {
    let p = phase_fraction(f * i.to_double())
    4.0 * (if p < 0.5 { p } else { 1.0 - p }) - 1.0
  })
}

///|
/// Generates a rising sawtooth wave of length `n` samples, amplitude in
/// `[-1, 1]`.
pub fn sawtooth_wave(
  n : Int32,
  freq_hz : Double,
  sample_rate : Double,
) -> Array[Double] {
  let f = freq_hz / sample_rate
  Array::makei(n, fn(i) { 2.0 * phase_fraction(f * i.to_double()) - 1.0 })
}

///|
/// Generates `n` samples of white noise uniformly distributed in `[-1, 1]`.
///
/// The generator is a deterministic 64-bit LCG, so a fixed `seed` always
/// produces the same sequence (useful for reproducible experiments). `seed`
/// of `0` is mapped to `1`.
pub fn white_noise(n : Int32, seed : UInt64) -> Array[Double] {
  let out = Array::make(n, 0.0)
  let mut state = if seed == 0UL { 1UL } else { seed }
  let mut i = 0
  while i < n {
    state = state * 6364136223846793005UL + 1442695040888963407UL
    let v = (state >> 11).to_double() / 9007199254740992.0
    out[i] = v * 2.0 - 1.0
    i = i + 1
  }
  out
}

///|
/// Returns the fractional part of `x` in `[0, 1)`.
fn phase_fraction(x : Double) -> Double {
  let f = x - @math.floor(x)
  if f < 0.0 {
    f + 1.0
  } else {
    f
  }
}
