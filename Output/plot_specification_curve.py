#!/usr/bin/env python3
"""
Specification Curve Plot
Publication-quality visualization of robustness across model specifications
"""

import pandas as pd
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

# Data from Stata output
data = {
    'spec_id': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    'spec_desc': [
        'No FE, robust',
        'Year FE, robust',
        'MergerID FE, robust',
        'MergerID+Year FE, robust',
        'County FE, robust',
        'BASELINE: MergerID+Year,\ncounty cluster',
        'MergerID+Year FE,\nmergerID cluster',
        'County+Year FE,\ncounty cluster',
        'Alternative outcome\n(anytouse)',
        'Pre-2012 sample',
        'Post-2012 sample',
        'Individual+Year FE'
    ],
    'coef': [0.0479, 0.0338, 0.7262, 0.8224, -0.0824, 0.8224, 0.8224, -0.0853, -2.3878, 0.4859, 1.6050, -0.4494],
    'se': [0.1225, 0.1230, 0.5927, 0.5859, 0.1288, 0.3617, 0.3396, 0.1343, 3.4779, 0.7251, 0.8526, 0.9690],
    'pval': [0.696, 0.784, 0.221, 0.161, 0.522, 0.027, 0.046, 0.526, 0.495, 0.506, 0.066, 0.645],
    'n_obs': [13027, 13027, 484, 484, 12961, 484, 484, 12961, 485, 365, 246, 456]
}

df = pd.DataFrame(data)

# Sort by coefficient for the curve
df_sorted = df.sort_values('coef').reset_index(drop=True)

# Calculate confidence intervals
df_sorted['ci_low'] = df_sorted['coef'] - 1.96 * df_sorted['se']
df_sorted['ci_high'] = df_sorted['coef'] + 1.96 * df_sorted['se']

# Significance indicators
df_sorted['sig_05'] = df_sorted['pval'] < 0.05
df_sorted['sig_10'] = (df_sorted['pval'] >= 0.05) & (df_sorted['pval'] < 0.10)

# Create figure with two panels
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(10, 8), height_ratios=[3, 1.5],
                                gridspec_kw={'hspace': 0.05})

# Colors
color_sig05 = '#1a5276'  # Dark blue for p<0.05
color_sig10 = '#2874a6'  # Medium blue for p<0.10
color_insig = '#85929e'  # Gray for insignificant
color_baseline = '#e74c3c'  # Red for baseline

# Top panel: Coefficient estimates with CIs
x = np.arange(len(df_sorted))

for i, row in df_sorted.iterrows():
    # Determine color
    if 'BASELINE' in row['spec_desc']:
        color = color_baseline
        marker = 'D'
        markersize = 10
        zorder = 10
    elif row['sig_05']:
        color = color_sig05
        marker = 'o'
        markersize = 8
        zorder = 5
    elif row['sig_10']:
        color = color_sig10
        marker = 'o'
        markersize = 8
        zorder = 5
    else:
        color = color_insig
        marker = 'o'
        markersize = 7
        zorder = 3

    # Plot point
    ax1.scatter(i, row['coef'], color=color, marker=marker, s=markersize**2,
                zorder=zorder, edgecolors='white', linewidths=0.5)

    # Plot CI
    ax1.plot([i, i], [row['ci_low'], row['ci_high']], color=color,
             linewidth=1.5, alpha=0.7, zorder=zorder-1)

# Reference line at zero
ax1.axhline(y=0, color='black', linestyle='-', linewidth=0.8, alpha=0.5)

# Shade positive region
ax1.axhspan(0, ax1.get_ylim()[1], alpha=0.05, color='green')
ax1.axhspan(ax1.get_ylim()[0], 0, alpha=0.05, color='red')

ax1.set_ylabel('Coefficient on Closure × Fintech', fontweight='bold')
ax1.set_xlim(-0.5, len(df_sorted) - 0.5)
ax1.set_xticks([])

# Add legend
from matplotlib.lines import Line2D
legend_elements = [
    Line2D([0], [0], marker='D', color='w', markerfacecolor=color_baseline,
           markersize=10, label='Baseline specification'),
    Line2D([0], [0], marker='o', color='w', markerfacecolor=color_sig05,
           markersize=8, label='p < 0.05'),
    Line2D([0], [0], marker='o', color='w', markerfacecolor=color_sig10,
           markersize=8, label='p < 0.10'),
    Line2D([0], [0], marker='o', color='w', markerfacecolor=color_insig,
           markersize=7, label='Not significant'),
]
ax1.legend(handles=legend_elements, loc='upper left', frameon=True,
           fancybox=False, edgecolor='gray')

# Add annotation for key finding
ax1.annotate('MergerID FE crucial\nfor identification',
             xy=(9, 1.2), fontsize=9, style='italic', color='#666666',
             ha='center')

# Bottom panel: Specification indicators
spec_features = {
    'MergerID FE': [False, False, True, True, False, True, True, False, True, True, True, False],
    'Year FE': [False, True, False, True, False, True, True, True, True, True, True, True],
    'County FE': [False, False, False, False, True, False, False, True, False, False, False, False],
    'Individual FE': [False, False, False, False, False, False, False, False, False, False, False, True],
    'County cluster': [False, False, False, False, False, True, False, True, True, True, True, True],
}

# Reorder features according to sorted coefficients
sorted_indices = df_sorted['spec_id'].values - 1

feature_names = list(spec_features.keys())
n_features = len(feature_names)

for i, (feature, values) in enumerate(spec_features.items()):
    values_sorted = [values[idx] for idx in sorted_indices]
    for j, val in enumerate(values_sorted):
        if val:
            ax2.scatter(j, n_features - i - 1, marker='s', s=100,
                       color='#2c3e50', alpha=0.8)

ax2.set_yticks(range(n_features))
ax2.set_yticklabels(feature_names[::-1])
ax2.set_xlim(-0.5, len(df_sorted) - 0.5)
ax2.set_ylim(-0.5, n_features - 0.5)
ax2.set_xlabel('Specifications (ordered by coefficient estimate)', fontweight='bold')

# Add gridlines
ax2.set_xticks(x)
ax2.grid(True, axis='x', alpha=0.3, linestyle=':')
ax2.tick_params(axis='x', which='both', bottom=False, labelbottom=False)

# Title
fig.suptitle('Specification Curve: Fintech Mitigation of Branch Closure Effects',
             fontsize=14, fontweight='bold', y=0.98)

plt.savefig('specification_curve.png', dpi=300, bbox_inches='tight',
            facecolor='white', edgecolor='none')
plt.savefig('specification_curve.pdf', bbox_inches='tight',
            facecolor='white', edgecolor='none')

print("Specification curve plots saved!")
print(f"  - specification_curve.png")
print(f"  - specification_curve.pdf")
