# Verilog 工具使用指南（仿真 · 波形 · 综合）

> 配套文档：[VSCode Verilog 环境配置指南](VSCode_Verilog环境配置指南.md)（安装与插件）
> 本指南解决"装好环境之后怎么用"：跑仿真、看波形、读综合结果。
> 文中所有命令均已在本仓库三个实验上实测通过。

## 1. 工具链总览

```
RTL 源码 (.v) ──iverilog 编译──> simv ──vvp 运行──> 终端打印 PASS/FAIL
      │                                    │
      │                                    └──> wave.vcd ──gtkwave──> 波形窗口
      └──yosys 综合──> *_stat.txt（资源统计）+ *_ltp.txt（最长路径）
```

| 工具 | 角色 | 常用命令 |
| ---- | ---- | ---- |
| Icarus Verilog (`iverilog`) | 编译 Verilog | `iverilog -g2005 -o simv <源文件...> <tb文件>` |
| `vvp` | 运行仿真 | `vvp simv` |
| GTKWave (`gtkwave`) | 查看波形 | `gtkwave wave.vcd wave.gtkw` |
| Yosys (`yosys`) | 逻辑综合 | `yosys synth.ys` |

> 编译务必加 `-g2005` 显式指定 Verilog-2005 标准，避免 generate 块等语法因工具默认标准不同而报错。

## 2. 各实验命令速查

| 实验 | 编译+仿真（在 `lab_X/sim/` 下） | 综合（在 `lab_X/syn/` 下） |
| ---- | ---- | ---- |
| Lab 1 | `iverilog -g2005 -o simv ../rtl/ADDER.v ../rtl/ADDER_RCA.v ../tb/tb_ADDER.v` → `vvp simv` | `yosys synth.ys` |
| Lab 2 | `iverilog -g2005 -o simv ../rtl/MULT.v ../rtl/MULT8_WALLACE.v ../rtl/MULT_NAIVE.v ../rtl/CSA.v ../../lab_1/rtl/ADDER.v ../tb/tb_MULT.v` → `vvp simv` | `yosys synth.ys` |
| Lab 3 复用版 | `iverilog -g2005 -o simv ../rtl/MULT.v ../rtl/PE.v ../../lab_2/rtl/MULT8_WALLACE.v ../../lab_2/rtl/CSA.v ../../lab_1/rtl/ADDER.v ../tb/tb_MULT.v` → `vvp simv` | `yosys synth.ys` |
| Lab 3 独立版 | `iverilog -g2005 -o simv ../rtl/MULT.v ../rtl/PE.v ../tb/tb_MULT.v` → `vvp simv` | `yosys synth.ys` |

仿真成功的标志是终端打印 `RESULT: PASS`；失败会逐条打印 `[ERROR] ...` 明细。

各实验预期终端输出（自检基准，应逐字一致）：

```text
── Lab 1 ──────────────────────────────────────
Total vectors : 10010
Kogge-Stone   : 0 errors
Ripple-Carry  : 0 errors
RESULT: PASS
── Lab 2 ──────────────────────────────────────
Total vectors : 65545
Errors        : 0
RESULT: PASS
── Lab 3（复用版 / 独立版输出相同）────────────
[CHECK] matrix m0: res correct at t=10
[CHECK] matrix m1: res correct at t=14
[CHECK] matrix m2: res correct at t=10
Errors : 0
RESULT: PASS
```

（首行 `VCD info: dumpfile wave.vcd opened for output.` 与末行 `$finish called at ...` 均会出现，属正常。）

## 3. Testbench 说明

三个实验的 tb 已随仓库提供，**不需要额外设置**，均具备：

- **自检**：内置黄金模型（行为级参考），自动比对并打印 `RESULT: PASS/FAIL`
- **波形输出**：`$dumpfile("wave.vcd"); $dumpvars(0, tb_xxx);`，`vvp` 运行后即在当前目录生成 `wave.vcd`
- 激励覆盖：Lab 1（10 定向 + 10000 随机）、Lab 2（9 定向 + 65536 全量遍历）、Lab 3（单发 / II=4 连续流水 / 换权重三场景）

学生自行编写 tb 的要点：

1. `timescale 与时钟：` `timescale 1ns/1ps`，`always #5 clk = ~clk;`
2. 组合逻辑 DUT 加激励后 `#1` 再采样（等输出稳定）
3. 时序 DUT 在 `negedge` 驱动输入、`posedge` 后 `#1` 检查输出
4. 结尾必须 `$finish;`，否则 `vvp` 不停下来
5. 自检比对用 `!==`（能把 X/Z 也判为错误），不要只用 `!=`

## 4. GTKWave 查看波形

### 4.1 打开后是空白？——这是正常的

GTKWave 打开 vcd 后**默认不加载任何信号**，左侧是空的信号窗。这不是故障。
两种加载信号的方法：

**方法 A（推荐）：加载随附保存文件** —— 每个实验的 `sim/` 目录都带一个 `wave.gtkw`，已配好推荐信号分组：

```bash
cd lab_3_reuse/sim
gtkwave wave.vcd wave.gtkw      # 打开即有完整波形视图
```

或在已打开的 GTKWave 里：**File → Read Save File** 选择 `wave.gtkw`。

**方法 B：手动添加**：

1. 左上 **SST** 面板逐层展开模块树（如 `tb_MULT` → `u_dut`）
2. 中间信号列表选中信号（可 Ctrl/Shift 多选），拖入右侧黑色波形区（或点 **Insert**）
3. 建议先加 `clk`、`rst_n` 等控制信号，再加数据总线

### 4.2 常用操作

| 操作 | 方法 |
| ---- | ---- |
| 缩放 | 工具栏放大镜，或 **Zoom → Zoom Fit**（一键看全程，快捷键 `F`） |
| 改数值进制 | 选中信号右键 → **Data Format → Decimal**（总线建议十进制/十六进制） |
| 时间测量 | 左键点击波形放主标记（红），中键/右键放副标记，顶部显示时间差 |
| 总线展开 | 选中总线右键 → **Expand**（看每个 bit） |
| 保存视图 | **File → Write Save File**，下次 `Read Save File` 直接恢复 |
| 查找边沿 | 选中信号，工具栏左右箭头跳到上一个/下一个跳变沿 |

### 4.3 实验三示例波形解读

下图由 `lab_3_reuse/sim/wave.vcd` 实际数据渲染（与本仓库 tb 完全一致）：

![Lab3 波形示例](images/lab3_waveform_example.png)

- `load` 拉高 1 拍装入权重 K1（单位矩阵），同时 `t_run` 清零
- `t_run` 逐拍计数，到 10 后饱和；`capture_en` 在 `t_run==10 且 phase==2` 时拉高一个周期
- **m0**：`t=145ns`（第 10 拍末）`res` 整组锁存，`y00: 0→1`、`y33: 0→16`（K1 是单位矩阵，Y=X0，X0 元素为 1..16 ✓）
- **m1**：第二个矩阵紧跟着流水注入（II=4），`t=185ns` 更新为 X1 的结果（`y00→13`、`y33→157`）
- **m2**：第二次 `load` 换权重 K2，旧部分和被清空，`t=305ns` 得到 K2·X2（`y00→532`、`y33→700`）

> 本波形已做逐字段程序化比对：3 个锁存时刻 × 16 个输出字段全部等于黄金模型，波形数据可信。

## 5. Yosys 综合结果解读

在各实验 `syn/` 目录执行 `yosys synth.ys` 后生成两类文件：

| 文件 | 内容 | 关注点 |
| ---- | ---- | ---- |
| `*_stat.txt` | 资源统计 | `cells` 总数（面积代理指标）、`$_AND_`/`$_XOR_` 等门类型明细、`$_SDFF_` 触发器数量（时序逻辑规模） |
| `*_ltp.txt` | 最长拓扑路径 | `Longest topological path (length=N)` —— N 即关键路径级数，下方逐级列出经过的每个门 |

Lab 1 实测样例（`ks_stat.txt` / `ks_ltp.txt` 节选）：

```text
=== ADDER ===
      133 wires
      147 cells
       43   $_AND_
       60   $_NAND_
       ...
Longest topological path in ADDER (length=27):
```

典型结论（本仓库实测，`synth -flatten`）：

| 对比 | cells | 最长路径 | 结论 |
| ---- | ---- | ---- | ---- |
| Kogge-Stone vs 串行加法器 | 147 vs 95 | **27 vs 39** | 前缀结构用 55% 面积换 31% 路径缩短 |
| Wallace vs 朴素连加乘法器 | 381 vs 338 | **28 vs 37** | 压缩树对数深度 vs 连加线性深度 |
| Lab 3 脉动阵列 | 8547 | **37（单拍）** | 流水寄存器把关键路径限制在单个 PE 内，与阵列规模无关 |

> **注意**：综合脚本必须 `synth -top XXX -flatten`（先整平再让 ABC 全局优化）。
> 若写成 `synth; flatten`（先映射后整平），ABC 无法跨模块边界优化，LTP 会明显失真偏大。
>
> 想看综合后原理图：`yosys -p "read_verilog ../rtl/xxx.v; synth -top XXX -flatten; show"`。

## 6. VSCode 一键任务（推荐给学生）

把 [templates/.vscode](templates/.vscode) 目录复制到任一实验根目录（与 `rtl/`、`sim/` 同级），
按 `Ctrl+Shift+B` 即可调用三个预置任务：

| 任务 | 动作 |
| ---- | ---- |
| 编译并仿真 | iverilog 编译 + vvp 运行，终端看 PASS/FAIL |
| 查看波形 | gtkwave 打开 `wave.vcd` |
| 逻辑综合 | yosys 运行 `syn/synth.ys` |

无需记忆命令，适合课堂统一分发。

## 7. 常见问题 FAQ

| 现象 | 原因与解决 |
| ---- | ---- |
| GTKWave 双击闪退、无窗口（退出码 0xC0000135） | PATH 只加了 `bin` 缺 `lib`，两个都要加，并重开终端 |
| GTKWave 打开后一片空白 | 正常默认行为，需加载信号：用 `wave.gtkw`（4.1 方法 A）或手动拖 |
| `GLib-GIO-WARNING: dbus not found` | 无害警告，忽略 |
| iverilog 报 `syntax error` 且指向 generate/always | 漏加 `-g2005`；或 `input` 等关键字被用作标识符（改名 `input_data`） |
| lint 提示 `Unknown module type` | 编译时漏带了被实例化的源文件（注意 Lab 2/3 依赖 `../../lab_1/rtl/ADDER.v` 等共享文件） |
| 波形全是 X | 时序逻辑没复位：检查 `rst_n` 是否先拉低若干拍再释放 |
| `vvp` 运行不退出 | tb 缺 `$finish;` |
| 终端提示命令不存在 | PATH 未生效：**关闭终端重开**；仍不行检查路径是否含中文/空格 |
| `synth` 后 LTP 与理论层数对不上 | 检查是否用了 `synth -flatten`；ABC 重构后门级路径与理论层数本就不是一一对应 |
| ABC 阶段报 `return code -2`、综合中断 | 终端激活了 conda `(base)` 环境，其 MinGW 动态库与 `yosys-abc.exe` 冲突；`conda deactivate` 后重跑，或新开不激活 conda 的终端 |

## 8. 相关文档

- [VSCode Verilog 环境配置指南](VSCode_Verilog环境配置指南.md)：安装、PATH、插件
- [实验手册英文版](../../Requirement/DigtalLabManual_EN.md)、[中英术语表](../../Requirement/Terminology_CN_EN.md)
- 各实验目录 README：接口约定、验证结果、复现命令