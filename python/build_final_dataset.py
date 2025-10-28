#!/usr/bin/env python3
"""
Build FINAL Meta-Learning Dataset with Maximum Real Data

Combines:
- 275 REAL published meta-analyses (from literature)
- 4725 realistic synthetic examples
- Total: 5000 samples

Author: CBAMMR Development Team
Date: 2025-10-28
"""

import sys
sys.path.append('python')

from real_metaanalyses_database import create_comprehensive_real_database
import json
import numpy as np
import pandas as pd
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')


def generate_optimized_synthetic(n_samples: int = 4725) -> list:
    """Generate optimized synthetic examples."""
    np.random.seed(42)

    domains = ['cardiology', 'oncology', 'psychiatry', 'neurology',
              'endocrinology', 'rheumatology', 'gastroenterology',
              'infectious_disease', 'immunology', 'nephrology',
              'pulmonology', 'dermatology', 'ophthalmology', 'urology']

    outcome_types = ['OR', 'RR', 'SMD', 'MD', 'HR', 'COR']

    generated = []

    for i in range(n_samples):
        k = int(np.random.lognormal(mean=2.5, sigma=0.6))
        k = max(5, min(k, 100))

        domain = np.random.choice(domains)
        outcome = np.random.choice(outcome_types)

        year_median = int(np.random.normal(2012, 6))
        year_range = int(np.random.lognormal(mean=2.0, sigma=0.7))
        year_range = max(3, min(year_range, 30))

        total_n = int(np.random.lognormal(mean=7.5, sigma=1.5))
        total_n = max(100, min(total_n, 500000))

        # I² with realistic distribution
        i2_category = np.random.choice(['low', 'moderate', 'substantial', 'high'],
                                      p=[0.25, 0.30, 0.25, 0.20])

        if i2_category == 'low':
            I2 = np.random.beta(2, 8) * 25
        elif i2_category == 'moderate':
            I2 = 25 + np.random.beta(2, 2) * 25
        elif i2_category == 'substantial':
            I2 = 50 + np.random.beta(2, 2) * 25
        else:
            I2 = 75 + np.random.beta(2, 5) * 25

        I2 = max(0, min(I2, 99.9))

        # τ² based on outcome type and I²
        if outcome in ['OR', 'RR', 'HR']:
            tau2_base = 0.01 + (I2/100) * 0.25
        elif outcome in ['SMD']:
            tau2_base = 0.02 + (I2/100) * 0.40
        else:
            tau2_base = 0.05 + (I2/100) * 1.50

        tau2 = np.random.lognormal(mean=np.log(tau2_base), sigma=0.5)
        tau2 = max(0, tau2)

        # Q statistic
        Q_expected = k / (1 - I2/100) if I2 < 99 else k * 10
        Q = np.random.gamma(shape=Q_expected/2, scale=2)

        # Pooled effect
        if outcome in ['OR', 'RR', 'HR']:
            pooled_effect = np.random.lognormal(mean=-0.1, sigma=0.4)
        elif outcome == 'SMD':
            pooled_effect = np.random.normal(0, 0.5)
        elif outcome == 'MD':
            pooled_effect = np.random.normal(0, 2.0)
        else:
            pooled_effect = np.random.normal(0, 0.3)
            pooled_effect = max(-0.95, min(pooled_effect, 0.95))

        # CI width
        ci_width_base = 0.15 * (1 + I2/100) / np.sqrt(total_n/1000)
        ci_width = np.random.lognormal(mean=np.log(ci_width_base), sigma=0.3)

        dataset = {
            'dataset_id': f'Synthetic_{i+1:05d}',
            'source': 'generated',
            'domain': domain,
            'outcome_measure': outcome,
            'n_studies': int(k),
            'year_median': int(year_median),
            'year_range': int(year_range),
            'I2': round(float(I2), 2),
            'tau2': round(float(tau2), 4),
            'Q': round(float(Q), 2),
            'pooled_effect': round(float(pooled_effect), 3),
            'ci_width': round(float(ci_width), 3),
            'total_n': int(total_n),
            'reference': 'Generated based on literature patterns'
        }

        generated.append(dataset)

    return generated


def main():
    """Main execution."""
    print("=" * 80)
    print("Building FINAL Meta-Learning Dataset")
    print("=" * 80)
    print()

    # Create output directory
    output_dir = Path("data/metalearning/training")
    output_dir.mkdir(parents=True, exist_ok=True)

    # Get REAL meta-analyses (275)
    print("Loading REAL meta-analyses from literature...")
    real_mas = create_comprehensive_real_database()
    print(f"  ✅ {len(real_mas)} REAL meta-analyses loaded")

    # Generate synthetic (4725)
    print(f"\nGenerating optimized synthetic examples...")
    n_synthetic = 5000 - len(real_mas)
    synthetic = generate_optimized_synthetic(n_samples=n_synthetic)
    print(f"  ✅ {len(synthetic)} synthetic examples generated")

    # Combine
    all_data = real_mas + synthetic
    df = pd.DataFrame(all_data)

    print(f"\n{'='*80}")
    print(f"FINAL DATASET STATISTICS")
    print(f"{'='*80}")
    print(f"Total samples: {len(df)}")
    print(f"  - REAL published: {len(real_mas)} ({100*len(real_mas)/len(df):.1f}%)")
    print(f"  - Synthetic: {len(synthetic)} ({100*len(synthetic)/len(df):.1f}%)")
    print(f"{'='*80}")

    # Add derived features
    print("\nEngineering features...")
    df['studies_per_year'] = df['n_studies'] / df['year_range'].clip(lower=1)
    df['avg_n_per_study'] = df['total_n'] / df['n_studies']
    df['log_total_n'] = np.log(df['total_n'])
    df['sqrt_k'] = np.sqrt(df['n_studies'])
    df['I2_category'] = pd.cut(df['I2'], bins=[0, 25, 50, 75, 100],
                                labels=['low', 'moderate', 'substantial', 'high'])

    # Summary statistics
    print("\n" + "=" * 80)
    print("DETAILED STATISTICS")
    print("=" * 80)

    print(f"\n📊 I² Statistics:")
    print(f"  Mean: {df['I2'].mean():.1f}%")
    print(f"  Median: {df['I2'].median():.1f}%")
    print(f"  Std: {df['I2'].std():.1f}%")
    print(f"  Range: {df['I2'].min():.1f}% - {df['I2'].max():.1f}%")

    print(f"\n📊 I² Categories:")
    i2_cats = df['I2_category'].value_counts().sort_index()
    for cat, count in i2_cats.items():
        print(f"  {cat:12s}: {count:4d} ({100*count/len(df):5.1f}%)")

    print(f"\n📊 τ² Statistics:")
    print(f"  Mean: {df['tau2'].mean():.4f}")
    print(f"  Median: {df['tau2'].median():.4f}")
    print(f"  Range: {df['tau2'].min():.4f} - {df['tau2'].max():.4f}")

    print(f"\n📊 Studies per Meta-Analysis:")
    print(f"  Mean: {df['n_studies'].mean():.1f}")
    print(f"  Median: {df['n_studies'].median():.1f}")
    print(f"  Range: {df['n_studies'].min()}-{df['n_studies'].max()}")

    print(f"\n📊 Outcome Types:")
    for outcome, count in df['outcome_measure'].value_counts().items():
        print(f"  {outcome:5s}: {count:4d} ({100*count/len(df):5.1f}%)")

    print(f"\n📊 Domains (Top 10):")
    for domain, count in df['domain'].value_counts().head(10).items():
        print(f"  {domain:20s}: {count:4d} ({100*count/len(df):5.1f}%)")

    # Save dataset
    output_file = output_dir / "metalearning_training_data_FINAL.csv"
    df.to_csv(output_file, index=False)
    print(f"\n✅ Saved training dataset to: {output_file}")

    # Save as JSON
    json_file = output_dir / "metalearning_training_data_FINAL.json"
    df.to_json(json_file, orient='records', indent=2)
    print(f"✅ Saved JSON format to: {json_file}")

    # Save comprehensive summary
    summary = {
        'total_samples': int(len(df)),
        'real_published': int(len(real_mas)),
        'synthetic': int(len(synthetic)),
        'real_percentage': round(100*len(real_mas)/len(df), 2),
        'sources': {
            'real': int(len(real_mas)),
            'synthetic': int(len(synthetic))
        },
        'I2_stats': {
            'mean': float(df['I2'].mean()),
            'median': float(df['I2'].median()),
            'std': float(df['I2'].std()),
            'min': float(df['I2'].min()),
            'max': float(df['I2'].max())
        },
        'tau2_stats': {
            'mean': float(df['tau2'].mean()),
            'median': float(df['tau2'].median()),
            'std': float(df['tau2'].std()),
            'min': float(df['tau2'].min()),
            'max': float(df['tau2'].max())
        },
        'k_stats': {
            'mean': float(df['n_studies'].mean()),
            'median': float(df['n_studies'].median()),
            'min': int(df['n_studies'].min()),
            'max': int(df['n_studies'].max())
        },
        'outcome_types': df['outcome_measure'].value_counts().to_dict(),
        'domains': df['domain'].value_counts().to_dict(),
        'I2_categories': {str(k): int(v) for k, v in df['I2_category'].value_counts().to_dict().items()}
    }

    summary_file = output_dir / "training_data_summary_FINAL.json"
    with open(summary_file, 'w') as f:
        json.dump(summary, f, indent=2)
    print(f"✅ Saved summary to: {summary_file}")

    print("\n" + "=" * 80)
    print("✅ FINAL DATASET COMPLETE!")
    print(f"✅ {len(df)} total samples")
    print(f"✅ {len(real_mas)} REAL meta-analyses ({100*len(real_mas)/len(df):.1f}%)")
    print(f"✅ Ready for training!")
    print("=" * 80)

    return df


if __name__ == "__main__":
    df = main()
