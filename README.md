# Digital Circuit Experiment (BUAA · 2026 Fall · Dept 41)

北航集成电路科学与工程学院《数字电路实验》课程仓库
Verilog Implementation of a Fully Pipelined Matrix Multiplier

## 课程实验 | Labs

课程按照 **加法器 → 乘法器 → 矩阵计算阵列** 的路径展开：

| 实验 | 内容 | 关键技术 | 目录 |
| ---- | ---- | ---- | ---- |
| 实验一 | 并行前缀进位加法器 | 19 位，Kogge–Stone / Sklansky / Brent–Kung / Han–Carlson，组合逻辑 | [lab_1/](lab_1/) |
| 实验二 | 移位相加乘法器 | 8 位无符号，Wallace 树压缩 + 前缀加法器最终求和 | [lab_2/](lab_2/) |
| 实验三 | 全流水脉动阵列矩阵乘法器 | 4×4 矩阵，固定权重（Weight-Stationary），流水线 | [lab_3/](lab_3/) |

## 目录结构 | Repository Structure

```
├── Requirement/    # 实验要求与手册（原文 docx、英文翻译、中英术语对照表）
├── Reference/      # 参考代码与环境（env / lab_1 / lab_2 / lab_3）
├── lab_1/          # 实验一：并行前缀进位加法器
├── lab_2/          # 实验二：移位相加乘法器
└── lab_3/          # 实验三：全流水脉动阵列矩阵乘法器
```

## 文档 | Documents

- [实验手册（原始中文版 docx）](Requirement/Digtal实验手册.docx)
- [Lab Manual (English Translation)](Requirement/DigtalLabManual_EN.md)
- [专业术语中英文对照表 (CN–EN Glossary)](Requirement/Terminology_CN_EN.md)