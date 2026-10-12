`timescale 1ns/1ps

module tb_adder4;

reg  [3:0] a;
reg  [3:0] b;
reg        cin;
wire [3:0] sum;
wire       cout;

// 实例化被测模块
adder4 u_adder4 (
    .a    (a),
    .b    (b),
    .cin  (cin),
    .sum  (sum),
    .cout (cout)
);

// 生成波形文件
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_adder4);
end

// 测试激励
initial begin
    a = 4'd0;  b = 4'd0;  cin = 1'b0;
    #10;
    a = 4'd3;  b = 4'd5;            // 预期 sum=8, cout=0
    #10;
    a = 4'd15; b = 4'd1;            // 预期 sum=0, cout=1
    #10;
    a = 4'd12; b = 4'd7;  cin = 1'b1; // 预期 sum=4, cout=1
    #10;
    $display("Simulation finished, check waveform.");
    $finish;
end

endmodule