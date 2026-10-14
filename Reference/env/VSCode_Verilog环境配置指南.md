# VSCode Verilog 开发环境配置指南

> 适用课程：数字电路实验（BUAA · 2026 秋 · 41 系）
> 覆盖实验：实验一（19 位并行前缀加法器）、实验二（8 位 Wallace 树乘法器）、实验三（4×4 脉动阵列）
> 本指南所有步骤已在 Windows 11 + VSCode 1.136 上实际验证通过。
> 配套文档：[Verilog 工具使用指南](Verilog工具使用指南.md)（装好环境后：仿真、波形、综合的用法）

---

## 0. 结论

VSCode + 开源 EDA 工具链可以完整覆盖本课程三个实验的 **代码编写、语法检查、功能仿真、波形调试、逻辑综合** 全部需求，无需安装 Quartus / Vivado。

| 能力 | 是否覆盖 | 说明 |
| ---- | ---- | ---- |
| Verilog-2001 RTL 编码、语法实时检查 | ✅ | mshr-h 插件 + iverilog lint |
| 代码自动格式化 | ✅ | Verible 插件 |
| 行为级功能仿真 + VCD 波形 | ✅ | Icarus Verilog + GTKWave |
| 逻辑综合、资源/延迟统计 | ✅ | Yosys |
| generate 块、参数化、多模块联合仿真 | ✅ | |
| FPGA 布局布线、上板下载 | ❌ | 本课程三个实验不需要 |

---

## 1. 安装底层 EDA 工具链（必做）

VSCode 本身不具备编译仿真能力，必须先安装命令行工具。

### 1.1 Windows（推荐，已实测）

使用 **OSS CAD Suite** 绿色免安装包，一套包含全部所需工具，**不需要管理员权限**。

1. 下载：GitHub 搜索 `YosysHQ/oss-cad-suite-build`，在 Releases 中下载最新
   `oss-cad-suite-windows-x64-YYYYMMDD.tgz`（约 575 MB）
2. 解压到**纯英文、无空格**路径，例如 `D:\Tools\oss-cad-suite`
   （Windows 10/11 可直接用系统自带 tar 解压：`tar -xzf oss-cad-suite-*.tgz -C D:\Tools`）
3. 将以下两个目录加入**用户环境变量 PATH**：
   - `D:\Tools\oss-cad-suite\bin`
   - `D:\Tools\oss-cad-suite\lib`
4. **关闭并重新打开** VSCode 终端（PATH 对已打开的终端不生效）

> 备选方案：`winget install --id Icarus.Verilog -e`（仅含 iverilog + GTKWave，安装时需在 UAC 弹窗点"是"；不含 Yosys）。

### 1.2 Linux（Ubuntu / Debian）

```bash
sudo apt update
sudo apt install iverilog gtkwave yosys -y
```

### 1.3 macOS

```bash
brew install icarus-verilog gtkwave yosys
```

### 1.4 验证工具链

打开 VSCode 终端（`` Ctrl+` ``），依次执行，全部输出版本号即正常：

```bash
iverilog -v        # Icarus Verilog 编译器
vvp -V             # 仿真运行器
yosys -V           # 综合工具（注意是大写 -V）
gtkwave --version  # 波形查看器
```

预期输出（本机实测，版本号随套件更新略有差异，**能打印出版本行即正常**）：

```text
$ iverilog -v
Icarus Verilog version 14.0 (devel) (s20260301-542-g04cc49350-dirty)
...
$ yosys -V
Yosys 0.69+274 (git sha1 7513f8df8 Release GNU /usr/bin/x86_64-w64-mingw32-g++ 15.2.1)
```

> 提示"不是内部或外部命令"→ PATH 未生效：检查环境变量是否写入、路径是否含中文/空格、是否重开了终端。

> **GTKWave 双击/启动后闪退、无任何窗口**（实际验证）：退出码 `0xC0000135`（-1073741515），即 **DLL 缺失**。原因是 PATH 只加了 `bin` 没加 `lib`——GTKWave 是 MinGW 程序，运行所需的 GTK/TCL 动态库在 `lib` 目录。**`bin` 和 `lib` 必须同时加入 PATH**，然后重开终端。启动时若打印 `GLib-GIO-WARNING: win32 session dbus binary not found` 属正常现象，不影响使用。

---

## 2. 安装 VSCode 插件（必装 3 个）

| 插件 | 扩展 ID | 作用 |
| ---- | ---- | ---- |
| Verilog-HDL/SystemVerilog | `mshr-h.VerilogHDL` | 语法高亮、补全、定义跳转、iverilog 实时 lint |
| Verible | `chipsalliance.verible` | 代码自动格式化、风格检查 |
| Error Lens | `usernamehw.errorlens` | 行内直接显示错误，不用翻问题面板 |

命令行一键安装：

```bash
code --install-extension mshr-h.VerilogHDL
code --install-extension chipsalliance.verible
code --install-extension usernamehw.errorlens
```

---

## 3. 环境全链路验证（必做）

用仓库自带的 4 位加法器示例验证「编译 → 仿真 → 波形 → 综合」全链路。
示例位于 [`Reference/env/test_adder/`](test_adder/)：

```
test_adder/
├── rtl/adder4.v      # 设计代码
└── tb/tb_adder4.v    # 测试激励（含 $dumpfile 波形输出）
```

在 `test_adder/` 目录下打开终端执行：

```bash
# 1. 编译（-g2005 显式指定 Verilog-2005 标准，避免默认标准差异）
iverilog -g2005 -o simv rtl/adder4.v tb/tb_adder4.v

# 2. 运行仿真（终端打印 "Simulation finished"，生成 wave.vcd）
vvp simv

# 3. 查看波形
gtkwave wave.vcd
```

第 1 步编译成功**没有任何输出**，属正常现象。第 2 步预期终端输出（逐字对照）：

```text
VCD info: dumpfile wave.vcd opened for output.
Simulation finished check waveform.
tb/tb_adder4.v:37: $finish called at 40000 (1ps)
```

第 3 步 GTKWave 成功启动的标志：弹出图形窗口（标题栏含 `wave.vcd`），左侧信号树可展开 `tb_adder4`；启动时终端打印 `GLib-GIO-WARNING` 属正常。

GTKWave 中点击左侧 `tb_adder4`，全选信号点 `Append`，应看到：

| 时刻 | a | b | cin | sum | cout |
| ---- | - | - | --- | --- | ---- |
| 10 ns | 3 | 5 | 0 | 8 | 0 |
| 20 ns | 15 | 1 | 0 | 0 | 1 |
| 30 ns | 12 | 7 | 1 | 4 | 1 |

```bash
# 4. 综合测试（输出门级资源统计，预期 12 个 NAND + 8 个 XOR）
yosys -p "read_verilog rtl/adder4.v; synth; stat"
```

第 4 步预期输出（统计段，逐字对照）：

```text
3. Printing statistics.
=== adder4 ===
       20 wires
       20 cells
       12   $_NAND_
        8   $_XOR_
```

四步全部通过即说明环境完全可用。

---

## 4. 工程规范与 VSCode 配置模板

### 4.1 统一工程目录结构

每个实验统一如下结构（本仓库 lab_1 / lab_2 / lab_3 已预建）：

```
lab1_adder/
├── rtl/    # 可综合 RTL 代码（提交核心）
├── tb/     # 测试激励
├── sim/    # 仿真产物（已加入 .gitignore，不上传）
├── syn/    # 综合脚本与结果
└── doc/    # 实验报告
```

### 4.2 一键任务与 lint 配置模板

将 [`templates/.vscode/`](templates/.vscode/) 整个复制到实验工程根目录：

- **`tasks.json`**：`Ctrl+Shift+B` 一键编译并运行仿真；命令面板可触发"查看波形""Yosys 综合"
- **`settings.json`**：保存时自动 Verible 格式化；iverilog 实时 lint（`-g2005 -Wall`）

> **Windows 注意**：`tasks.json` 中多条命令用 `;` 连接，不要用 `&&`（PowerShell 5.1 不支持 `&&`）。

### 4.3 Git 管理

仿真产物（`simv`、`*.vcd`、`*.out`）与 `lab_*/sim/` 内容已在仓库 `.gitignore` 中忽略，提交代码时不会带入。

---

## 5. 常见问题（高发）

1. **路径/模块名不要出现中文和空格**——Icarus 对中文路径支持不佳。
2. **`input` 是 Verilog 关键字**——实验三端口必须用 `input_data` 等合法标识符。
3. **Testbench 开头必须声明** `` `timescale 1ns/1ps ``，否则时序单位错误。
4. Verilog **大小写敏感**，模块名、端口名严格一致。
5. 编译统一加 `-g2005`（课程代码按 Verilog-2001/2005 编写），避免工具默认标准差异导致 generate 块报错。
6. 修改 PATH 后必须**重开终端**才生效。
7. **Yosys 综合到 ABC 阶段报 `return code -2` 或直接失败**（实际验证）：多见于激活了
   Anaconda/Miniconda `(base)` 环境的终端——conda 自带的 MinGW 动态库与套件的
   `yosys-abc.exe` 冲突（退出码 `0xC0000139`）。解决：`conda deactivate` 后重试，
   或新开一个不自动激活 conda 的终端；确保 PATH 中套件 `bin`、`lib` 位于 conda 目录之前。

---

## 6. 本课程环境实测记录（2026-10-12）

| 项目 | 版本 / 路径 | 验证结果 |
| ---- | ---- | ---- |
| OSS CAD Suite | 2026-10-11，`D:\Tools\oss-cad-suite` | ✅ |
| Icarus Verilog | 14.0 (devel) | ✅ 编译通过 |
| vvp | 14.0 | ✅ 仿真、VCD 输出正确 |
| Yosys | （套件内置） | ✅ adder4 综合：12 NAND + 8 XOR，0 problems |
| GTKWave | （套件内置） | ✅ |
| VSCode 插件 | VerilogHDL 1.29.0 / Verible 0.0.4296 / Error Lens 3.29.0 | ✅ |