# -*- coding: utf-8 -*-
"""由 lab_1 / lab_2 的 wave.vcd 渲染教学波形图（供参考手册引用）"""
import os
from PIL import Image, ImageDraw, ImageFont

BASE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(BASE, "images")
FP = "C:/Windows/Fonts/msyh.ttc"


def font(sz):
    return ImageFont.truetype(FP, sz)


def parse_vcd(path):
    """返回 (timescale_fs, {fullname: [(time, value_int)]})"""
    with open(path, encoding="utf-8", errors="ignore") as f:
        text = f.read()
    id2name, signals = {}, {}
    scope_stack = []
    ts = 1
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        ln = lines[i].strip()
        if ln.startswith("$timescale"):
            nxt = lines[i + 1].strip() if not ln.endswith("1ps") else "1ps"
            ts = {"1ps": 1, "1ns": 1000}.get(nxt.split()[0], 1)
            i += 2
            continue
        if ln.startswith("$scope"):
            scope_stack.append(ln.split()[2])
        elif ln.startswith("$upscope"):
            scope_stack.pop()
        elif ln.startswith("$var"):
            parts = ln.split()
            full = ".".join(scope_stack + [parts[4]])
            id2name.setdefault(parts[3], []).append(full)
            signals.setdefault(full, [])
        elif ln.startswith("$enddefinitions"):
            i += 1
            break
        i += 1
    t = 0
    for ln in lines[i:]:
        ln = ln.strip()
        if not ln:
            continue
        if ln[0] == "#":
            t = int(ln[1:]) * ts
        elif ln[0] == "b":
            bits, vid = ln[1:].split()
            v = int(bits.replace("x", "0").replace("z", "0"), 2)
            for nm in id2name.get(vid, []):
                signals[nm].append((t, v))
        elif ln[0] in "01xz":
            v = 1 if ln[0] == "1" else 0
            for nm in id2name.get(ln[1:], []):
                signals[nm].append((t, v))
    return signals


def value_at(ev, t):
    v = ev[0][1] if ev else 0
    for tt, vv in ev:
        if tt > t:
            break
        v = vv
    return v


def render(title, specs, t_end_ns, out, t0_ns=0, grid_ns=2):
    """specs: [(label, fullname, kind)] kind: bit / hex"""
    W = 1060
    ROWH = 74 if len(specs) <= 5 else 62
    TOP, BOT = 110, 60
    H = TOP + ROWH * len(specs) + BOT
    img = Image.new("RGB", (W, H), "white")
    dr = ImageDraw.Draw(img)
    LM, RM = 210, 40
    X0, X1 = LM, W - RM

    def x_of(t_ns):
        return X0 + (t_ns - t0_ns) * (X1 - X0) / (t_end_ns - t0_ns)

    dr.text((W // 2, 40), title, font=font(26), fill=(20, 20, 20), anchor="mm")
    GREEN, BLUE, RED, GRID = (30, 140, 90), (30, 90, 180), (200, 60, 60), (222, 222, 222)
    for gx in range(int(t0_ns), int(t_end_ns) + 1, grid_ns):
        x = x_of(gx)
        dr.line([(x, TOP - 16), (x, H - BOT + 8)], fill=GRID)
        dr.text((x, H - BOT + 20), str(gx), font=font(13), fill=(120, 120, 120), anchor="ma")
    dr.text((W // 2, H - 22), "时间 (ns)", font=font(15), fill=(90, 90, 90), anchor="mm")

    for r, spec in enumerate(specs):
        label, full, kind = spec[0], spec[1], spec[2]
        ev = SIGNALS[full]
        y = TOP + r * ROWH + ROWH // 2
        dr.text((X0 - 14, y), label, font=font(16), fill=(30, 30, 30), anchor="rm")
        if kind == "bit":
            hh, lw = y - 20, y + 20
            steps = 600
            prev = None
            for s in range(steps + 1):
                t = t0_ns + (t_end_ns - t0_ns) * s / steps
                v = value_at(ev, t * 1000)
                x = x_of(t)
                if prev is not None and v != prev:
                    dr.line([(x, hh), (x, lw)], fill=GREEN, width=2)
                dr.line([(x, hh if v else lw), (x_of(t0_ns + (t_end_ns - t0_ns) * (s + 1) / steps), hh if v else lw)], fill=GREEN, width=2)
                prev = v
        else:  # hex 总线
            hh, lw = y - 20, y + 20
            t = t0_ns
            changes = [tt for tt, _ in ev]
            bounds = sorted(set([t0_ns] + [c / 1000 for c in changes if t0_ns < c / 1000 <= t_end_ns] + [t_end_ns]))
            for a, b in zip(bounds[:-1], bounds[1:]):
                xa, xb = x_of(a), x_of(b)
                v = value_at(ev, (a + 1e-9) * 1000 if a > t0_ns else a * 1000)
                dr.line([(xa, hh), (xb, hh)], fill=BLUE, width=2)
                dr.line([(xa, lw), (xb, lw)], fill=BLUE, width=2)
                dr.line([(xa, hh), (xa + 5, y)], fill=BLUE, width=1)
                dr.line([(xa, lw), (xa + 5, y)], fill=BLUE, width=1)
                if xb - xa > 56:
                    w = specs[r][3] if len(specs[r]) > 3 else 5
                    dr.text(((xa + xb) / 2 + 2, y), ("%0*X" % (w, v)), font=font(13), fill=(0, 60, 140), anchor="mm")
            dr.line([(x_of(t_end_ns), hh), (x_of(t_end_ns) - 5, y)], fill=BLUE, width=1)
            dr.line([(x_of(t_end_ns), lw), (x_of(t_end_ns) - 5, y)], fill=BLUE, width=1)
    img.save(out, dpi=(150, 150))
    print("saved", out)


# ---------------------------------------------------------------- lab_1
SIGNALS = parse_vcd(r"D:\vscode_workspace\Digital_lab\lab_1\sim\wave.vcd")
render(
    "实验一 19 位加法器仿真波形（定向激励段，wave.vcd 实测）",
    [("in1[18:0] (hex)", "tb_ADDER.in1", "hex"),
     ("in2[18:0] (hex)", "tb_ADDER.in2", "hex"),
     ("cin", "tb_ADDER.cin", "bit"),
     ("sum_ks[18:0] (hex)", "tb_ADDER.sum_ks", "hex"),
     ("cout_ks", "tb_ADDER.cout_ks", "bit")],
    100, os.path.join(OUT, "fig_lab1_waveform.png"), grid_ns=10)

# ---------------------------------------------------------------- lab_2
SIGNALS = parse_vcd(r"D:\vscode_workspace\Digital_lab\lab_2\sim\wave.vcd")
render(
    "实验二 8 位乘法器仿真波形（定向激励段，wave.vcd 实测）",
    [("in1[7:0] (hex)", "tb_MULT.in1", "hex", 2),
     ("in2[7:0] (hex)", "tb_MULT.in2", "hex", 2),
     ("res[15:0] (hex)", "tb_MULT.res", "hex", 4),
     ("ref[15:0] (hex)", "tb_MULT.ref", "hex", 4)],
    10, os.path.join(OUT, "fig_lab2_waveform.png"))