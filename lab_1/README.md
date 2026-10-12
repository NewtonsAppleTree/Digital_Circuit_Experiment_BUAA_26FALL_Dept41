# Lab 1：并行前缀进位加法器

**Parallel-Prefix Carry Adder**

- 完成 19 位并行前缀进位加法器
- Sklansky / Kogge–Stone / Brent–Kung / Han–Carlson 结构均可
- 必须采用组合逻辑，模块无时钟输入

模块名：`ADDER`（`in1[18:0]`、`in2[18:0]`、`cin` → `sum[18:0]`、`cout`）