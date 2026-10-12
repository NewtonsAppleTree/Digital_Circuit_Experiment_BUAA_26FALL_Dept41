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
| 综合单元数（Yosys ABC，flatten） | Wallace 树 **794 cells** / 朴素移位相加 **338 cells** |
| 最长拓扑路径（`ltp`） | Wallace 树 **40 级** / 朴素移位相加 **30 级** |

复现命令：

```bash
# 功能仿真（在 lab_2/sim/ 下）
iverilog -g2005 -o simv ../rtl/MULT.v ../rtl/CSA.v ../../lab_1/rtl/ADDER.v ../tb/tb_MULT.v
vvp simv
# 综合对比（在 lab_2/syn/ 下）
yosys synth.ys
```

**结果解读（重要教学点）**：8 位位宽下，ABC 映射器对两个设计做了全局重构，理论上的 Wallace 树深度优势被综合器拉平甚至反转。这正印证了实验手册的结论——"实际性能仍需结合综合与时序结果判断；较少的理论层数并不保证在所有工艺或 FPGA 上都更快"。Wallace 树的结构性优势（压缩深度对数增长）在**更大位宽**、**限制重构**（如 `-noabc`）或定制单元库场景下才会体现。