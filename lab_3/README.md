# Lab 3：全流水脉动阵列矩阵乘法器

**Fully Pipelined Systolic-Array Matrix Multiplier**

- 完成两个 4×4 无符号整数矩阵相乘的脉动阵列矩阵乘法器
- 采用固定权重（Weight-Stationary）、输入输出流动的方式
- 采用流水线结构
- `load = 0`：正常流水计算；`load = 1`：停止计算并装载权重

模块名：`MULT`（`input[127:0]`、`weight[127:0]`、`clk`、`rst_n`、`load` → `res[303:0]`）

> 注：`input` 为 Verilog 关键字，代码中应使用 `input_data` 等合法标识符。