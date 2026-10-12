`timescale 1ns / 1ps
// =============================================================
// Lab 1: 19-bit Parallel-Prefix Carry Adder (Kogge-Stone)
//
// 结构：输入预处理(g/p) -> 5 级前缀合并(距离 1/2/4/8/16) -> 求和输出
// 组合逻辑实现，无时钟。
// 接口（按实验手册要求）：
//   in1[18:0], in2[18:0], cin -> sum[18:0], cout
// =============================================================
module ADDER (
    input  [18:0] in1,
    input  [18:0] in2,
    input         cin,
    output [18:0] sum,
    output        cout
);

  localparam N      = 19;  // 位宽
  localparam LEVELS = 5;   // 前缀合并层数：ceil(log2(19)) = 5

  // 位级进位产生 g 与进位传播 p
  wire [N-1:0] g, p;
  assign g = in1 & in2;
  assign p = in1 ^ in2;

  // 各级前缀网络的区间产生 G / 区间传播 P，第 0 级为位级信号
  wire [N-1:0] G[0:LEVELS];
  wire [N-1:0] P[0:LEVELS];
  assign G[0] = g;
  assign P[0] = p;

  // Kogge-Stone 前缀合并：
  //   (G_hi, P_hi) o (G_lo, P_lo) = (G_hi | (P_hi & G_lo), P_hi & P_lo)
  // 第 k 层合并距离 D = 2^(k-1)，不足距离的低位节点直接透传
  genvar k, i;
  generate
    for (k = 1; k <= LEVELS; k = k + 1) begin : prefix_level
      localparam integer D = 1 << (k - 1);
      for (i = 0; i < N; i = i + 1) begin : prefix_node
        if (i >= D) begin : merge
          assign G[k][i] = G[k-1][i] | (P[k-1][i] & G[k-1][i-D]);
          assign P[k][i] = P[k-1][i] & P[k-1][i-D];
        end else begin : passthrough
          assign G[k][i] = G[k-1][i];
          assign P[k][i] = P[k-1][i];
        end
      end
    end
  endgenerate

  // 进位：c[i+1] = G[i:0] | (P[i:0] & cin)，c[0] = cin
  wire [N:0] c;
  assign c[0] = cin;
  generate
    for (i = 0; i < N; i = i + 1) begin : carry_gen
      assign c[i+1] = G[LEVELS][i] | (P[LEVELS][i] & cin);
    end
  endgenerate

  assign sum  = p ^ c[N-1:0];
  assign cout = c[N];

endmodule
