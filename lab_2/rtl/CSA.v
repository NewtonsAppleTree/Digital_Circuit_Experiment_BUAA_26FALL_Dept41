`timescale 1ns / 1ps
// =============================================================
// Carry-Save Adder (进位保存加法器)，向量级 3:2 压缩器
//
// 约定：输出未左移的【原始进位向量 q】；
//       q 的左移（<<1）在送入下一级时完成，每级只移一次。
//   s = x ^ y ^ z
//   q = (x&y) | (x&z) | (y&z)
// 满足：x + y + z = s + (q << 1)
// =============================================================
module CSA #(
    parameter W = 16
) (
    input  [W-1:0] x,
    input  [W-1:0] y,
    input  [W-1:0] z,
    output [W-1:0] s,
    output [W-1:0] q
);

  assign s = x ^ y ^ z;
  assign q = (x & y) | (x & z) | (y & z);

endmodule
