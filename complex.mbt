///|
/// A double-precision complex number.
///
/// Used as the unit of the discrete Fourier transform and the fast Fourier
/// transform in this library.
pub struct Complex {
  re : Double
  im : Double
}

///|
/// Constructs a complex number from its real and imaginary parts.
pub fn Complex::new(re : Double, im : Double) -> Complex {
  { re, im, }
}

///|
/// The complex number `0 + 0i`.
pub fn Complex::zero() -> Complex {
  { re: 0.0, im: 0.0, }
}

///|
/// The complex number `1 + 0i`.
pub fn Complex::one() -> Complex {
  { re: 1.0, im: 0.0, }
}

///|
/// Adds two complex numbers.
pub fn Complex::add(self : Complex, other : Complex) -> Complex {
  { re: self.re + other.re, im: self.im + other.im, }
}

///|
/// Subtracts `other` from `self`.
pub fn Complex::sub(self : Complex, other : Complex) -> Complex {
  { re: self.re - other.re, im: self.im - other.im, }
}

///|
/// Multiplies two complex numbers.
pub fn Complex::mul(self : Complex, other : Complex) -> Complex {
  {
    re: self.re * other.re - self.im * other.im,
    im: self.re * other.im + self.im * other.re,
  }
}

///|
/// Divides `self` by `other`.
pub fn Complex::div(self : Complex, other : Complex) -> Complex {
  let den = other.re * other.re + other.im * other.im
  {
    re: (self.re * other.re + self.im * other.im) / den,
    im: (self.im * other.re - self.re * other.im) / den,
  }
}

///|
/// Complex conjugate of `self`.
pub fn Complex::conj(self : Complex) -> Complex {
  { re: self.re, im: -self.im, }
}

///|
/// The magnitude (modulus) of `self`.
pub fn Complex::abs(self : Complex) -> Double {
  (self.re * self.re + self.im * self.im).sqrt()
}

///|
/// The phase (argument) of `self` in radians, in `[-pi, pi]`.
pub fn Complex::phase(self : Complex) -> Double {
  @math.atan2(self.im, self.re)
}

///|
/// Scales both components of `self` by `factor`.
pub fn Complex::scale(self : Complex, factor : Double) -> Complex {
  { re: self.re * factor, im: self.im * factor, }
}
