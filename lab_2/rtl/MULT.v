`timescale 1ns / 1ps
// =============================================================
// Lab 2: 8-bit 无符号移位相加乘法器 (Wallace Tree)
//
// 实验手册要求的顶层模块（模块名必须为 MULT）。
// 核心逻辑在共享模块 MULT8_WALLACE 中实现，本文件为端口包装，
// 以便 Lab 3 的 PE 直接复用同一乘法器核心。
// 接口（按实验手册要求）：in1[7:0], in2[7:0] -> res[15:0]
// =============================================================
module MULT (
    input  [ 7:0] in1,
    input  [ 7:0] in2,
    output [15:0] res
);

  MULT8_WALLACE u_core (
      .in1(in1),
      .in2(in2),
      .res(res)
  );

endmodule
