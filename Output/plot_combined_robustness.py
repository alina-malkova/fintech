#!/usr/bin/env python3
"""
Combined Robustness Figures for Paper
Publication-quality visualizations
"""

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import Patch
from matplotlib.lines import Line2D

# Set publication-quality style
plt.rcParams.update({
    'font.family': 'serif',
    'font.size': 10,
    'axes.labelsize': 11,
    'axes.titlesize': 12,
    'xtick.labelsize': 9,
    'ytick.labelsize': 9,
    'legend.fontsize': 9,
    'figure.dpi': 150,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
    'axes.spines.top': False,
    'axes.spines.right': False,
    'axes.linewidth': 0.8,
})

# ============================================
# Figure 1: Simplified Specification Curve
# ============================================

fig1, ax1 = plt.subplots(figsize=(8, 5))

# Data
specs = [
    ('No FE', 0.048, 0.122, False),
    ('Year FE', 0.034, 0.123, False),
    ('County FE', -0.082, 0.129, False),
    ('County+Year FE', -0.085, 0.134, False),
    ('Individual+Year FE', -0.449, 0.969, False),
    ('MergerID FE', 0.726, 0.593, False),
    ('MergerID+Year FE\n(Baseline)', 0.822, 0.362, True),
    ('Pre-2012 only', 0.486, 0.725, False),
    ('Post-2012 only', 1.605, 0.853, False),
]

# Sort by coefficient
specs_sorted = sorted(specs, key=lambda x: x[1])

labels = [s[0] for s in specs_sorted]
coefs = [s[1] for s in specs_sorted]
ses = [s[2] for s in specs_sorted]
is_baseline = [s[3] for s in specs_sorted]

x = np.arange(len(specs_sorted))
ci_low = [c - 1.96*s for c, s in zip(coefs, ses)]
ci_high = [c + 1.96*s for c, s in zip(coefs, ses)]

# Colors
colors = ['#e74c3c' if b else '#3498db' for b in is_baseline]
alphas = [1.0 if b else 0.7 for b in is_baseline]

# Plot
for i, (coef, low, high, color, alpha) in enumerate(zip(coefs, ci_low, ci_high, colors, alphas)):
    ax1.plot([i, i], [low, high], color=color, linewidth=2.5, alpha=alpha)
    marker = 'D' if is_baseline[i] else 'o'
    size = 120 if is_baseline[i] else 80
    ax1.scatter(i, coef, color=color, s=size, marker=marker, zorder=10,
               edgecolors='white', linewidths=1.5)

# Reference line
ax1.axhline(y=0, color='black', linestyle='-', linewidth=1, alpha=0.4)

# Shading
ax1.axhspan(0, 3, alpha=0.03, color='green')
ax1.axhspan(-2, 0, alpha=0.03, color='red')

# Labels
ax1.set_xticks(x)
ax1.set_xticklabels(labels, rotation=45, ha='right')
ax1.set_ylabel('Coefficient on Closure × Fintech\n(with 95% CI)', fontweight='bold')
ax1.set_xlabel('')
ax1.set_xlim(-0.5, len(specs_sorted) - 0.5)
ax1.set_ylim(-2.5, 3.5)

# Legend
legend_elements = [
    Line2D([0], [0], marker='D', color='w', markerfacecolor='#e74c3c',
           markersize=10, label='Baseline specification'),
    Line2D([0], [0], marker='o', color='w', markerfacecolor='#3498db',
           markersize=8, label='Alternative specifications'),
]
ax1.legend(handles=legend_elements, loc='upper left', frameon=True,
           fancybox=False, edgecolor='#cccccc')

# Title
ax1.set_title('Specification Curve: Robustness of Fintech Mitigation Effect',
              fontweight='bold', pad=15)

# Annotation
ax1.annotate('Positive effect requires\nMergerID fixed effects',
             xy=(7, 1.8), fontsize=9, style='italic', color='#666666',
             ha='center', bbox=dict(boxstyle='round,pad=0.3', facecolor='white',
                                    edgecolor='#cccccc', alpha=0.9))

plt.tight_layout()
plt.savefig('specification_curve_clean.png', dpi=300, bbox_inches='tight',
            facecolor='white', edgecolor='none')
plt.savefig('specification_curve_clean.pdf', bbox_inches='tight',
            facecolor='white', edgecolor='none')
plt.close()

# ============================================
# Figure 2: Clean Event Study
# ============================================

fig2, ax2 = plt.subplots(figsize=(8, 5))

# Simplified event study data (using full sample)
event_times = [-4, -3, -2, -1, 0, 1, 2, 3, 4]
coef_full = [-0.048, -0.003, -0.015, 0, -0.010, -0.007, -0.008, -0.028, 0.000]
se_full = [0.041, 0.020, 0.020, 0, 0.016, 0.023, 0.028, 0.037, 0.001]

x = np.array(event_times)
coef = np.array(coef_full)
se = np.array(se_full)

ci_low = coef - 1.96 * se
ci_high = coef + 1.96 * se

# Shaded CI region
ax2.fill_between(x, ci_low, ci_high, alpha=0.25, color='#2c3e50', linewidth=0,
                 label='95% Confidence Interval')

# Point estimates
ax2.plot(x, coef, 'o-', color='#2c3e50', linewidth=2.5, markersize=9,
         markerfacecolor='white', markeredgewidth=2.5, label='Point Estimate',
         zorder=5)

# Reference period diamond
ax2.scatter([-1], [0], marker='D', s=150, color='#e74c3c', zorder=10,
            edgecolors='white', linewidths=2, label='Reference Period (t=-1)')

# Reference lines
ax2.axhline(y=0, color='black', linestyle='-', linewidth=1, alpha=0.4)
ax2.axvline(x=0, color='#e74c3c', linestyle='--', linewidth=1.5, alpha=0.6)

# Shading for pre/post
ax2.axvspan(-4.5, -0.5, alpha=0.03, color='blue')
ax2.axvspan(-0.5, 4.5, alpha=0.03, color='orange')

# Annotations
ax2.annotate('Pre-closure', xy=(-2.5, 0.06), fontsize=10, fontweight='bold',
             color='#2980b9', ha='center')
ax2.annotate('Post-closure', xy=(2, 0.06), fontsize=10, fontweight='bold',
             color='#d35400', ha='center')
ax2.annotate('Branch\nClosure', xy=(0, -0.10), fontsize=9, color='#e74c3c',
             ha='center', fontweight='bold')

# Labels
ax2.set_xlabel('Years Relative to Branch Closure', fontweight='bold', fontsize=11)
ax2.set_ylabel('Effect on Self-Employment Rate\n(Percentage Points)', fontweight='bold')
ax2.set_xticks(event_times)
ax2.set_xlim(-4.5, 4.5)
ax2.set_ylim(-0.12, 0.08)

# Grid
ax2.grid(True, alpha=0.3, linestyle=':', axis='y')

# Legend
ax2.legend(loc='lower left', frameon=True, fancybox=False, edgecolor='#cccccc')

# Title
ax2.set_title('Event Study: Self-Employment Dynamics Around Branch Closures',
              fontweight='bold', pad=15)

# Key finding annotation
ax2.annotate('Pre-trends near zero\nsupports parallel trends',
             xy=(-3, -0.08), fontsize=9, style='italic', color='#666666',
             ha='center', bbox=dict(boxstyle='round,pad=0.3', facecolor='white',
                                    edgecolor='#cccccc', alpha=0.9))

plt.tight_layout()
plt.savefig('event_study_clean.png', dpi=300, bbox_inches='tight',
            facecolor='white', edgecolor='none')
plt.savefig('event_study_clean.pdf', bbox_inches='tight',
            facecolor='white', edgecolor='none')
plt.close()

# ============================================
# Figure 3: Coefficient Comparison Bar Chart
# ============================================

fig3, ax3 = plt.subplots(figsize=(7, 5))

# Key specifications to highlight
key_specs = [
    ('No Fixed\nEffects', 0.048, 0.122),
    ('County\nFE', -0.085, 0.134),
    ('Individual\nFE', -0.449, 0.969),
    ('MergerID\nFE (Baseline)', 0.822, 0.362),
    ('Post-2012\nSample', 1.605, 0.853),
]

labels = [s[0] for s in key_specs]
coefs = [s[1] for s in key_specs]
ses = [s[2] for s in key_specs]

x = np.arange(len(key_specs))
width = 0.6

# Colors based on significance
colors = []
for c, s in zip(coefs, ses):
    pval = 2 * (1 - 0.5)  # placeholder
    t_stat = abs(c / s)
    if t_stat > 1.96:
        colors.append('#27ae60')  # Green for significant
    elif t_stat > 1.645:
        colors.append('#f39c12')  # Orange for marginal
    else:
        colors.append('#95a5a6')  # Gray for insignificant

# Manually set colors based on actual p-values
colors = ['#95a5a6', '#95a5a6', '#95a5a6', '#27ae60', '#f39c12']

bars = ax3.bar(x, coefs, width, color=colors, edgecolor='white', linewidth=1.5)

# Error bars
ax3.errorbar(x, coefs, yerr=[1.96*s for s in ses], fmt='none',
             color='#2c3e50', capsize=5, capthick=2, linewidth=2)

# Reference line
ax3.axhline(y=0, color='black', linestyle='-', linewidth=1, alpha=0.5)

# Labels
ax3.set_xticks(x)
ax3.set_xticklabels(labels, fontsize=9)
ax3.set_ylabel('Coefficient on Closure × Fintech', fontweight='bold')
ax3.set_ylim(-2, 3)

# Legend
legend_elements = [
    Patch(facecolor='#27ae60', edgecolor='white', label='Significant (p < 0.05)'),
    Patch(facecolor='#f39c12', edgecolor='white', label='Marginal (p < 0.10)'),
    Patch(facecolor='#95a5a6', edgecolor='white', label='Not Significant'),
]
ax3.legend(handles=legend_elements, loc='upper left', frameon=True,
           fancybox=False, edgecolor='#cccccc')

# Title
ax3.set_title('Key Specification Comparison:\nFintech Mitigation Effect by Model',
              fontweight='bold', pad=15)

# Annotation
ax3.annotate('Identification requires\nmerger-group FE',
             xy=(3, 2.2), fontsize=9, style='italic', color='#666666',
             ha='center', arrowprops=dict(arrowstyle='->', color='#999999'),
             xytext=(2, 2.7))

plt.tight_layout()
plt.savefig('coefficient_comparison.png', dpi=300, bbox_inches='tight',
            facecolor='white', edgecolor='none')
plt.savefig('coefficient_comparison.pdf', bbox_inches='tight',
            facecolor='white', edgecolor='none')
plt.close()

print("Clean publication figures saved!")
print("  - specification_curve_clean.png/pdf")
print("  - event_study_clean.png/pdf")
print("  - coefficient_comparison.png/pdf")
