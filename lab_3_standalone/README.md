# Lab 3（standalone 独立版）：全流水脉动阵列矩阵乘法器

**Fully Pipelined Systolic Array Matrix Multiplier — Self-Contained Version**

- 设计 4×4 全流水脉动阵列，计算两个 4×4 无符号 8 位整数矩阵之积
- 处理单元（PE）采用固定权重（Weight-Stationary）结构
- 每个输出元素分配 19 位：`res[19*(4i+j) +: 19] = y_ij`

模块名：`MULT`（`input_data[127:0]`、`weight[127:0]`、`clk`、`rst_n`、`load` → `res[303:0]`）

> 注：`input` 为 Verilog 关键字，代码中使用 `input_data`。

## 本版本说明

实验三提供两个版本，接口、时序、验证平台完全一致：

| 版本 | 目录 | PE 乘加实现 | 依赖 |
| ---- | ---- | ---- | ---- |
| **独立版（本目录）** | `lab_3_standalone` | 行为级 `*` / `+`（综合器自动映射） | 仅本目录，自包含 |
| 复用版 | [lab_3_reuse](../lab_3_reuse) | 结构实例化 Lab 2 Wallace 乘法器 + Lab 1 前缀加法器 | `lab_1`、`lab_2` |

独立版适合**只做实验三**的场景：无需先完成实验一、二即可独立编译、仿真、综合。

## 参考实现验证结果（已跑通，2026-10-12）

| 项目 | 结果 |
| ---- | ---- |
| 功能仿真（iverilog + vvp） | 单位矩阵单发、**双矩阵 II=4 连续流水**、换权重后再计算，**三组检查全部 0 错误 PASS** |
| 输出有效时刻 | 首次 `t=10` 整组锁存，此后每 4 拍更新（连续矩阵流） |
| 综合（Yosys ABC，`synth -flatten`） | **7709 cells**，最长拓扑路径 **38 级**（单个 PE 的乘加路径，流水寄存器将其与阵列规模解耦） |

关键设计约定（详见 [rtl/MULT.v](rtl/MULT.v) 头部注释）：

- **输入**：按帧驱动，一帧 4 拍；帧 f 槽位 `input_data[8*(4q+k) +: 8]` 在 `t=4f+q` 拍被第 k 行消费（对角错位注入）
- **权重**：`weight[8*(4i+k) +: 8] = K[i][k]`，load=1 装入并清空流水寄存器
- **输出**：`res[19*(4i+j) +: 19] = y_ij`（行主序）；`t=i+j+4` 出现于列底，经 `6-i-j` 拍对齐延迟后于 `t=10` 整组对齐

复现命令：

```bash
# 功能仿真（在 lab_3_standalone/sim/ 下）
iverilog -g2005 -o simv ../rtl/MULT.v ../rtl/PE.v ../tb/tb_MULT.v
vvp simv
# 综合（在 lab_3_standalone/syn/ 下）
yosys synth.ys
```