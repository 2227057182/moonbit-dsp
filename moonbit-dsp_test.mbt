///|
/// Asserts that `actual` is within `tol` of `expected`.
fn assert_close(actual : Double, expected : Double, tol : Double) -> Unit raise {
  if (actual - expected).abs() > tol {
    @test.fail("expected \{expected}, got \{actual}")
  }
}

///|
/// Asserts that every element of `a` is within `tol` of the corresponding
/// element of `b`.
fn assert_close_array(
  a : Array[Double],
  b : Array[Double],
  tol : Double,
) -> Unit raise {
  @test.assert_eq(a.length(), b.length())
  for i in 0..<a.length() {
    if (a[i] - b[i]).abs() > tol {
      @test.fail("index \{i}: expected \{b[i]}, got \{a[i]}")
    }
  }
}

///|
/// Asserts that a complex number is within `tol` of `(re, im)`.
fn assert_close_complex(
  a : @moonbit-dsp.Complex,
  re : Double,
  im : Double,
  tol : Double,
) -> Unit raise {
  assert_close(a.re, re, tol)
  assert_close(a.im, im, tol)
}

///|
test "complex add" {
  let a = @moonbit-dsp.Complex::new(1.0, 2.0)
  let b = @moonbit-dsp.Complex::new(3.0, 4.0)
  let c = a.add(b)
  assert_close(c.re, 4.0, 1.0e-12)
  assert_close(c.im, 6.0, 1.0e-12)
}

///|
test "complex multiply" {
  let a = @moonbit-dsp.Complex::new(1.0, 2.0)
  let b = @moonbit-dsp.Complex::new(3.0, 4.0)
  let c = a.mul(b)
  assert_close(c.re, -5.0, 1.0e-12)
  assert_close(c.im, 10.0, 1.0e-12)
}

///|
test "complex divide" {
  // (1 + 0i) / (0 + 1i) = -i
  let a = @moonbit-dsp.Complex::new(1.0, 0.0)
  let b = @moonbit-dsp.Complex::new(0.0, 1.0)
  let c = a.div(b)
  assert_close(c.re, 0.0, 1.0e-12)
  assert_close(c.im, -1.0, 1.0e-12)
}

///|
test "complex abs conj phase" {
  let a = @moonbit-dsp.Complex::new(3.0, 4.0)
  assert_close(a.abs(), 5.0, 1.0e-12)
  let c = a.conj()
  assert_close(c.re, 3.0, 1.0e-12)
  assert_close(c.im, -4.0, 1.0e-12)
  let b = @moonbit-dsp.Complex::new(1.0, 0.0)
  assert_close(b.phase(), 0.0, 1.0e-12)
}

///|
test "window hamming symmetry and endpoints" {
  let w = @moonbit-dsp.hamming_window(7)
  @test.assert_eq(w.length(), 7)
  assert_close(w[0], w[6], 1.0e-12)
  assert_close(w[1], w[5], 1.0e-12)
  assert_close(w[2], w[4], 1.0e-12)
  assert_close(w[0], 0.08, 1.0e-9)
  assert_close(w[3], 1.0, 1.0e-9)
}

///|
test "window hann center" {
  let w = @moonbit-dsp.hann_window(5)
  assert_close(w[2], 1.0, 1.0e-12)
  assert_close(w[0], 0.0, 1.0e-12)
}

///|
test "window blackman center" {
  let w = @moonbit-dsp.blackman_window(5)
  assert_close(w[2], 1.0, 1.0e-12)
  assert_close(w[0], 0.0, 1.0e-12)
}

///|
test "window length one" {
  let w = @moonbit-dsp.hamming_window(1)
  @test.assert_eq(w.length(), 1)
  assert_close(w[0], 1.0, 1.0e-12)
}

///|
test "apply window scales samples" {
  let x = [1.0, 1.0, 1.0]
  let w = @moonbit-dsp.apply_window(x, @moonbit-dsp.WindowType::Hann)
  // 3-point Hann window: [0, 1, 0]
  assert_close(w[0], 0.0, 1.0e-12)
  assert_close(w[1], 1.0, 1.0e-12)
  assert_close(w[2], 0.0, 1.0e-12)
}

///|
test "power of two helpers" {
  @test.assert_eq(@moonbit-dsp.is_power_of_two(1), true)
  @test.assert_eq(@moonbit-dsp.is_power_of_two(8), true)
  @test.assert_eq(@moonbit-dsp.is_power_of_two(6), false)
  @test.assert_eq(@moonbit-dsp.is_power_of_two(0), false)
  @test.assert_eq(@moonbit-dsp.next_power_of_two(5), 8)
  @test.assert_eq(@moonbit-dsp.next_power_of_two(8), 8)
  @test.assert_eq(@moonbit-dsp.next_power_of_two(0), 1)
}

///|
test "fft two point" {
  let x = [1.0, 1.0]
  let y = @moonbit-dsp.fft(x)
  assert_close_complex(y[0], 2.0, 0.0, 1.0e-12)
  assert_close_complex(y[1], 0.0, 0.0, 1.0e-12)
}

///|
test "fft impulse is flat" {
  let x = @moonbit-dsp.pad_to_power_of_two([1.0, 0.0, 0.0, 0.0])
  let y = @moonbit-dsp.fft(x)
  for k in 0..<4 {
    assert_close_complex(y[k], 1.0, 0.0, 1.0e-12)
  }
}

///|
test "fft matches dft" {
  let x = @moonbit-dsp.sine_wave(64, 7.5, 64.0)
  let f = @moonbit-dsp.fft(x)
  let d = @moonbit-dsp.dft(x)
  @test.assert_eq(f.length(), d.length())
  for k in 0..<f.length() {
    assert_close(f[k].re, d[k].re, 1.0e-9)
    assert_close(f[k].im, d[k].im, 1.0e-9)
  }
}

///|
test "parseval theorem" {
  // sum(x^2) == sum(|X|^2) / n
  let x = @moonbit-dsp.sine_wave(128, 10.0, 256.0)
  let spec = @moonbit-dsp.fft(x)
  let mut time_energy = 0.0
  for i in 0..<x.length() {
    time_energy = time_energy + x[i] * x[i]
  }
  let mut freq_energy = 0.0
  for k in 0..<spec.length() {
    freq_energy = freq_energy +
      spec[k].re * spec[k].re +
      spec[k].im * spec[k].im
  }
  assert_close(freq_energy / spec.length().to_double(), time_energy, 1.0e-6)
}

///|
test "convolve known result" {
  let y = @moonbit-dsp.convolve([1.0, 2.0, 3.0], [1.0, 1.0])
  @test.assert_eq(y.length(), 4)
  assert_close_array(y, [1.0, 3.0, 5.0, 3.0], 1.0e-12)
}

///|
test "convolve is commutative" {
  let a = [1.0, 2.0, 3.0, 4.0]
  let b = [0.5, 1.0]
  let ab = @moonbit-dsp.convolve(a, b)
  let ba = @moonbit-dsp.convolve(b, a)
  assert_close_array(ab, ba, 1.0e-12)
}

///|
test "correlate zero lag is dot product" {
  let x = [1.0, 2.0, 3.0]
  let y = [1.0, 1.0]
  let c = @moonbit-dsp.correlate(x, y)
  // zero lag sits at index ny-1 == 1: sum_i x[i]*y[i] = 1*1 + 2*1 = 3
  @test.assert_eq(c.length(), 4)
  assert_close(c[1], 3.0, 1.0e-12)
}

///|
test "autocorrelate symmetric" {
  let x = [1.0, 2.0, 1.0]
  let a = @moonbit-dsp.autocorrelate(x)
  @test.assert_eq(a.length(), 5)
  // symmetric around the zero-lag index (2)
  assert_close(a[0], a[4], 1.0e-12)
  assert_close(a[1], a[3], 1.0e-12)
  // zero-lag value equals energy
  assert_close(a[2], 6.0, 1.0e-12)
}

///|
test "fir lowpass dc gain is one" {
  let h = @moonbit-dsp.fir_lowpass_coeffs(
    0.25,
    31,
    @moonbit-dsp.WindowType::Hamming,
  )
  let mut sum = 0.0
  for i in 0..<h.length() {
    sum = sum + h[i]
  }
  assert_close(sum, 1.0, 1.0e-9)
}

///|
test "fir lowpass symmetric with odd taps" {
  let h = @moonbit-dsp.fir_lowpass_coeffs(
    0.2,
    21,
    @moonbit-dsp.WindowType::Hamming,
  )
  for i in 0..<10 {
    assert_close(h[i], h[20 - i], 1.0e-12)
  }
}

///|
test "fir filter length" {
  let h = @moonbit-dsp.fir_lowpass_coeffs(
    0.2,
    11,
    @moonbit-dsp.WindowType::Hann,
  )
  let x = @moonbit-dsp.sine_wave(50, 5.0, 100.0)
  let y = @moonbit-dsp.fir_filter(x, h)
  @test.assert_eq(y.length(), 50 + 11 - 1)
}

///|
test "alpha from cutoff in unit interval" {
  let a = @moonbit-dsp.alpha_from_cutoff(0.1)
  assert_close(a, 1.0 - @math.exp(-2.0 * @math.PI * 0.1), 1.0e-12)
  @test.assert_eq(a > 0.0 && a < 1.0, true)
}

///|
test "iir lowpass 1 constant input reaches steady state" {
  let x = Array::make(200, 1.0)
  let y = @moonbit-dsp.iir_lowpass_1(x, @moonbit-dsp.alpha_from_cutoff(0.05))
  assert_close(y[199], 1.0, 1.0e-9)
}

///|
test "butterworth lowpass 2 dc gain" {
  let c = @moonbit-dsp.butterworth_lowpass_2(0.2)
  let x = Array::make(200, 1.0)
  let y = @moonbit-dsp.iir_filter_2(x, c)
  assert_close(y[199], 1.0, 1.0e-9)
}

///|
test "butterworth lowpass 2 attenuates high frequency" {
  // A sine at half the cutoff should be attenuated compared with DC-like input.
  let c = @moonbit-dsp.butterworth_lowpass_2(0.1)
  let x = @moonbit-dsp.sine_wave(1024, 30.0, 100.0) // 0.3 of Nyquist, above cutoff
  let y = @moonbit-dsp.iir_filter_2(x, c)
  let input_rms = @moonbit-dsp.rms(x)
  let output_rms = @moonbit-dsp.rms(y)
  @test.assert_eq(output_rms < input_rms * 0.3, true)
}

///|
test "sine wave known values" {
  // 250 Hz at 1000 Hz sample rate, 4 samples: one quarter period each.
  let x = @moonbit-dsp.sine_wave(4, 250.0, 1000.0)
  assert_close(x[0], 0.0, 1.0e-12)
  assert_close(x[1], 1.0, 1.0e-12)
  assert_close(x[2], 0.0, 1.0e-12)
  assert_close(x[3], -1.0, 1.0e-12)
}

///|
test "sine wave phase parameter" {
  let x = @moonbit-dsp.sine_wave(1, 100.0, 1000.0, phase=@math.PI / 2.0)
  assert_close(x[0], 1.0, 1.0e-12)
}

///|
test "square wave takes duty values" {
  let x = @moonbit-dsp.square_wave(100, 10.0, 1000.0, duty=0.25)
  let mut saw_high = false
  let mut saw_low = false
  for i in 0..<100 {
    if x[i] == 1.0 {
      saw_high = true
    } else if x[i] == -1.0 {
      saw_low = true
    }
  }
  @test.assert_eq(saw_high, true)
  @test.assert_eq(saw_low, true)
}

///|
test "triangle and sawtooth stay in bounds" {
  let t = @moonbit-dsp.triangle_wave(200, 5.0, 1000.0)
  let s = @moonbit-dsp.sawtooth_wave(200, 5.0, 1000.0)
  for i in 0..<200 {
    @test.assert_eq(t[i] >= -1.0 && t[i] <= 1.0, true)
    @test.assert_eq(s[i] >= -1.0 && s[i] <= 1.0, true)
  }
}

///|
test "white noise deterministic and bounded" {
  let a = @moonbit-dsp.white_noise(100, 42UL)
  let b = @moonbit-dsp.white_noise(100, 42UL)
  assert_close_array(a, b, 0.0)
  let mut in_bounds = true
  for i in 0..<100 {
    if a[i] < -1.0 || a[i] > 1.0 {
      in_bounds = false
    }
  }
  @test.assert_eq(in_bounds, true)
}

///|
test "white noise mean near zero" {
  let x = @moonbit-dsp.white_noise(4096, 7UL)
  let m = @moonbit-dsp.mean(x)
  assert_close(m, 0.0, 0.02)
}

///|
test "dominant frequency detection" {
  // fs=8192, N=2048 -> resolution 4 Hz; 100 Hz is exactly bin 25.
  let x = @moonbit-dsp.sine_wave(2048, 100.0, 8192.0)
  let (freq, mag) = @moonbit-dsp.dominant_frequency(x, 8192.0)
  assert_close(freq, 100.0, 1.0e-6)
  @test.assert_eq(mag > 1000.0, true)
}

///|
test "magnitude spectrum peak bin" {
  let x = @moonbit-dsp.sine_wave(512, 50.0, 1024.0)
  let spec = @moonbit-dsp.magnitude_spectrum(x)
  // 50 Hz at fs 1024, N 512 -> bin 25 (frequency resolution 2 Hz).
  assert_close(spec[25], 512.0, 1.0e-6)
}

///|
test "power spectrum non negative" {
  let x = @moonbit-dsp.white_noise(128, 9UL)
  let p = @moonbit-dsp.power_spectrum(x)
  for k in 0..<p.length() {
    @test.assert_eq(p[k] >= 0.0, true)
  }
}

///|
test "find peaks" {
  let p = @moonbit-dsp.find_peaks([1.0, 3.0, 2.0, 5.0, 4.0, 2.0])
  @test.assert_eq(p.length(), 2)
  @test.assert_eq(p[0], 1)
  @test.assert_eq(p[1], 3)
}

///|
test "top k sorts by value" {
  let t = @moonbit-dsp.top_k([3.0, 1.0, 4.0, 1.0, 5.0], 3)
  @test.assert_eq(t.length(), 3)
  @test.assert_eq(t[0], (4, 5.0))
  @test.assert_eq(t[1], (2, 4.0))
  @test.assert_eq(t[2], (0, 3.0))
}

///|
test "stats mean variance rms" {
  let x = [1.0, 2.0, 3.0, 4.0]
  assert_close(@moonbit-dsp.mean(x), 2.5, 1.0e-12)
  assert_close(@moonbit-dsp.variance(x), 1.25, 1.0e-12)
  assert_close(@moonbit-dsp.variance(x, sample=true), 5.0 / 3.0, 1.0e-12)
  assert_close(@moonbit-dsp.stddev(x), 1.25.sqrt(), 1.0e-12)
  assert_close(@moonbit-dsp.rms([3.0, 4.0]), 12.5.sqrt(), 1.0e-12)
  assert_close(@moonbit-dsp.energy([1.0, 2.0]), 5.0, 1.0e-12)
}

///|
test "normalize scales to unit peak" {
  let x = @moonbit-dsp.normalize([-2.0, 4.0, 1.0])
  assert_close(x[0], -0.5, 1.0e-12)
  assert_close(x[1], 1.0, 1.0e-12)
  assert_close(x[2], 0.25, 1.0e-12)
}

///|
test "max abs" {
  assert_close(@moonbit-dsp.max_abs([-1.0, 2.0, -3.0]), 3.0, 1.0e-12)
}
