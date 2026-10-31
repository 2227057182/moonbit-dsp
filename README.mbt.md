# moonbit-dsp

**moonbit-dsp** 是一个**零外部依赖、纯 MoonBit 实现的通用数字信号处理（DSP）基础库**。

它提供了一组可独立复用、互相组合的底层能力：复数运算、FFT/DCT 变换（含 DFT 与迭代 radix-2 FFT）、卷积与相关、FIR/IIR 滤波器设计、窗函数、波形生成（确定性白噪声等）、频谱分析与信号统计。所有代码均为纯 MoonBit 编写，不依赖任何第三方包，`moon check` 零警告、39 个单元测试全部通过（含与 O(N²) DFT 对照的 FFT 一致性验证、Parseval 定理守恒验证、卷积交换律与已知结果对照、滤波器频率响应验证、主导频率检测端到端验证）。

它是音频、振动、传感器、通信、金融时序等各类信号处理应用可以直接引用的基础构件——这正是其通用性与复用价值所在。

---

## 为什么做这个库

- **通用性强**：不绑定任何具体业务场景。FFT、卷积、滤波、窗函数、统计是几乎所有信号处理任务的公共底层，可以被音频工具、科学计算、嵌入式数据分析等任何项目复用。
- **高技术含量**：实现了教科书级算法并验证正确性——radix-2 迭代 FFT（比特反转 + 蝶形）、窗口法 FIR 设计（DC 增益归一）、双线性变换 Butterworth IIR 设计、半谱幅值谱/功率谱（含非 DC/Nyquist bin 幅值补偿）。
- **零依赖、纯 MoonBit**：可直接作为他人项目的依赖引入，验证了 MoonBit 标准库表达数值算法与工程代码的能力。
- **质量可验证**：39 项单元测试覆盖数学性质（Parseval 定理、卷积交换律、窗对称性、噪声确定性）与数值对照（FFT vs DFT、滤波器频响、主导频率检测）。

---

## 快速开始

### 1. 作为依赖引入

在 `moon.mod` 中声明依赖（发布后可 `moon add 2227057182/moonbit-dsp`），然后在 `moon.pkg` 中导入：

```moon
import {
  "2227057182/moonbit-dsp",
}
```

### 2. 一段最小示例

```moon
fn main {
  // 生成 8000 Hz 采样率、频率 100 Hz、时长 0.25 s 的正弦波
  let x = @moonbit-dsp.sine_wave(2000, 100.0, 8000.0)
  // 加 Hann 窗抑制频谱泄漏
  let w = @moonbit-dsp.apply_window(x, @moonbit-dsp.WindowType::Hann)
  // 计算幅值谱，找到主导频率
  let (freq, mag) = @moonbit-dsp.dominant_frequency(w, 8000.0)
  println("dominant frequency: \{freq.to_string()} Hz, magnitude: \{mag.to_string()}")
}
```

### 3. 运行测试

```text
moon test
```

预期输出：`Total tests: 39, passed: 39, failed: 0.`

### 4. 命令行演示程序

仓库附带一个零依赖 CLI 演示（`cmd/main`），走「波形生成 → 可选 FIR 低通 → 可选加窗 → FFT 频谱分析」完整链路：

```text
# 正弦波频谱分析（打印前 3 个谱峰 + 主导频率 + 统计量）
moon run cmd/main -- --wave sine --freq 50 --stats

# 白噪声频谱（确定性 LCG，种子固定）
moon run cmd/main -- --wave noise --seed 42 --peaks 2

# 锯齿波经过 FIR 低通（归一化截止 0.1）+ Hann 窗后的频谱
moon run cmd/main -- --wave sawtooth --freq 100 --lowpass 0.1 --window hann --peaks 3
```

全部选项见 `moon run cmd/main -- --help`。

---

## 模块总览

| 模块 | 文件 | 提供的功能 |
|---|---|---|
| Complex | `complex.mbt` | 复数运算（加/减/乘/除、共轭、模、相位） |
| FFT | `fft.mbt` | 迭代 radix-2 FFT、O(N²) DFT 参考实现、2 的幂对齐、FFT 与 DFT 一致性 |
| Conv | `conv.mbt` | 线性卷积、互相关、自相关 |
| Window | `window.mbt` | 矩形/Hann/Hamming/Blackman 窗、加窗 |
| Filter | `filter.mbt` | 窗函数法 FIR 低通设计、一阶 IIR 低通、二阶 Butterworth IIR 低通（双线性变换） |
| Waveform | `waveform.mbt` | 正弦/方波/三角波/锯齿波/确定性白噪声（LCG 64） |
| Spectrum | `spectrum.mbt` | 幅值谱/功率谱（半谱 + 幅值补偿）、主导频率、峰值查找、Top-K |
| Stats | `stats.mbt` | 均值、方差、标准差、RMS、能量、最大绝对值、归一化 |

---

## API 说明

### 复数 `@moonbit-dsp.Complex`

```moon
Complex::new(re : Double, im : Double) -> Complex
Complex::zero() / Complex::one()
add / sub / mul / div / conj / abs / phase / scale
```

用于 FFT 内部运算，也可独立作为复数的通用表示。

### 窗函数 `@moonbit-dsp.WindowType`

```moon
pub(all) enum WindowType { Rectangular, Hann, Hamming, Blackman }

window(WindowType, Int) -> Array[Double]        // 生成窗系数
apply_window(Array[Double], WindowType) -> Array[Double]
hann_window(Int) / hamming_window(Int) / blackman_window(Int) / rectangular_window(Int)
```

### FFT

```moon
fft(Array[Double]) -> Array[Complex]        // 迭代 radix-2，长度须为 2 的幂
dft(Array[Double]) -> Array[Complex]        // O(N²) 参考实现
is_power_of_two(Int) -> Bool
next_power_of_two(Int) -> Int               // 对非 2 幂输入自动补零对齐
```

### 卷积与相关

```moon
convolve(Array[Double], Array[Double]) -> Array[Double]   // 线性卷积
correlate(Array[Double], Array[Double]) -> Array[Double]  // 互相关
autocorrelate(Array[Double]) -> Array[Double]
```

### 滤波器

```moon
fir_lowpass_coeffs(cutoff : Double, taps : Int, window : WindowType) -> Array[Double]  // 窗口法，DC 增益归一
fir_filter(Array[Double], Array[Double]) -> Array[Double]                               // 直接卷积滤波
iir_lowpass_1(Array[Double], alpha : Double) -> Array[Double]                           // 一阶 IIR
butterworth_lowpass_2(cutoff : Double) -> IirCoeffs2                                    // 二阶 Butterworth（双线性变换）
iir_filter_2(Array[Double], IirCoeffs2) -> Array[Double]                                // 直接 II 型实现
```

`cutoff` 均为归一化截止频率（0, 0.5），`0.5` 对应 Nyquist。

### 波形生成

```moon
sine_wave(n : Int, freq : Double, sample_rate : Double, phase~ : Double) -> Array[Double]
square_wave(n : Int, freq : Double, sample_rate : Double, duty~ : Double) -> Array[Double]
triangle_wave / sawtooth_wave（签名同上）
white_noise(n : Int, seed : UInt64) -> Array[Double]   // 64 位 LCG，确定性可复现；seed = 0 映射为 1
```

### 频谱分析

```moon
magnitude_spectrum(Array[Double]) -> Array[Double]  // 半谱；非 DC/Nyquist bin 幅值 ×2
power_spectrum(Array[Double]) -> Array[Double]
dominant_frequency(Array[Double], sample_rate : Double) -> (Double, Double)
find_peaks(Array[Double], min_height : Double, min_distance : Int) -> Array[(Int, Double)]
top_k(Array[Double], k : Int) -> Array[(Int, Double)]
```

### 统计

```moon
mean / variance(x, sample~ : Bool) / stddev / rms / energy / max_abs / normalize
```

---

## 设计说明

- **零外部依赖**：仅使用 `moonbitlang/core`（math / builtin）。库本体与 CLI 均不引入任何第三方包，便于评审与复用。
- **确定性**：白噪声使用 64 位 LCG 且显式接受种子，同一输入同一输出，方便测试与复现实验。
- **性能分层**：`fft` 为迭代 radix-2（O(N log N)），`dft` 作为 O(N²) 参考，测试中以 1e-9 容差验证两者一致；`fft_inplace` 为私有实现，对非 2 幂输入由 `pad_to_power_of_two` 自动补零。
- **工程规范**：全程 `moon check --deny-warn` 零警告（修复了包括 `pub` 冗余修饰、`Array::new` 废弃、`var` 废弃、枚举只读性等语言迁移问题）；浮点断言使用自写 `assert_close`（绝对容差），不做脆弱的精确相等比较。
- **测试策略**：39 项测试分为四类——数学恒等式（Parseval 定理、卷积交换律、窗对称性、DFT/FFT 一致性）、已知数值对照（卷积、复数运算、统计量）、频域特性（FIR DC 增益 = 1、Butterworth 频响衰减、主导频率端到端检出）、随机数性质（确定性、均值 ≈ 0）。

---

## 目录结构

```text
moonbit-dsp/
├── moon.mod                 # 包配置（Apache-2.0, preferred_target = wasm）
├── moon.pkg                 # 库包声明
├── complex.mbt              # 复数
├── fft.mbt                  # FFT / DFT
├── conv.mbt                 # 卷积与相关
├── window.mbt               # 窗函数
├── filter.mbt               # FIR / IIR 滤波器
├── waveform.mbt             # 波形生成
├── spectrum.mbt             # 频谱分析
├── stats.mbt                # 统计
├── moonbit-dsp_test.mbt     # 39 项单元测试
└── cmd/main/                # CLI 演示（moon run cmd/main -- ...）
```

---

## 路线图（后续可扩展）

- `fft` 支持实数输入的对称优化、逆变换（IFFT）
- 更多窗函数（Bartlett、Kaiser 等）与窗函数特征参数（主瓣宽度、旁瓣衰减）
- FIR 等纹波（Parks-McClellan）与 IIR 高阶设计、频域滤波
- 分帧 / 短时傅里叶变换（STFT）、频谱图
- 更多波形（chirp、指数衰减等）与确定性随机分布（高斯噪声 Box-Muller）

---

## License

Apache-2.0
