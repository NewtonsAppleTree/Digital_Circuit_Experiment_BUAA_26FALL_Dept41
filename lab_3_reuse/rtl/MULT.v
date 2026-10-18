`timescale 1ns / 1ps
// =============================================================
// Lab 3: 全流水脉动阵列矩阵乘法器 (4x4, 固定权重, Weight-Stationary)
//
// 计算 Y = K * X，K、X 均为 4x4 无符号 8 位整数矩阵，
// y_ij = sum_k K[i][k] * X[k][j]，每元素 < 2^18，按 19 位分配。
//
// ---------------- 接口与数据约定（设计文档） ----------------
// 1. 权重总线 weight[127:0]：行主序存放 K，
//    weight[8*(4i+k) +: 8] = K[i][k]。
//    load=1 时每拍并行装入 16 个 PE（PE(k,i) 驻留 K[i][k]），
//    同时清空全部流水寄存器，旧计算作废。
// 2. 输入总线 input_data[127:0]：按“帧”驱动，一帧 4 拍。
//    第 f 帧的槽位 (4q+k) 在第 t=4f+q 拍被第 k 行左边界消费：
//        input_data[8*(4q+k) +: 8] = 第 k 行在 t=4f+q 拍需要的元素
//    对矩阵 m（注入窗口 t∈[4m,4m+6]），元素 X_m[k][j] 出现在
//    t=4m+j+k 拍（对角错位注入），驱动方按拍打包，详见 tb_MULT.v。
// 3. 时序：load 拉低后内部 phase/t_run 计数启动。
//    X[k][j] 到达 PE(k,i) 的拍为 j+k+i（每跨一个 PE 延迟 1 拍），
//    y_ij 在 t = i+j+3 沿后出现于第 i 列底部（即下一沿 t=i+j+4 沿前），
//    经深度 6-i-j 的对齐延迟后，全部抽头在 t=9 沿后对齐，t=10 锁存。
// 4. 输出 res[303:0]：行主序，res[19*(4i+j) +: 19] = y_ij。
//    t_run 饱和(>=10)且 phase==2 时整组锁存（首次 t=10，
//    此后每 4 拍随连续矩阵流更新一次），load=1 或其余时间保持稳定。
// 5. 复位：同步低有效 rst_n，清空全部寄存器（含权重与 res）。
// =============================================================
module MULT (
    input              clk,
    input              rst_n,
    input              load,
    input      [127:0] input_data,
    input      [127:0] weight,
    output reg [303:0] res
);

  // ---------------- 节拍计数 ----------------
  reg [1:0] phase;  // 帧内拍号 = t mod 4（输入槽位选择）
  reg [3:0] t_run;  // load 拉低后的拍数，饱和于 10（门控首次有效）

  always @(posedge clk) begin
    if (!rst_n || load) begin
      phase <= 2'd0;
      t_run <= 4'd0;
    end else begin
      phase <= phase + 2'd1;
      if (t_run < 4'd10) t_run <= t_run + 4'd1;
    end
  end

  wire capture_en = (phase == 2'd2) && (t_run == 4'd10);

  // ---------------- 4x4 PE 阵列 ----------------
  // x_wire[k][i]：PE(k,i) 的 x 输入；p_wire[k][i]：PE(k,i) 的 p 输入
  wire [7:0] x_wire[0:3][0:4];
  wire [18:0] p_wire[0:4][0:3];
  wire [7:0] w_obs[0:3][0:3];  // 驻留权重观测

  genvar gk, gi;
  generate
    for (gk = 0; gk < 4; gk = gk + 1) begin : row
      for (gi = 0; gi < 4; gi = gi + 1) begin : col
        PE u_pe (
            .clk   (clk),
            .rst_n (rst_n),
            .load  (load),
            .w_in  (weight[8*(4*gi+gk)+:8]),  // K[gi][gk]
            .x_in  (x_wire[gk][gi]),
            .p_in  (p_wire[gk][gi]),
            .x_out (x_wire[gk][gi+1]),
            .p_out (p_wire[gk+1][gi]),
            .w_hold(w_obs[gk][gi])
        );
      end
    end
  endgenerate

  // 行输入：帧槽位 (4*phase + k) 送入第 k 行左边界
  generate
    for (gk = 0; gk < 4; gk = gk + 1) begin : row_feed
      assign x_wire[gk][0] = input_data[8*(4*phase+gk)+:8];
    end
  endgenerate

  // 顶部部分和初始化为 0
  generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : top_zero
      assign p_wire[0][gi] = 19'd0;
    end
  endgenerate

  // ---------------- 输出对齐 ----------------
  // 第 i 列底部 p_wire[4][i] 在 t=i+j+3 沿后携带 y_ij；
  // 再延迟 (6-i-j) 拍，抽头在 t=9 沿后对齐，供 t=10 上升沿锁存。
  reg  [18:0] dly[0:3][0:6];  // 0 号位闲置，避免未选生成分支的越界告警
  wire [18:0] tap[0:3][0:3];

  genvar gj, gs;
  generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : align_col
      // 第 i 列的移位延迟链（深度 6-i）
      for (gs = 1; gs <= 6 - gi; gs = gs + 1) begin : dly_stage
        always @(posedge clk) begin
          if (!rst_n || load) dly[gi][gs] <= 19'd0;
          else dly[gi][gs] <= (gs == 1) ? p_wire[4][gi] : dly[gi][gs-1];
        end
      end
      // 各 j 的抽头
      for (gj = 0; gj < 4; gj = gj + 1) begin : tap_j
        if (6 - gi - gj == 0) assign tap[gi][gj] = p_wire[4][gi];
        else assign tap[gi][gj] = dly[gi][6-gi-gj];
      end
    end
  endgenerate

  // ---------------- 结果锁存 ----------------
  generate
    for (gi = 0; gi < 4; gi = gi + 1) begin : res_i
      for (gj = 0; gj < 4; gj = gj + 1) begin : res_j
        always @(posedge clk) begin
          if (!rst_n) res[19*(4*gi+gj)+:19] <= 19'd0;
          // load 优先于结果提交：取消旧流水，保留上次已提交结果。
          else if (!load && capture_en) res[19*(4*gi+gj)+:19] <= tap[gi][gj];
        end
      end
    end
  endgenerate

endmodule
