# 专业术语中英文对照表
# Glossary of Technical Terms (Chinese–English)

> 适用文档：《Lab1 实验手册》英文版（Lab1_Lab_Manual_EN.md）
> 覆盖范围：课程背景、实验一（并行前缀进位加法器）、实验二（移位相加乘法器）、实验三（全流水脉动阵列矩阵乘法器）

---

## 1. 课程与体系结构通用术语 (Course & Architecture — General)

| 中文 | English | 缩写 / 备注 |
| ---- | ------- | ----------- |
| 数字处理器 | Digital Processor | |
| AI 芯片 | AI Chip | |
| 算术电路 | Arithmetic Circuit | |
| 算术单元 | Arithmetic Unit | |
| 算术逻辑单元 | Arithmetic Logic Unit | ALU |
| 数字信号处理器 | Digital Signal Processor | DSP |
| 通用处理器 | General-Purpose Processor | |
| 神经网络 | Neural Network | |
| 大语言模型 | Large Language Model | LLM |
| 线性投影 | Linear Projection | |
| 前馈网络 | Feed-Forward Network | FFN |
| 注意力（机制） | Attention (Mechanism) | |
| 矩阵乘法 | Matrix Multiplication | MatMul |
| 张量运算 | Tensor Operation | |
| 矩阵乘法单元 | Matrix Multiply Unit | MXU |
| 张量处理单元 | Tensor Processing Unit | TPU |
| 乘加（运算） | Multiply-Accumulate | MAC |
| 乘加数据通路 | MAC Datapath | |
| 点积 | Dot Product | |
| 性能、面积和功耗 | Performance, Area, and Power | PPA（设计权衡三要素） |
| 位级运算 | Bit-level Operation | |
| 算术模块 | Arithmetic Module | |
| 阵列架构 | Array Architecture | |
| 仿真验证 | Simulation-based Verification | |
| 综合 | Synthesis | |
| 时序 | Timing | |
| 工作频率 | Operating Frequency | |
| 关键路径 | Critical Path | |
| 吞吐率 | Throughput | |
| 延迟 | Latency | |
| 数据通路 | Datapath | |
| 组合逻辑 | Combinational Logic | |
| 传播延迟 | Propagation Delay | |
| 门级延迟 | Gate-level Delay | |
| 扇出 | Fanout | |
| 布线 / 互连 | Routing / Interconnect | |
| 规则布局 | Regular Layout | |
| 位宽 | Bit Width | |
| 操作数 | Operand | |
| 数据复用 | Data Reuse | |
| 量化（模型） | Quantization / Quantized Model | |
| 缩放因子 | Scaling Factor | |
| 零点 | Zero Point | 量化数值规则 |
| 低精度 | Low-Precision | |
| （AI）推理 | (AI) Inference | |
| 可复用模块 | Reusable Module | |

## 2. 实验一：加法器术语 (Lab 1 — Adder)

| 中文 | English | 缩写 / 备注 |
| ---- | ------- | ----------- |
| 并行前缀进位加法器 | Parallel-Prefix (Carry) Adder | 注意与 PPA 缩写区分 |
| 串行 / 行波进位加法器 | Ripple-Carry Adder | RCA |
| 进位传播加法器 | Carry-Propagate Adder | CPA |
| 进位传播 | Carry Propagation | |
| 全加器 | Full Adder | FA |
| 进位 | Carry | |
| 输入进位（进位输入） | Carry-in | `cin` |
| 输出进位（进位输出） | Carry-out | `cout` |
| 进位产生信号 | Carry-Generate Signal | $g_i$ |
| 进位传播信号 | Carry-Propagate Signal | $p_i$ |
| 区间产生信号 | Group/Block Generate Signal | $G_{i:j}$ |
| 区间传播信号 | Group/Block Propagate Signal | $P_{i:j}$ |
| 区间合并运算 | (Interval) Merge Operator | $\circ$，满足结合律 |
| 结合律 | Associativity / Associative Law | |
| 逐位递推 | Bit-by-bit Recurrence | |
| 树形前缀网络 | Tree-structured Prefix Network | |
| 递归倍增 | Recursive Doubling | Kogge–Stone 的理论来源 |
| 前缀合并层 | Prefix-Merge Level / Stage | |
| 逻辑深度 | Logic Depth | |
| 串行依赖 | Serial Dependency | |
| 依赖链 | Dependency Chain | |
| 进位链 | Carry Chain | |
| Sklansky 结构 | Sklansky Structure | 前缀加法器拓扑之一 |
| Kogge–Stone 结构 | Kogge–Stone Structure | 前缀加法器拓扑之一 |
| Brent–Kung 结构 | Brent–Kung Structure | 前缀加法器拓扑之一 |
| Han–Carlson 结构 | Han–Carlson Structure | 前缀加法器拓扑之一 |
| 输入预处理 | Input Preprocessing | |
| 最终求和 | Final Summation | |

## 3. 实验二：乘法器术语 (Lab 2 — Multiplier)

| 中文 | English | 缩写 / 备注 |
| ---- | ------- | ----------- |
| 移位相加乘法器 | Shift-and-Add Multiplier | |
| 部分积 | Partial Product | |
| 华莱士树 | Wallace Tree | |
| 进位保存加法器 | Carry-Save Adder | CSA（3 输入压缩为 2 输出） |
| 压缩 / 归约 | Compression / Reduction | |
| 压缩树 | Compression Tree | |
| 压缩层 | Compression Layer | |
| 部分和 | Partial Sum | |
| 无符号整数 | Unsigned Integer | UINT8（8 位无符号整数） |
| 按位与 | Bitwise AND | |
| 左移 | Left Shift | $\ll$ |
| 截断 | Truncation | |
| 零扩展 | Zero-Extension | |
| 位权 | Bit Weight | |
| 乘法数据通路 | Multiplier Datapath | |
| 压缩单元 | Compression Cell | |
| （乘法器）拓扑 | (Multiplier) Topology | |
| 最终加法 | Final Addition | |

## 4. 实验三：脉动阵列与流水线术语 (Lab 3 — Systolic Array & Pipeline)

| 中文 | English | 缩写 / 备注 |
| ---- | ------- | ----------- |
| 全流水 | Fully Pipelined | |
| 脉动阵列 | Systolic Array | |
| 脉动阵列矩阵乘法器 | Systolic-Array Matrix Multiplier | |
| 处理单元 | Processing Element | PE |
| 固定权重（数据流） | Weight-Stationary | WS |
| 数据流 | Dataflow | |
| 流水线 | Pipeline | |
| 流水线寄存器 | Pipeline Register | |
| （时钟）节拍 | Clock Beat / Cycle | |
| 错位注入 | Skewed / Staggered Injection | 输入按行错位送入 |
| 数据对齐 | Data Alignment | |
| 边界采样 | Boundary Sampling | |
| 输出有效（时刻） | Output-Valid (Timing) | |
| 权重装载 | Weight Loading | |
| 装载控制 | Load Control | `load` 信号 |
| 复位 | Reset | `rst_n`（低电平有效） |
| 权重驻留 | Resident Weights / Weight Residency | |
| 换权重开销 | Weight-Swapping Overhead | |
| （流水线）填充 | Pipeline Fill | |
| （流水线）排空 | Pipeline Drain / Flush | |
| 阵列利用率 | Array Utilization | |
| 输入调度 | Input Scheduling | |
| 持续吞吐率 | Sustained Throughput | |
| 理想峰值 | Ideal Peak (Throughput) | |
| 标量乘法 | Scalar Multiplication | |
| 乘加更新 | MAC Update | |
| 存储访问 | Memory Access | |
| 数据供应 | Data Supply | |
| 算子 | Operator | Op |
| 调度 | Scheduling | |
| 数据总线 | Data Bus | |
| 元素排列 | Element Ordering | |
| 标识符 | Identifier | Verilog 命名 |
| 关键字 | Keyword | 如 `input` 为 Verilog 保留字 |

## 5. 关键人物与经典文献 (Key People & Classic References)

| 中文 | English | 备注 |
| ---- | ------- | ---- |
| 彼得·M·科格 | Peter M. Kogge | Kogge–Stone 前缀加法器（1973） |
| 哈罗德·S·斯通 | Harold S. Stone | 同上 |
| 理查德·P·布伦特 | Richard P. Brent | Brent–Kung 加法器（1982） |
| 孔祥重 | H. T. Kung | 脉动阵列提出者之一 |
| 查尔斯·E·雷瑟森 | Charles E. Leiserson | 脉动阵列提出者之一 |
| C. S. 华莱士 | C. S. Wallace | 华莱士树快速乘法（1964） |
| 《面向 VLSI 的脉动阵列》 | *Systolic Arrays (for VLSI)* | CMU-CS-79-103，1978 年初稿 |
| 脉动阵列架构图解（Telesens 教程） | *Systolic Architectures* (Telesens) | 脉动阵列数据流图解教程，实验三设计参考 [8] |