# Digital Circuit Experiment (BUAA · 2026 Fall · Dept 41)

北航集成电路科学与工程学院《数字电路实验》课程仓库
Verilog Implementation of a Fully Pipelined Matrix Multiplier

## 课程实验 | Labs

课程按照 **加法器 → 乘法器 → 矩阵计算阵列** 的路径展开：

| 实验 | 内容 | 关键技术 | 目录 |
| ---- | ---- | ---- | ---- |
| 实验一 | 并行前缀进位加法器 | 19 位，Kogge–Stone / Sklansky / Brent–Kung / Han–Carlson，组合逻辑 | [lab_1/](lab_1/) |
| 实验二 | 移位相加乘法器 | 8 位无符号，Wallace 树压缩 + 前缀加法器最终求和 | [lab_2/](lab_2/) |
| 实验三 | 全流水脉动阵列矩阵乘法器 | 4×4 矩阵，固定权重（Weight-Stationary），流水线 | [lab_3_reuse/](lab_3_reuse/) · [lab_3_standalone/](lab_3_standalone/) |

> 实验三提供双版本（接口、时序、测试平台一致）：`lab_3_reuse` 复用版在 PE 中结构实例化 Lab 2 乘法器与 Lab 1 加法器，体现课程连贯路径；`lab_3_standalone` 独立版自包含，可脱离实验一、二单独完成。

## 目录结构 | Repository Structure

```
├── Requirement/       # 实验要求与手册（原文 docx、英文翻译、中英术语对照表）
├── Reference/         # 参考代码与环境（env / lab_1 / lab_2 / lab_3）
├── lab_1/             # 实验一：并行前缀进位加法器
├── lab_2/             # 实验二：移位相加乘法器
├── lab_3_reuse/       # 实验三（复用版）：PE 实例化 Lab2 乘法器 + Lab1 加法器
└── lab_3_standalone/  # 实验三（独立版）：自包含，行为级乘加
```

## 文档 | Documents

- [实验手册（原始中文版 docx）](Requirement/DigtalLab实验手册.docx)
- [Lab Manual (English Translation)](Requirement/DigtalLabManual_EN.md)
- [专业术语中英文对照表 (CN–EN Glossary)](Requirement/Terminology_CN_EN.md)