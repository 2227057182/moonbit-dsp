///|
/// CLI errors.
suberror CliError {
  CliError(String)
}

///|
/// Parsed command line options.
struct Options {
  wave : String
  freq : Double
  rate : Double
  duration : Double
  seed : UInt64
  peaks : Int32
  window_type : @moonbit-dsp.WindowType?
  lowpass : Double?
  stats : Bool
  dominant : Bool
}

///|
fn help_text() -> String {
  let text =
    #|moonbit-dsp-cli - generate a test signal and analyze it with moonbit-dsp
    #|
    #|USAGE
    #|  moon run cmd/main -- [OPTIONS]
    #|
    #|OPTIONS
    #|  --wave <type>       sine | square | triangle | sawtooth | noise (default sine)
    #|  --freq <hz>         signal frequency (default 50)
    #|  --rate <hz>         sample rate (default 8000)
    #|  --duration <sec>    signal duration in seconds (default 1)
    #|  --seed <int>        LCG seed for the noise wave (default 42)
    #|  --peaks <k>         number of strongest spectral peaks to print (default 3)
    #|  --window <type>     hann | hamming | blackman | rectangular (default none)
    #|  --lowpass <fc>      FIR low-pass at normalized cutoff in (0, 0.5)
    #|  --stats             print mean / rms / max-abs statistics
    #|  --no-dominant       do not print the dominant frequency
    #|  --help              show this help
  text
}

///|
fn require_next(
  args : ArrayView[String],
  index : Int32,
  flag : String,
) -> String raise CliError {
  if index + 1 >= args.length() {
    raise CliError("Missing value after \{flag}")
  }
  args[index + 1]
}

///|
fn parse_number(
  args : ArrayView[String],
  index : Int32,
  flag : String,
) -> Double raise CliError {
  @string.parse_double(require_next(args, index, flag)) catch {
    _ => raise CliError("Invalid numeric value for \{flag}")
  }
}

///|
fn parse_int_arg(
  args : ArrayView[String],
  index : Int32,
  flag : String,
) -> Int32 raise CliError {
  @string.parse_int(require_next(args, index, flag)) catch {
    _ => raise CliError("Invalid integer value for \{flag}")
  }
}

///|
fn parse_window(s : String) -> @moonbit-dsp.WindowType? raise CliError {
  match s {
    "hann" => Some(@moonbit-dsp.WindowType::Hann)
    "hamming" => Some(@moonbit-dsp.WindowType::Hamming)
    "blackman" => Some(@moonbit-dsp.WindowType::Blackman)
    "rectangular" => Some(@moonbit-dsp.WindowType::Rectangular)
    "none" => None
    _ => raise CliError("Unknown window `\{s}`")
  }
}

///|
fn parse_options(args : ArrayView[String]) -> Options? raise CliError {
  let mut wave = "sine"
  let mut freq = 50.0
  let mut rate = 8000.0
  let mut duration = 1.0
  let mut seed = 42UL
  let mut peaks = 3
  let mut window_type : @moonbit-dsp.WindowType? = None
  let mut lowpass : Double? = None
  let mut stats = false
  let mut dominant = true
  let mut index = 1
  while index < args.length() {
    let arg = args[index]
    match arg {
      "--wave" => {
        wave = require_next(args, index, arg)
        index += 2
      }
      "--freq" => {
        freq = parse_number(args, index, arg)
        index += 2
      }
      "--rate" => {
        rate = parse_number(args, index, arg)
        index += 2
      }
      "--duration" => {
        duration = parse_number(args, index, arg)
        index += 2
      }
      "--seed" => {
        seed = parse_int_arg(args, index, arg).to_uint64()
        index += 2
      }
      "--peaks" => {
        peaks = parse_int_arg(args, index, arg)
        index += 2
      }
      "--window" => {
        window_type = parse_window(require_next(args, index, arg))
        index += 2
      }
      "--lowpass" => {
        lowpass = Some(parse_number(args, index, arg))
        index += 2
      }
      "--stats" => {
        stats = true
        index += 1
      }
      "--no-dominant" => {
        dominant = false
        index += 1
      }
      "--help" | "-h" => {
        println(help_text())
        return None
      }
      _ => raise CliError("Unknown option `\{arg}`; run with --help for usage")
    }
  }
  if rate <= 0.0 || duration <= 0.0 {
    raise CliError("Sample rate and duration must be positive")
  }
  match lowpass {
    Some(cutoff) =>
      if cutoff <= 0.0 || cutoff >= 0.5 {
        raise CliError("Low-pass cutoff must be in (0, 0.5)")
      }
    None => ()
  }
  Some({
    wave,
    freq,
    rate,
    duration,
    seed,
    peaks,
    window_type,
    lowpass,
    stats,
    dominant,
  })
}

///|
fn generate_signal(
  kind : String,
  n : Int32,
  freq : Double,
  rate : Double,
  seed : UInt64,
) -> Array[Double] raise CliError {
  match kind {
    "sine" => @moonbit-dsp.sine_wave(n, freq, rate)
    "square" => @moonbit-dsp.square_wave(n, freq, rate)
    "triangle" => @moonbit-dsp.triangle_wave(n, freq, rate)
    "sawtooth" => @moonbit-dsp.sawtooth_wave(n, freq, rate)
    "noise" => @moonbit-dsp.white_noise(n, seed)
    _ => raise CliError("Unknown wave type `\{kind}`")
  }
}

///|
fn run(args : ArrayView[String]) -> Int32 raise {
  let options = match parse_options(args) {
    Some(options) => options
    None => return 0
  }
  let n = @math.floor(options.duration * options.rate).to_int()
  if n <= 0 {
    raise CliError("Duration too short for the sample rate")
  }
  let signal = generate_signal(
    options.wave,
    n,
    options.freq,
    options.rate,
    options.seed,
  )
  println(
    "Signal: \{options.wave} \{options.freq.to_string()} Hz @ \{options.rate.to_string()} Hz, \{options.duration.to_string()} s (\{n} samples)",
  )
  let filtered = match options.lowpass {
    Some(cutoff) => {
      println("[filter] FIR low-pass, normalized cutoff \{cutoff.to_string()}")
      let h = @moonbit-dsp.fir_lowpass_coeffs(
        cutoff,
        65,
        @moonbit-dsp.WindowType::Hamming,
      )
      @moonbit-dsp.fir_filter(signal, h)
    }
    None => signal
  }
  let analyzed = match options.window_type {
    Some(window_type) => @moonbit-dsp.apply_window(filtered, window_type)
    None => filtered
  }
  let spectrum = @moonbit-dsp.magnitude_spectrum(analyzed)
  let n_fft = @moonbit-dsp.next_power_of_two(analyzed.length())
  let resolution = options.rate / n_fft.to_double()
  println(
    "Spectrum: N=\{n_fft}, frequency resolution \{resolution.to_string()} Hz",
  )
  let tops = @moonbit-dsp.top_k(spectrum, options.peaks)
  println("Top \{tops.length()} spectral peaks:")
  for (idx, mag) in tops {
    let freq = idx.to_double() * resolution
    println(
      "  bin \{idx}  \{freq.to_string()} Hz  magnitude \{mag.to_string()}",
    )
  }
  if options.dominant {
    let (freq, mag) = @moonbit-dsp.dominant_frequency(analyzed, options.rate)
    println(
      "Dominant frequency: \{freq.to_string()} Hz (magnitude \{mag.to_string()})",
    )
  }
  if options.stats {
    println(
      "Stats: mean \{@moonbit-dsp.mean(analyzed).to_string()}, rms \{@moonbit-dsp.rms(analyzed).to_string()}, max-abs \{@moonbit-dsp.max_abs(analyzed).to_string()}",
    )
  }
  0
}

///|
fn main {
  let _ = run(@env.args()) catch {
    error => {
      eprintln("dsp-cli error: \{error}")
      0
    }
  }
}
