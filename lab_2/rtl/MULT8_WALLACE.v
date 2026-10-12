`timescale 1ns / 1ps
// =============================================================
// 8-bit 无符号 Wallace 树乘法器核心（共享模块）
//
// 本模块是课程“加法器→乘法器→矩阵计算阵列”路径的共享单元：
//   - Lab 2 顶层 MULT 对其做端口包装（满足手册模块名要求）
//   - Lab 3 的 PE 直接实例化本模块完成 w*x（再经 Lab1 ADDER 累加）
//
// 结构：部分积生成 -> Wallace 树 CSA 压缩(8->6->4->3->2)
//       -> Lab1 的 19 位并行前缀加法器完成最终求和
// 组合逻辑实现，无时钟。
// =============================================================
module MULT8_WALLACE (
    input  [ 7:0] in1,
    input  [ 7:0] in2,
    output [15:0] res
);

  localparam W = 16;

  // ---- 1. 部分积生成：pp[j] = in2[j] ? (in1 << j) : 0 ----
  wire [W-1:0] pp[0:7];
  genvar j;
  generate
    for (j = 0; j < 8; j = j + 1) begin : gen_pp
      assign pp[j] = in2[j] ? ({8'b0, in1} << j) : {W{1'b0}};
    end
  endgenerate

  // ---- 2. Wallace 树压缩（向量级 CSA）----
  // 约定：CSA 输出未左移的原始进位 q，左移在送入下一级时完成。
  // 第 1 层：8 -> 6
  wire [W-1:0] s1a, q1a, s1b, q1b;
  CSA #(W) csa_1a (
      .x(pp[0]),
      .y(pp[1]),
      .z(pp[2]),
      .s(s1a),
      .q(q1a)
  );
  CSA #(W) csa_1b (
      .x(pp[3]),
      .y(pp[4]),
      .z(pp[5]),
      .s(s1b),
      .q(q1b)
  );
  // pp[6]、pp[7] 直通

  // 第 2 层：6 -> 4
  wire [W-1:0] s2a, q2a, s2b, q2b;
  CSA #(W) csa_2a (
      .x(s1a),
      .y({q1a[W-2:0], 1'b0}),
      .z(s1b),
      .s(s2a),
      .q(q2a)
  );
  CSA #(W) csa_2b (
      .x({q1b[W-2:0], 1'b0}),
      .y(pp[6]),
      .z(pp[7]),
      .s(s2b),
      .q(q2b)
  );

  // 第 3 层：4 -> 3
  wire [W-1:0] s3a, q3a;
  CSA #(W) csa_3a (
      .x(s2a),
      .y({q2a[W-2:0], 1'b0}),
      .z(s2b),
      .s(s3a),
      .q(q3a)
  );
  // {q2b 左移} 直通

  // 第 4 层：3 -> 2
  wire [W-1:0] s4a, q4a;
  CSA #(W) csa_4a (
      .x(s3a),
      .y({q3a[W-2:0], 1'b0}),
      .z({q2b[W-2:0], 1'b0}),
      .s(s4a),
      .q(q4a)
  );

  // ---- 3. 最终加法：Lab1 的 19 位 Kogge-Stone 前缀加法器 ----
  // 输入零扩展至 19 位，cin = 0；结果 < 2^16，取低 16 位输出
  wire [18:0] final_sum;
  wire        final_cout;  // 8x8 无符号乘法不会越界，此信号应为 0
  ADDER u_final_adder (
      .in1 ({3'b000, s4a}),
      .in2 ({3'b000, q4a[W-2:0], 1'b0}),
      .cin (1'b0),
      .sum (final_sum),
      .cout(final_cout)
  );

  assign res = final_sum[15:0];

endmodule
