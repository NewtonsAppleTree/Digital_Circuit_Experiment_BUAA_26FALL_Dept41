`timescale 1ns / 1ps
// =============================================================
// Lab 3: 处理单元 (Processing Element, PE) —— 固定权重
//
// 每拍完成：p_out <= p_in + w * x_in，x_in 寄存后向右传递。
// 乘加运算结构复用课程前两个实验（加法器→乘法器→阵列 路径）：
//   w * x     —— Lab 2 的 8 位 Wallace 树乘法器 MULT8_WALLACE
//   p_in + 积 —— Lab 1 的 19 位并行前缀加法器 ADDER
//
// load=1：装入权重 w，同时清空流水寄存器（防止旧部分和混入新权重）。
// load=0：正常流水计算。
// 复位：同步低有效 rst_n，清空全部寄存器。
// =============================================================
module PE (
    input             clk,
    input             rst_n,
    input             load,
    input      [ 7:0] w_in,   // 权重装载值（load=1 时写入）
    input      [ 7:0] x_in,   // 左侧传入的输入元素
    input      [18:0] p_in,   // 上方传入的部分和
    output reg [ 7:0] x_out,  // 向右传递的输入（寄存 1 拍）
    output reg [18:0] p_out,  // 向下传递的部分和（寄存 1 拍）
    output reg [ 7:0] w_hold  // 驻留权重（观测用）
);

  // ---- 乘法：Lab 2 的 8 位 Wallace 树乘法器（组合逻辑）----
  wire [15:0] prod;
  MULT8_WALLACE u_mult (
      .in1(w_hold),
      .in2(x_in),
      .res(prod)
  );

  // ---- 加法：Lab 1 的 19 位 Kogge-Stone 前缀加法器（组合逻辑）----
  // 积零扩展至 19 位，cin = 0；部分和 < 2^18，cout 恒为 0
  wire [18:0] p_sum;
  wire        p_cout;
  ADDER u_adder (
      .in1 (p_in),
      .in2 ({3'b000, prod}),
      .cin (1'b0),
      .sum (p_sum),
      .cout(p_cout)
  );

  always @(posedge clk) begin
    if (!rst_n) begin
      w_hold <= 8'd0;
      x_out  <= 8'd0;
      p_out  <= 19'd0;
    end else if (load) begin
      w_hold <= w_in;
      x_out  <= 8'd0;
      p_out  <= 19'd0;
    end else begin
      x_out <= x_in;
      p_out <= p_sum;
    end
  end

endmodule
