# Lab 3：全流水脉动阵列矩阵乘法器

**Fully Pipelined Systolic-Array Matrix Multiplier**

- 完成两个 4×4 无符号整数矩阵相乘的脉动阵列矩阵乘法器
- 采用固定权重（Weight-Stationary）、输入输出流动的方式
- 采用流水线结构
- `load = 0`：正常流水计算；`load = 1`：停止计算并装载权重

模块名：`MULT`（`input[127:0]`、`weight[127:0]`、`clk`、`rst_n`、`load` → `res[303:0]`）

> 注：`input` 为 Verilog 关键字，代码中应使用 `input_data` 等合法标识符。

## 参考实现验证结果（已跑通，2026-10-12）

| 项目 | 结果 |
| ---- | ---- |
| 功能仿真（iverilog + vvp） | 单位矩阵单发、**双矩阵 II=4 连续流水**、换权重后再计算，**三组检查全部 0 错误 PASS** |
| 输出有效时刻 | 首次 `t=10` 整组锁存，此后每 4 拍更新（连续矩阵流） |
| 综合（Yosys ABC，flatten） | **8268 cells**，最长拓扑路径 **40 级**（= 单个 PE 的乘加路径，流水寄存器有效切断长组合路径） |

关键设计约定（详见 [rtl/MULT.v](rtl/MULT.v) 头部注释）：

- **输入**：按帧驱动，一帧 4 拍；帧 f 槽位 `input_data[8*(4q+k) +: 8]` 在 `t=4f+q` 拍被第 k 行消费（对角错位注入）
- **权重**：`weight[8*(4i+k) +: 8] = K[i][k]`，load=1 装入并清空流水寄存器
- **输出**：`res[19*(4i+j) +: 19] = y_ij`（行主序）；`t=i+j+4` 出现于列底，经 `6-i-j` 拍对齐延迟后于 `t=10` 整组对齐

复现命令：

```bash
# 功能仿真（在 lab_3/sim/ 下）
iverilog -g2005 -o simv ../rtl/MULT.v ../rtl/PE.v ../tb/tb_MULT.v
vvp simv
# 综合（在 lab_3/syn/ 下）
yosys synth.ys
```