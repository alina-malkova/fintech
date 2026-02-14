#!/usr/bin/env python3
"""
Event Study Plot
Publication-quality visualization of dynamic effects around branch closures
"""

import matplotlib.pyplot as plt
import numpy as np

# Set publication-quality style
plt.rcParams.update({
    'font.family': 'serif',
    'font.size': 11,
    'axes.labelsize': 12,
    'axes.titlesize': 13,
    'xtick.labelsize': 10,
    'ytick.labelsize': 10,
    'legend.fontsize': 10,
    'figure.dpi': 150,
    'savefig.dpi': 300,
    'savefig.bbox': 'tight',
    'axes.spines.top': False,
    'axes.spines.right': False,
})

# Data from Stata event study output
# Event times (t=-1 is omitted reference)
event_times = [-4, -3, -2, 0, 1, 2, 3, 4]

# Full sample coefficients
coef_full = [-0.0476, -0.0029, -0.0151, -0.0100, -0.0074, -0.0079, -0.0282, 0.0000]
se_full = [0.0410, 0.0198, 0.0197, 0.0155, 0.0228, 0.0279, 0.0366, 0.0001]

# High fintech counties
coef_high = [0.0000, 0.0000, -0.5068, -0.0018, 0.0054, 0.0829, -0.0068, -0.0008]
se_high = [0.0001, 0.0001, 0.3892, 0.0271, 0.0205, 0.0568, 0.0233, 0.0220]

# Low fintech counties
coef_low = [0.0000, 0.0203, 0.0046, 0.0108, 0.0549, -0.0046, 0.0488, 0.1709]
se_low = [0.0001, 0.0233, 0.0183, 0.0107, 0.0314, 0.0163, 0.0510, 0.0836]

# Insert reference period (t=-1) with coefficient = 0
event_times_full = [-4, -3, -2, -1, 0, 1, 2, 3, 4]
coef_full_plot = coef_full[:3] + [0] + coef_full[3:]
se_full_plot = se_full[:3] + [0] + se_full[3:]
coef_high_plot = coef_high[:3] + [0] + coef_high[3:]
se_high_plot = se_high[:3] + [0] + se_high[3:]
coef_low_plot = coef_low[:3] + [0] + coef_low[3:]
se_low_plot = se_low[:3] + [0] + se_low[3:]

# Colors
color_high = '#27ae60'  # Green for high fintech
color_low = '#c0392b'   # Red for low fintech
color_full = '#2c3e50'  # Dark gray for full sample

# Create figure with two panels
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5.5))

# ============================================
# Panel A: Full Sample Event Study
# ============================================
x = np.array(event_times_full)
coef = np.array(coef_full_plot)
se = np.array(se_full_plot)

# Confidence intervals
ci_low = coef - 1.96 * se
ci_high = coef + 1.96 * se

# Shaded CI region
ax1.fill_between(x, ci_low, ci_high, alpha=0.2, color=color_full, linewidth=0)

# Point estimates
ax1.plot(x, coef, 'o-', color=color_full, linewidth=2, markersize=8,
         markerfacecolor='white', markeredgewidth=2, label='Point estimate')

# Reference line at zero
ax1.axhline(y=0, color='black', linestyle='-', linewidth=0.8, alpha=0.5)

# Vertical line at treatment (t=0)
ax1.axvline(x=0, color='gray', linestyle='--', linewidth=1, alpha=0.5)

# Reference period marker
ax1.scatter([-1], [0], marker='D', s=100, color=color_full, zorder=10,
            edgecolors='white', linewidths=1.5)

# Labels
ax1.set_xlabel('Years Relative to Branch Closure', fontweight='bold')
ax1.set_ylabel('Effect on Self-Employment Rate', fontweight='bold')
ax1.set_title('A. Full Sample', fontweight='bold', loc='left', fontsize=13)

# Annotations
ax1.annotate('Pre-trends\n(parallel)', xy=(-3, 0.02), fontsize=9,
             style='italic', color='#666666', ha='center')
ax1.annotate('Post-closure', xy=(2, -0.04), fontsize=9,
             style='italic', color='#666666', ha='center')
ax1.annotate('Reference\nperiod', xy=(-1, -0.06), fontsize=8,
             ha='center', color=color_full)

ax1.set_xticks(event_times_full)
ax1.set_xlim(-4.5, 4.5)
ax1.set_ylim(-0.12, 0.08)

# Add grid
ax1.grid(True, alpha=0.3, linestyle=':')

# ============================================
# Panel B: By Fintech Level
# ============================================
x = np.array(event_times_full)

# High fintech
coef_h = np.array(coef_high_plot)
se_h = np.array(se_high_plot)
ci_low_h = coef_h - 1.96 * se_h
ci_high_h = coef_h + 1.96 * se_h

# Low fintech
coef_l = np.array(coef_low_plot)
se_l = np.array(se_low_plot)
ci_low_l = coef_l - 1.96 * se_l
ci_high_l = coef_l + 1.96 * se_l

# Offset for visibility
offset = 0.1

# High fintech (slightly left)
ax2.fill_between(x - offset, ci_low_h, ci_high_h, alpha=0.15, color=color_high, linewidth=0)
ax2.plot(x - offset, coef_h, 'o-', color=color_high, linewidth=2, markersize=7,
         markerfacecolor='white', markeredgewidth=2, label='High fintech counties')

# Low fintech (slightly right)
ax2.fill_between(x + offset, ci_low_l, ci_high_l, alpha=0.15, color=color_low, linewidth=0)
ax2.plot(x + offset, coef_l, 's-', color=color_low, linewidth=2, markersize=7,
         markerfacecolor='white', markeredgewidth=2, label='Low fintech counties')

# Reference lines
ax2.axhline(y=0, color='black', linestyle='-', linewidth=0.8, alpha=0.5)
ax2.axvline(x=0, color='gray', linestyle='--', linewidth=1, alpha=0.5)

# Reference period markers
ax2.scatter([-1 - offset], [0], marker='D', s=80, color=color_high, zorder=10,
            edgecolors='white', linewidths=1.5)
ax2.scatter([-1 + offset], [0], marker='D', s=80, color=color_low, zorder=10,
            edgecolors='white', linewidths=1.5)

# Labels
ax2.set_xlabel('Years Relative to Branch Closure', fontweight='bold')
ax2.set_ylabel('Effect on Self-Employment Rate', fontweight='bold')
ax2.set_title('B. By Fintech Penetration Level', fontweight='bold', loc='left', fontsize=13)

# Legend
ax2.legend(loc='upper left', frameon=True, fancybox=False, edgecolor='gray')

ax2.set_xticks(event_times_full)
ax2.set_xlim(-4.5, 4.5)

# Add grid
ax2.grid(True, alpha=0.3, linestyle=':')

# Annotation for divergence
ax2.annotate('Divergence\npost-closure', xy=(3, 0.15), fontsize=9,
             style='italic', color='#666666', ha='center',
             arrowprops=dict(arrowstyle='->', color='#999999', lw=1),
             xytext=(3, 0.25))

# Overall title
fig.suptitle('Event Study: Self-Employment Dynamics Around Branch Closures',
             fontsize=14, fontweight='bold', y=1.02)

plt.tight_layout()

plt.savefig('event_study.png', dpi=300, bbox_inches='tight',
            facecolor='white', edgecolor='none')
plt.savefig('event_study.pdf', bbox_inches='tight',
            facecolor='white', edgecolor='none')

print("Event study plots saved!")
print(f"  - event_study.png")
print(f"  - event_study.pdf")
