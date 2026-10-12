// =============================================================
// Lab 1 Testbench: 19-bit 加法器验证
// 同时例化 Kogge-Stone (ADDER) 与串行进位 (ADDER_RCA)，
// 与行为级参考模型 in1+in2+cin 逐拍比对。
// 流程：定向边界用例 -> 随机向量 -> 打印 PASS/FAIL 统计
// =============================================================
`timescale 1ns/1ps

module tb_ADDER;

    localparam N       = 19;
    localparam N_RANDOM = 10000;   // 随机向量数量

    reg  [N-1:0] in1, in2;
    reg          cin;

    wire [N-1:0] sum_ks,  sum_rca;
    wire         cout_ks, cout_rca;

    // 被测：Kogge-Stone 前缀加法器
    ADDER u_ks (
        .in1  (in1),
        .in2  (in2),
        .cin  (cin),
        .sum  (sum_ks),
        .cout (cout_ks)
    );

    // 参照：串行进位加法器
    ADDER_RCA u_rca (
        .in1  (in1),
        .in2  (in2),
        .cin  (cin),
        .sum  (sum_rca),
        .cout (cout_rca)
    );

    integer errors_ks  = 0;
    integer errors_rca = 0;
    integer total      = 0;
    integer t;

    reg [N:0] ref;   // 20 位参考结果 {cout, sum}

    // 波形：只记录定向测试阶段，随机阶段关闭以控制文件大小
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_ADDER);
    end

    // 单个向量检查任务
    task check;
        input [N-1:0] a, b;
        input         ci;
        begin
            in1 = a; in2 = b; cin = ci;
            #10;
            ref = {1'b0, a} + {1'b0, b} + ci;
            total = total + 1;
            if ({cout_ks, sum_ks} !== ref) begin
                errors_ks = errors_ks + 1;
                $display("[KS  ERROR] a=%h b=%h cin=%b -> got %b_%h, expect %b_%h",
                         a, b, ci, cout_ks, sum_ks, ref[N], ref[N-1:0]);
            end
            if ({cout_rca, sum_rca} !== ref) begin
                errors_rca = errors_rca + 1;
                $display("[RCA ERROR] a=%h b=%h cin=%b -> got %b_%h, expect %b_%h",
                         a, b, ci, cout_rca, sum_rca, ref[N], ref[N-1:0]);
            end
        end
    endtask

    initial begin
        // ---------- 定向边界用例 ----------
        check(19'h00000, 19'h00000, 1'b0);   // 全零
        check(19'h00000, 19'h00000, 1'b1);   // 仅进位
        check(19'h7FFFF, 19'h00000, 1'b0);   // 最大操作数
        check(19'h7FFFF, 19'h7FFFF, 1'b0);   // 最大+最大 -> 溢出
        check(19'h7FFFF, 19'h7FFFF, 1'b1);   // 溢出+进位
        check(19'h7FFFF, 19'h00000, 1'b1);   // 全传播链 + cin -> 进位贯穿 19 位
        check(19'h00001, 19'h00001, 1'b0);   // 最小产生进位
        check(19'h55555, 19'h2AAAA, 1'b0);   // 交替进位链
        check(19'h2AAAA, 19'h55555, 1'b1);
        check(19'h40000, 19'h40000, 1'b0);   // 仅最高位 -> 进位到 cout

        $dumpoff;    // 定向部分结束，停止记录波形

        // ---------- 随机向量 ----------
        for (t = 0; t < N_RANDOM; t = t + 1) begin
            check($random & 19'h7FFFF, $random & 19'h7FFFF, $random & 1'b1);
        end

        // ---------- 结果统计 ----------
        $display("==============================================");
        $display("Total vectors : %0d", total);
        $display("Kogge-Stone   : %0d errors", errors_ks);
        $display("Ripple-Carry  : %0d errors", errors_rca);
        if (errors_ks == 0 && errors_rca == 0)
            $display("RESULT: PASS");
        else
            $display("RESULT: FAIL");
        $display("==============================================");
        $finish;
    end

endmodule