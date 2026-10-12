`timescale 1ns / 1ps
// =============================================================
// Lab 3 (standalone 独立版): 处理单元 (PE) —— 固定权重
//
// 每拍完成：p_out <= p_in + w * x_in，x_in 寄存后向右传递。
// 乘加运算直接使用行为级运算符 * / +（由综合器自动映射乘法器
// 与加法器），不依赖 Lab 1 / Lab 2 的模块，可独立编译验证。
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
      p_out <= p_in + w_hold * x_in;
    end
  end

endmodule
