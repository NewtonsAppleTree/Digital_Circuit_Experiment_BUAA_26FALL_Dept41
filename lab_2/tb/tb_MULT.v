// =============================================================
// Lab 2 Testbench: 8-bit Wallace 树乘法器验证
// 定向用例 -> 全量遍历 256×256 = 65536 组，与行为级 a*b 比对
// =============================================================
`timescale 1ns/1ps

module tb_MULT;

    reg  [7:0]  in1, in2;
    wire [15:0] res;

    MULT u_mult (
        .in1 (in1),
        .in2 (in2),
        .res (res)
    );

    integer errors = 0;
    integer total  = 0;
    integer a, b;

    reg [15:0] ref;

    // 波形：只记录定向测试阶段
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_MULT);
    end

    task check;
        input [7:0] x, y;
        begin
            in1 = x; in2 = y;
            #1;
            ref = x * y;
            total = total + 1;
            if (res !== ref) begin
                errors = errors + 1;
                if (errors <= 20)   // 最多打印 20 条错误明细
                    $display("[ERROR] %0d x %0d -> got %0d (0x%h), expect %0d (0x%h)",
                             x, y, res, res, ref, ref);
            end
        end
    endtask

    initial begin
        // ---------- 定向边界用例 ----------
        check(8'd0,   8'd0);      // 0 x 0
        check(8'd0,   8'd255);    // 0 x max
        check(8'd1,   8'd1);      // 1 x 1
        check(8'd1,   8'd255);    // 恒等
        check(8'd255, 8'd1);
        check(8'd255, 8'd255);    // 最大值 65025
        check(8'd128, 8'd2);      // 单比特移位
        check(8'd170, 8'd85);     // 交替位型 0xAA x 0x55
        check(8'd85,  8'd170);

        $dumpoff;

        // ---------- 全量遍历 65536 组 ----------
        for (a = 0; a < 256; a = a + 1)
            for (b = 0; b < 256; b = b + 1)
                check(a[7:0], b[7:0]);

        // ---------- 结果统计 ----------
        $display("==============================================");
        $display("Total vectors : %0d", total);
        $display("Errors        : %0d", errors);
        if (errors == 0) $display("RESULT: PASS");
        else             $display("RESULT: FAIL");
        $display("==============================================");
        $finish;
    end

endmodule