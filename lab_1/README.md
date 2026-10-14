# Lab 1：并行前缀进位加法器

**Parallel-Prefix Carry Adder**

- 完成 19 位并行前缀进位加法器
- Sklansky / Kogge–Stone / Brent–Kung / Han–Carlson 结构均可
- 必须采用组合逻辑，模块无时钟输入

模块名：`ADDER`（`in1[18:0]`、`in2[18:0]`、`cin` → `sum[18:0]`、`cout`）

## 参考实现验证结果（已实测通过）

| 项目 | 结果 |
| ---- | ---- |
| 功能仿真（iverilog + vvp） | 10 定向边界 + 10000 随机向量，Kogge–Stone 与 RCA **均 0 错误 PASS** |
| 综合单元数（Yosys ABC 映射） | Kogge–Stone **147 cells** / RCA **95 cells** |
| 最长拓扑路径（`ltp`） | Kogge–Stone **27 级** / RCA **39 级**（关键路径缩短约 31%） |

复现命令：

```bash
# 功能仿真（在 lab_1/sim/ 下）
iverilog -g2005 -o simv ../rtl/ADDER.v ../rtl/ADDER_RCA.v ../tb/tb_ADDER.v
vvp simv
# 综合对比（在 lab_1/syn/ 下，结果输出至 ks_/rca_ stat/ltp 文本）
yosys synth.ys
```

结论与手册一致：前缀加法器以增加约 55% 面积为代价，将进位路径从线性（RCA）压缩为对数级（KS），体现速度—面积权衡。