// =============================================================
// Lab 2 参照组: 朴素移位相加乘法器（组合逻辑直接连加 8 个部分积）
// 用于与 Wallace 树结构做 Yosys 综合对比（面积/关键路径）。
// 部分积求和退化为多级进位传播，关键路径更长。
// =============================================================
module MULT_NAIVE (
    input  [ 7:0] in1,
    input  [ 7:0] in2,
    output [15:0] res
);

  wire [15:0] pp[0:7];
  genvar j;
  generate
    for (j = 0; j < 8; j = j + 1) begin : gen_pp
      assign pp[j] = in2[j] ? ({8'b0, in1} << j) : 16'b0;
    end
  endgenerate

  assign res = pp[0] + pp[1] + pp[2] + pp[3] + pp[4] + pp[5] + pp[6] + pp[7];

endmodule
