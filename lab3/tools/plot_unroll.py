#!/usr/bin/env python3
"""Render Lab 3 x87 loop-unrolling performance data as a standalone SVG."""
import csv
from pathlib import Path

with Path('unroll_sweep.csv').open(newline='', encoding='utf-8') as handle:
    rows = [(int(row['factor']), float(row['gflops'])) for row in csv.DictReader(handle)]
if not rows:
    raise SystemExit('No measurements in unroll_sweep.csv')

width, height = 760, 450
left, right, top, bottom = 90, 35, 65, 85
chart_w, chart_h = width - left - right, height - top - bottom
upper = max(max(v for _, v in rows) * 1.2, 0.01)
coords = []
for i, (factor, value) in enumerate(rows):
    x = left + (i + 0.5) * chart_w / len(rows)
    y = top + chart_h * (1 - value / upper)
    coords.append((x, y, factor, value))

svg = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
    '<rect width="100%" height="100%" fill="white"/>',
    '<text x="380" y="36" font-family="sans-serif" font-size="20" text-anchor="middle">x87 loop-unrolling performance</text>',
    '<text x="25" y="55" font-family="sans-serif" font-size="13">GFLOPS</text>',
]
for tick in range(6):
    value = upper * tick / 5
    y = top + chart_h * (1 - tick / 5)
    svg.append(f'<line x1="{left}" y1="{y:.1f}" x2="{width-right}" y2="{y:.1f}" stroke="#dadde2"/>')
    svg.append(f'<text x="{left-10}" y="{y+4:.1f}" font-family="sans-serif" font-size="12" text-anchor="end">{value:.2f}</text>')
svg.append(f'<polyline points="{" ".join(f"{x:.1f},{y:.1f}" for x,y,_,_ in coords)}" fill="none" stroke="#275d96" stroke-width="3"/>')
for x, y, factor, value in coords:
    svg.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="6" fill="#275d96"/>')
    svg.append(f'<text x="{x:.1f}" y="{y-15:.1f}" text-anchor="middle" font-family="sans-serif" font-size="13">{value:.3f}</text>')
    svg.append(f'<text x="{x:.1f}" y="{height-bottom+23}" text-anchor="middle" font-family="sans-serif" font-size="14">{factor}</text>')
svg.append(f'<text x="{left+chart_w/2:.1f}" y="{height-23}" font-family="sans-serif" font-size="15" text-anchor="middle">Unroll factor (0 = baseline)</text>')
svg.append('</svg>')

Path('unroll_sweep.svg').write_text('\n'.join(svg), encoding='utf-8')
print('Saved unroll_sweep.svg')
