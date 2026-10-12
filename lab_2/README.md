# Lab 2：移位相加乘法器

**Shift-and-Add Multiplier**

- 完成 8 位无符号整数的移位相加乘法器
- 8 个部分积的相加采用华莱士树（Wallace Tree）结构
- 压缩后的 2 个部分和采用 Lab 1 设计的并行前缀进位加法器完成

模块名：`MULT`（`in1[7:0]`、`in2[7:0]` → `res[15:0]`）

## 参考实现验证结果（已跑通，2026-10-12）

| 项目 | 结果 |
| ---- | ---- |
| 功能仿真（iverilog + vvp） | 9 定向 + **65536 全量遍历**，**0 错误 PASS** |
| 综合单元数（Yosys ABC，`synth -flatten`） | Wallace 树 **381 cells** / 朴素移位相加 **338 cells** |
| 最长拓扑路径（`ltp`） | Wallace 树 **28 级** / 朴素移位相加 **37 级** |

文件结构（课程路径"加法器→乘法器→阵列"的共享设计）：

- `rtl/MULT8_WALLACE.v` —— Wallace 树乘法器核心（CSA 压缩 8→6→4→3→2 + Lab 1 ADDER 最终求和）
- `rtl/MULT.v` —— 手册要求的顶层包装（模块名 `MULT`），Lab 3 的 PE 直接实例化核心模块复用

复现命令：

```bash
# 功能仿真（在 lab_2/sim/ 下）
iverilog -g2005 -o simv ../rtl/MULT.v ../rtl/MULT8_WALLACE.v ../rtl/CSA.v ../../lab_1/rtl/ADDER.v ../tb/tb_MULT.v
vvp simv
# 综合对比（在 lab_2/syn/ 下）
yosys synth.ys
```

**结果解读（重要教学点）**：

1. 在正确的综合流程下（`synth -flatten`，ABC 对整平设计全局优化），Wallace 树路径 **28 级** 明显短于朴素连加的 **37 级**，与理论预期一致（连加路径随部分积个数线性增长，Wallace 压缩为对数增长）。面积上 Wallace 略大（381 vs 338 cells），体现典型的**面积换速度**。
2. 综合脚本若写成 `synth; flatten`（先映射后整平），ABC 无法跨模块边界优化，LTP 会失真偏大——这是流程使用上的一个常见坑。
3. ABC 会对逻辑做全局重构，理论"层数"与综合后门级路径并非一一对应，验证实验手册的结论："实际性能仍需结合综合与时序结果判断"。