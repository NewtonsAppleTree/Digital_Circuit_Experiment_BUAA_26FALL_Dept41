// =============================================================
// Lab 1 参照组: 19-bit Ripple-Carry Adder (串行进位加法器)
// 用于功能交叉验证与 Yosys 综合性能对比的基线。
// 进位链长度随位宽线性增长（19 级），作为关键路径参照。
// =============================================================
module ADDER_RCA (
    input  [18:0] in1,
    input  [18:0] in2,
    input         cin,
    output [18:0] sum,
    output        cout
);

  localparam N = 19;

  wire [N-1:0] g, p;
  wire [N:0] c;

  assign g    = in1 & in2;
  assign p    = in1 ^ in2;
  assign c[0] = cin;

  // 串行递推：c[i+1] = g[i] | (p[i] & c[i])
  genvar i;
  generate
    for (i = 0; i < N; i = i + 1) begin : rca_bit
      assign c[i+1] = g[i] | (p[i] & c[i]);
      assign sum[i] = p[i] ^ c[i];
    end
  endgenerate

  assign cout = c[N];

endmodule
