# -*- coding: utf-8 -*-
"""生成《数字电路实验参考手册》插图（PIL 绘制）"""
import os
from PIL import Image, ImageDraw, ImageFont

OUTDIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "images")
os.makedirs(OUTDIR, exist_ok=True)
FP = "C:/Windows/Fonts/msyh.ttc"


def font(sz, bold=False):
    return ImageFont.truetype(FP, sz, index=1 if bold else 0)


INK = (30, 30, 30)
BLUE = (30, 90, 180)
GREEN = (30, 140, 90)
ORANGE = (220, 120, 0)
GRAY = (120, 120, 120)
LBLUE = (222, 235, 250)
LGREEN = (225, 245, 235)


def ct(dr, xy, s, f, fill=INK, anchor="mm"):
    dr.text(xy, s, font=font(f), fill=fill, anchor=anchor)


# ---------------------------------------------------------------- 图1 Kogge-Stone
def fig_kogge_stone():
    W, H = 1140, 745
    img = Image.new("RGB", (W, H), "white")
    dr = ImageDraw.Draw(img)
    ct(dr, (W // 2, 40), "Kogge–Stone 8 位前缀网络（19 位为 5 级，规律相同）", 30, INK)
    ct(dr, (W // 2, 78), "前缀运算：G' = G_hi + P_hi·G_lo    P' = P_hi·P_lo", 20, GRAY)

    NB = 8                      # bit 0..7
    LV = 3                      # log2(8) = 3 级
    x0, dx = 330, 105
    y_in, dy = 170, 120
    ys = [y_in + k * dy for k in range(LV + 1)]   # ys[0]=输入行, ys[1..3]=第1..3级
    xs = {i: x0 + (7 - i) * dx for i in range(NB)}  # bit7 在最左

    # 左侧行标签
    ct(dr, (150, ys[0] - 34), "位级 g, p", 20, GRAY)
    ct(dr, (150, ys[0] + 30), "（a·b , a⊕b）", 17, GRAY)
    for k in range(1, LV + 1):
        ct(dr, (150, ys[k]), f"第 {k} 级", 20, INK)
        ct(dr, (150, ys[k] + 26), f"合并距离 2^{k-1} = {1 << (k-1)}", 16, GRAY)

    # 输入行节点（位级 GP）+ 位标签
    for i in range(NB):
        dr.ellipse([xs[i] - 9, ys[0] - 9, xs[i] + 9, ys[0] + 9], outline=INK, width=2, fill="white")
        ct(dr, (xs[i], ys[0] - 34), f"g{i},p{i}", 17, INK)

    # 逐级连线与节点
    for k in range(1, LV + 1):
        d = 1 << (k - 1)
        for i in range(NB):
            x, y = xs[i], ys[k]
            # 垂直线（上级 → 本级）
            dr.line([(x, ys[k - 1] + 9), (x, y - (11 if i >= d else 9))], fill=INK, width=2)
            if i >= d:
                # 对角线：来自 i-d 上级节点
                dr.line([(xs[i - d], ys[k - 1] + 9), (x, y - 11)], fill=BLUE, width=2)
                dr.ellipse([x - 11, y - 11, x + 11, y + 11], fill=BLUE, outline=INK)
            else:
                dr.rectangle([x - 8, y - 8, x + 8, y + 8], outline=GRAY, width=2, fill="white")

    # 输出行
    y_out = ys[LV] + 95
    for i in range(NB):
        dr.line([(xs[i], ys[LV] + 11), (xs[i], y_out - 20)], fill=INK, width=2)
        ct(dr, (xs[i], y_out + 8), f"c{i+1}", 18, INK)
    ct(dr, (150, y_out), "进位输出", 20, INK)
    ct(dr, (150, y_out + 26), "c_{i+1}=G+P·cin", 15, GRAY)

    # 图例（独立底行，避免与进位标签重叠）
    lx, ly = 90, H - 48
    dr.ellipse([lx, ly - 9, lx + 18, ly + 9], fill=BLUE, outline=INK)
    ct(dr, (lx + 30, ly), "前缀运算节点", 17, INK, anchor="lm")
    dr.rectangle([lx + 230, ly - 8, lx + 246, ly + 8], outline=GRAY, width=2, fill="white")
    ct(dr, (lx + 258, ly), "直通（本级不合并）", 17, INK, anchor="lm")
    ct(dr, (lx + 500, ly), "深度 = ceil(log2 N) 级，扇出 ≤ 2，布线规则", 17, GRAY, anchor="lm")

    img.save(os.path.join(OUTDIR, "fig_lab1_kogge_stone.png"), dpi=(150, 150))
    print("fig_lab1_kogge_stone.png")


# ---------------------------------------------------------------- 图2 Wallace 流程
def fig_wallace():
    W, H = 1240, 430
    img = Image.new("RGB", (W, H), "white")
    dr = ImageDraw.Draw(img)
    ct(dr, (W // 2, 38), "Wallace 树压缩流程（8×8 无符号乘法）", 30, INK)

    def box(x, y, w, h, text, sub="", fill=LBLUE, edge=BLUE):
        dr.rounded_rectangle([x, y, x + w, y + h], radius=10, fill=fill, outline=edge, width=2)
        ct(dr, (x + w / 2, y + h / 2 - (10 if sub else 0)), text, 20, INK)
        if sub:
            ct(dr, (x + w / 2, y + h / 2 + 16), sub, 15, GRAY)

    def arrow(x1, y, x2, label="", above=True):
        dr.line([(x1, y), (x2 - 12, y)], fill=INK, width=3)
        dr.polygon([(x2 - 12, y - 7), (x2, y), (x2 - 12, y + 7)], fill=INK)
        if label:
            ct(dr, ((x1 + x2) / 2, y - 18 if above else y + 20), label, 16, GREEN)

    y = 200
    box(30, y - 45, 150, 90, "8 个部分积", "pp[0..7] 各16位")
    arrow(180, y, 260, "第 1 层")
    box(260, y - 45, 120, 90, "CSA × 2", "2 个直通")
    arrow(380, y, 450, "6 个向量")
    box(450, y - 45, 120, 90, "CSA × 2", "")
    arrow(570, y, 640, "4 个向量")
    box(640, y - 45, 130, 90, "CSA × 1", "1 个直通")
    arrow(770, y, 840, "3 个向量")
    box(840, y - 45, 120, 90, "CSA × 1", "")
    arrow(960, y, 1060, "s, q<<1")
    box(1060, y - 45, 150, 90, "前缀加法器", "实验一 ADDER", LGREEN, GREEN)

    ct(dr, (1135, y + 70), "res[15:0]", 18, INK)
    ct(dr, (95, y + 70), "pp[j] = in2[j] ? in1<<j : 0", 15, GRAY)
    ct(dr, (W // 2, H - 60), "CSA = 进位保存加法器（3:2 压缩）：s = x⊕y⊕z，q = xy+xz+yz，q 送入下一级时左移 1 位", 18, INK)
    ct(dr, (W // 2, H - 30), "每层 CSA 仅 1 级全加器延迟、无横向进位链；8 → 6 → 4 → 3 → 2 共 4 层，最后做一次真正的进位传播加法", 17, GRAY)

    img.save(os.path.join(OUTDIR, "fig_lab2_wallace.png"), dpi=(150, 150))
    print("fig_lab2_wallace.png")


# ---------------------------------------------------------------- 图3 脉动阵列 + PE
def fig_systolic():
    W, H = 1380, 860
    img = Image.new("RGB", (W, H), "white")
    dr = ImageDraw.Draw(img)
    ct(dr, (W // 2, 36), "4×4 固定权重脉动阵列结构与 PE 内部", 30, INK)

    # ---------- 左：阵列 ----------
    gx, gy, cs = 210, 140, 132          # 网格原点、单元边长
    for k in range(4):                  # k = 行（自上而下 0..3）
        for i in range(4):              # i = 列（自左而右 0..3）
            x, y = gx + i * cs, gy + k * cs
            dr.rectangle([x, y, x + cs - 14, y + cs - 14], fill=LBLUE, outline=BLUE, width=2)
            ct(dr, (x + (cs - 14) / 2, y + 40), f"PE({k},{i})", 19, INK)
            ct(dr, (x + (cs - 14) / 2, y + 68), f"w=K[{i}][{k}]", 15, GRAY)
    # 行输入箭头（左边界）
    for k in range(4):
        y = gy + k * cs + 52
        dr.line([(gx - 95, y), (gx - 8, y)], fill=GREEN, width=3)
        dr.polygon([(gx - 8, y - 7), (gx, y), (gx - 8, y + 7)], fill=GREEN)
        ct(dr, (gx - 104, y - 6), f"X[{k}][·]", 18, GREEN, anchor="rm")
        ct(dr, (gx - 104, y + 14), "错位 j+k", 13, GRAY, anchor="rm")
        # 行间 x 传递
        for i in range(3):
            x1 = gx + i * cs + cs - 14
            dr.line([(x1, y), (x1 + 8, y)], fill=GREEN, width=3)
            dr.polygon([(x1 + 8, y - 6), (x1 + 16, y), (x1 + 8, y + 6)], fill=GREEN)
    # 列间 p 传递 + 顶部 p=0
    for i in range(4):
        x = gx + i * cs + 52
        dr.line([(x, gy - 42), (x, gy - 6)], fill=ORANGE, width=3)
        dr.polygon([(x - 7, gy - 6), (x, gy + 2), (x + 7, gy - 6)], fill=ORANGE)
        ct(dr, (x, gy - 52), "p=0", 14, ORANGE)
        for k in range(3):
            y1 = gy + k * cs + cs - 14
            dr.line([(x, y1), (x, y1 + 10)], fill=ORANGE, width=3)
            dr.polygon([(x - 6, y1 + 10), (x, y1 + 18), (x + 6, y1 + 10)], fill=ORANGE)
    # 底部输出
    for i in range(4):
        x = gx + i * cs + 52
        y1 = gy + 4 * cs - 14
        dr.line([(x, y1), (x, y1 + 44)], fill=ORANGE, width=3)
        dr.polygon([(x - 7, y1 + 36), (x, y1 + 46), (x + 7, y1 + 36)], fill=ORANGE)
        ct(dr, (x, y1 + 62), f"y[{i}][·]", 16, ORANGE)
    ct(dr, (gx + 2 * cs, y1 + 102), "weight[127:0] 行主序，load=1 时 16 个权重并行装入各 PE", 16, GRAY)
    ct(dr, (gx + 2 * cs, y1 + 128), "绿色：x 向右流（每拍 1 格）　橙色：部分和向下流（每拍 1 格）", 16, GRAY)
    ct(dr, (gx + 2 * cs, y1 + 154), "列底 y[i][·] 经深度 6−i−j 对齐链后，t=10 整组锁存 res[303:0]", 16, GRAY)

    # ---------- 右：PE 内部 ----------
    px, py = 880, 170
    ct(dr, (px + 210, py - 60), "PE 内部（复用版 = Lab2 乘法器 + Lab1 加法器 + 寄存器）", 18, INK)
    bw, bh = 150, 56

    def pbox(cx, cy, t1, t2="", fill="white", edge=INK, w=None):
        w = w or bw
        dr.rectangle([cx - w / 2, cy - bh / 2, cx + w / 2, cy + bh / 2], fill=fill, outline=edge, width=2)
        ct(dr, (cx, cy - (8 if t2 else 0)), t1, 17, INK)
        if t2:
            ct(dr, (cx, cy + 14), t2, 13, GRAY)

    def varrow(x, y1, y2, label="", side=1, color=INK):
        dr.line([(x, y1), (x, y2 - 10)], fill=color, width=3)
        dr.polygon([(x - 6, y2 - 10), (x, y2), (x + 6, y2 - 10)], fill=color)
        if label:
            ct(dr, (x + side * 12, (y1 + y2) / 2), label, 15, color, anchor="lm" if side > 0 else "rm")

    # x 通路（横向）
    pbox(px + 60, py + 30, "x_in", "", LBLUE, BLUE)
    pbox(px + 240, py + 30, "寄存器", "1 拍", "white", INK)
    pbox(px + 420, py + 30, "x_out", "", LBLUE, BLUE)
    dr.line([(px + 135, py + 30), (px + 165, py + 30)], fill=INK, width=3)
    dr.polygon([(px + 165, py + 24), (px + 175, py + 30), (px + 165, py + 36)], fill=INK)
    dr.line([(px + 315, py + 30), (px + 345, py + 30)], fill=INK, width=3)
    dr.polygon([(px + 345, py + 24), (px + 355, py + 30), (px + 345, py + 36)], fill=INK)
    # x_in 下行支路到乘法器
    dr.line([(px + 90, py + 58), (px + 90, py + 150)], fill=GREEN, width=3)
    dr.line([(px + 90, py + 150), (px + 130, py + 150)], fill=GREEN, width=3)
    dr.polygon([(px + 130, py + 144), (px + 140, py + 150), (px + 130, py + 156)], fill=GREEN)
    # 权重
    pbox(px + 240, py + 130, "w_hold", "load 装入", "white", ORANGE)
    dr.line([(px + 240, py + 158), (px + 240, py + 190)], fill=ORANGE, width=3)
    dr.polygon([(px + 234, py + 190), (px + 240, py + 200), (px + 246, py + 190)], fill=ORANGE)
    # 乘法器
    pbox(px + 240, py + 230, "MULT8_WALLACE", "w×x 组合", "white", INK, 180)
    dr.line([(px + 140, py + 150), (px + 170, py + 150), (px + 170, py + 210), (px + 150, py + 210)], fill=GREEN, width=3)
    # 加法器
    pbox(px + 240, py + 330, "ADDER (19位)", "p_in + 积", "white", INK, 170)
    dr.line([(px + 240, py + 258), (px + 240, py + 292)], fill=INK, width=3)
    dr.polygon([(px + 234, py + 292), (px + 240, py + 302), (px + 246, py + 292)], fill=INK)
    # p_in / p_out
    ct(dr, (px + 420, py + 236), "p_in（上方 PE）", 15, ORANGE)
    varrow(px + 420, py + 252, py + 320, "", 1, ORANGE)
    dr.line([(px + 420, py + 320), (px + 330, py + 330)], fill=ORANGE, width=3)
    dr.polygon([(px + 330, py + 324), (px + 320, py + 330), (px + 330, py + 336)], fill=ORANGE)
    pbox(px + 240, py + 420, "寄存器", "1 拍")
    dr.line([(px + 240, py + 358), (px + 240, py + 382)], fill=INK, width=3)
    dr.polygon([(px + 234, py + 382), (px + 240, py + 392), (px + 246, py + 382)], fill=INK)
    varrow(px + 240, py + 448, py + 520, "p_out（送下方 PE）", 1, ORANGE)
    ct(dr, (px + 210, py + 560), "每拍：p_out ≤ p_in + w·x_in；x_out ≤ x_in", 17, INK)

    img.save(os.path.join(OUTDIR, "fig_lab3_systolic.png"), dpi=(150, 150))
    print("fig_lab3_systolic.png")


if __name__ == "__main__":
    fig_kogge_stone()
    fig_wallace()
    fig_systolic()