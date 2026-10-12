// =============================================================
// Lab 3 Testbench: 4x4 脉动阵列矩阵乘法器验证
//
// 流程：
//   1) 复位 -> load 装入权重 K1（identity，便于波形肉眼核对）
//   2) 连续注入 2 个矩阵（II=4 流水），t=10 / t=14 检查 res
//   3) 重新 load 装入权重 K2，验证旧部分和被清除，再算 1 个矩阵
//
// 输入打包规则（对角错位注入）：
//   帧 f 槽位 (4q+k) 在 t=4f+q 拍被第 k 行消费，
//   内容 = X_m[k][j]，其中 4m+j = (4f+q-k)，越界填 0。
// 输出：res[19*(4i+j) +: 19] = y_ij（行主序），
//   t=4m+10 拍整组锁存（m 为矩阵序号）。
// =============================================================
`timescale 1ns / 1ps

module tb_MULT;

  reg clk, rst_n, load;
  reg [127:0] input_data, weight;
  wire [303:0] res;

  MULT u_dut (
      .clk       (clk),
      .rst_n     (rst_n),
      .load      (load),
      .input_data(input_data),
      .weight    (weight),
      .res       (res)
  );

  initial clk = 1'b0;
  always #5 clk = ~clk;  // 100 MHz

  // ---------------- 数据存储 ----------------
  reg [7:0] K1[0:3][0:3];
  reg [7:0] K2[0:3][0:3];
  reg [7:0] X0[0:3][0:3];
  reg [7:0] X1[0:3][0:3];
  reg [7:0] X2[0:3][0:3];
  integer Yexp[0:2][0:3][0:3];  // 期望结果（每矩阵 16 个，< 2^18）

  integer errors = 0;
  integer i, k, j, m, q, f, s, T;

  // ---------------- 波形 ----------------
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_MULT);
  end

  // ---------------- 工具任务 ----------------
  // 计算期望结果：Y = K * X
  task golden;
    input integer midx;  // 期望结果写入 Yexp[midx]
    input integer ksel;  // 权重选择：1->K1, 2->K2
    input integer xsel;  // 输入矩阵：0->X0, 1->X1, 2->X2
    integer ii, jj, kk, acc, xv, kv;
    begin
      for (ii = 0; ii < 4; ii = ii + 1)
      for (jj = 0; jj < 4; jj = jj + 1) begin
        acc = 0;
        for (kk = 0; kk < 4; kk = kk + 1) begin
          kv  = (ksel == 1) ? K1[ii][kk] : K2[ii][kk];
          xv  = (xsel == 0) ? X0[kk][jj] : (xsel == 1) ? X1[kk][jj] : X2[kk][jj];
          acc = acc + kv * xv;
        end
        Yexp[midx][ii][jj] = acc;
      end
    end
  endtask

  // 打包权重总线（行主序 K[i][k] -> 槽位 4i+k）
  task pack_weight;
    input integer ksel;
    begin
      weight = 128'd0;
      for (i = 0; i < 4; i = i + 1)
      for (k = 0; k < 4; k = k + 1) weight[8*(4*i+k)+:8] = (ksel == 1) ? K1[i][k] : K2[i][k];
    end
  endtask

  // 打包第 f 帧输入（run1：矩阵流 X0,X1；run2：单矩阵 X2）
  task pack_frame;
    input integer f;
    input integer run;
    integer mm, jj;
    reg [7:0] v;
    begin
      input_data = 128'd0;
      for (q = 0; q < 4; q = q + 1)
      for (k = 0; k < 4; k = k + 1) begin
        s = 4 * f + q - k;  // 全局 4m+j
        if (s < 0) v = 8'd0;
        else begin
          mm = s / 4;
          jj = s % 4;
          if (run == 1) begin
            if (mm == 0) v = X0[k][jj];
            else if (mm == 1) v = X1[k][jj];
            else v = 8'd0;
          end else begin
            if (mm == 0) v = X2[k][jj];
            else v = 8'd0;
          end
        end
        input_data[8*(4*q+k)+:8] = v;
      end
    end
  endtask

  // 比对 res 与期望矩阵 midx
  task check_res;
    input integer midx;
    integer ii, jj;
    integer got;
    begin
      for (ii = 0; ii < 4; ii = ii + 1)
      for (jj = 0; jj < 4; jj = jj + 1) begin
        got = res[19*(4*ii+jj)+:19];
        if (got !== Yexp[midx][ii][jj]) begin
          errors = errors + 1;
          $display("[ERROR] m%0d y%0d%0d: got %0d, expect %0d", midx, ii, jj, got,
                   Yexp[midx][ii][jj]);
        end
      end
      if (errors == 0) $display("[CHECK] matrix m%0d: res correct at t=%0d", midx, T);
      else $display("[CHECK] matrix m%0d: MISMATCH (cum errors=%0d)", midx, errors);
    end
  endtask

  // ---------------- 初始化数据 ----------------
  initial begin
    // K1 = 单位矩阵（Y = X，便于波形肉眼核对）
    for (i = 0; i < 4; i = i + 1) for (k = 0; k < 4; k = k + 1) K1[i][k] = (i == k) ? 8'd1 : 8'd0;
    // K2 = 全 2（每输出 = 2 * 列和）
    for (i = 0; i < 4; i = i + 1) for (k = 0; k < 4; k = k + 1) K2[i][k] = 8'd2;
    // X0：规则递增值，X1/X2：伪随机
    for (k = 0; k < 4; k = k + 1)
    for (j = 0; j < 4; j = j + 1) begin
      X0[k][j] = 4 * k + j + 1;  // 1..16
      X1[k][j] = (17 * k + 31 * j + 13) % 256;  // 确定性伪随机
      X2[k][j] = (41 * k + 7 * j + 5) % 256;
    end

    golden(0, 1, 0);  // m0 = K1 * X0
    golden(1, 1, 1);  // m1 = K1 * X1
    golden(2, 2, 2);  // m2 = K2 * X2
  end

  // ---------------- 主测试流程 ----------------
  initial begin
    rst_n = 1'b0;
    load = 1'b0;
    input_data = 128'd0;
    weight = 128'd0;

    // 复位 2 拍
    repeat (2) @(negedge clk);
    rst_n = 1'b1;

    // ---- run 1：装入 K1，连续注入 X0、X1（II=4）----
    @(negedge clk);
    load = 1'b1;
    pack_weight(1);
    @(negedge clk);
    load = 1'b0;
    pack_frame(0, 1);  // t=0 的帧 0
    for (T = 1; T <= 14; T = T + 1) begin
      @(negedge clk);
      pack_frame(T / 4, 1);
      @(posedge clk);
      #1;
      if (T == 10) check_res(0);
      if (T == 14) check_res(1);
    end

    // ---- run 2：换权重 K2（验证旧部分和被清除），算 X2 ----
    @(negedge clk);
    load = 1'b1;
    pack_weight(2);
    @(negedge clk);
    load = 1'b0;
    pack_frame(0, 2);
    for (T = 1; T <= 10; T = T + 1) begin
      @(negedge clk);
      pack_frame(T / 4, 2);
      @(posedge clk);
      #1;
      if (T == 10) check_res(2);
    end

    // ---------------- 总结 ----------------
    $display("==============================================");
    $display("Errors : %0d", errors);
    if (errors == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");
    $display("==============================================");
    $finish;
  end

endmodule
