#!/usr/bin/env python3
"""
Process SYNERGY and other meta-analysis datasets for meta-learning.

SYNERGY dataset contains systematic review screening data (included/excluded)
but NOT effect sizes. This script extracts available metadata and creates
a template for processing datasets with actual effect size data.
"""

import os
import csv
import json
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import List, Optional, Dict
import re


@dataclass
class MetaAnalysisMetadata:
    """Metadata extracted from systematic review dataset"""
    dataset_id: str
    source: str  # 'synergy', 'metadat', 'github', 'manual'
    domain: str
    year: int
    n_papers_screened: int
    n_included: int
    n_excluded: int

    # Effect size data (if available)
    has_effect_sizes: bool = False
    outcome_measure: Optional[str] = None  # OR, RR, SMD, MD, HR, COR

    # Heterogeneity statistics (TARGET for ML)
    I2: Optional[float] = None
    tau2: Optional[float] = None
    Q: Optional[float] = None
    Q_pval: Optional[float] = None
    pooled_effect: Optional[float] = None
    pooled_ci_lower: Optional[float] = None
    pooled_ci_upper: Optional[float] = None

    # Additional metadata
    title: Optional[str] = None
    authors: Optional[str] = None
    reference: Optional[str] = None
    avg_title_length: Optional[float] = None
    avg_abstract_length: Optional[float] = None


class SynergyProcessor:
    """Process SYNERGY dataset systematic reviews"""

    def __init__(self, synergy_path: str):
        self.synergy_path = Path(synergy_path)
        self.index_file = self.synergy_path / "index.csv"
        self.datasets_dir = self.synergy_path / "datasets"

    def load_index(self) -> List[Dict]:
        """Load the index.csv metadata file"""
        with open(self.index_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            return list(reader)

    def process_all(self) -> List[MetaAnalysisMetadata]:
        """Process all SYNERGY datasets"""
        index_data = self.load_index()
        results = []

        for row in index_data:
            try:
                metadata = self._process_single_dataset(row)
                if metadata:
                    results.append(metadata)
            except Exception as e:
                print(f"Error processing {row.get('dataset_id')}: {e}")

        return results

    def _process_single_dataset(self, row: Dict) -> Optional[MetaAnalysisMetadata]:
        """Process a single SYNERGY dataset"""
        dataset_id = row['dataset_id']

        # Parse year (handle missing values)
        try:
            year = int(row['year']) if row['year'] else None
        except (ValueError, TypeError):
            year = None

        # Parse numeric fields
        try:
            n_papers = int(row['n_papers']) if row['n_papers'] else 0
            n_included = int(row['n_included']) if row['n_included'] else 0
            n_excluded = int(row['n_excluded']) if row['n_excluded'] else 0
            title_len = float(row['title_length']) if row.get('title_length') else None
            abstract_len = float(row['abstract_length']) if row.get('abstract_length') else None
        except (ValueError, TypeError) as e:
            print(f"Warning: Error parsing numeric fields for {dataset_id}: {e}")
            return None

        metadata = MetaAnalysisMetadata(
            dataset_id=dataset_id,
            source='synergy',
            domain=row.get('topic', 'Unknown'),
            year=year,
            n_papers_screened=n_papers,
            n_included=n_included,
            n_excluded=n_excluded,
            has_effect_sizes=False,  # SYNERGY doesn't have effect sizes
            title=row.get('title'),
            authors=row.get('authors'),
            reference=row.get('reference'),
            avg_title_length=title_len,
            avg_abstract_length=abstract_len
        )

        return metadata


class MetadatProcessor:
    """
    Process metadat package datasets (R package with 350+ meta-analysis datasets).

    NOTE: This requires R to be installed and the metadat package.
    For now, this is a template/placeholder for future implementation.
    """

    def __init__(self):
        self.has_rpy2 = self._check_rpy2()

    def _check_rpy2(self) -> bool:
        """Check if rpy2 is available"""
        try:
            import rpy2
            return True
        except ImportError:
            return False

    def process_all(self) -> List[MetaAnalysisMetadata]:
        """
        Process all metadat package datasets.

        Returns empty list for now - needs R integration.
        """
        if not self.has_rpy2:
            print("WARNING: rpy2 not available. Cannot process metadat datasets.")
            print("Install with: pip install rpy2")
            return []

        # TODO: Implement R integration to:
        # 1. Load metadat package
        # 2. List all available datasets (data(package="metadat"))
        # 3. For each dataset:
        #    - Detect outcome measure type
        #    - Run metafor::rma() to get I², τ², Q
        #    - Extract effect sizes and study characteristics
        # 4. Return standardized MetaAnalysisMetadata objects

        return []


class MetaLearningDatabase:
    """Build meta-learning database from multiple sources"""

    def __init__(self, output_dir: str):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

    def build(self,
              synergy_path: Optional[str] = None,
              include_metadat: bool = False) -> Dict:
        """
        Build meta-learning database.

        Args:
            synergy_path: Path to SYNERGY dataset
            include_metadat: Whether to include metadat package datasets

        Returns:
            Summary statistics dictionary
        """
        all_datasets = []

        # Process SYNERGY
        if synergy_path and Path(synergy_path).exists():
            print("Processing SYNERGY dataset...")
            processor = SynergyProcessor(synergy_path)
            synergy_data = processor.process_all()
            all_datasets.extend(synergy_data)
            print(f"  Extracted {len(synergy_data)} SYNERGY datasets")

        # Process metadat (if available)
        if include_metadat:
            print("\nProcessing metadat package...")
            processor = MetadatProcessor()
            metadat_data = processor.process_all()
            all_datasets.extend(metadat_data)
            print(f"  Extracted {len(metadat_data)} metadat datasets")

        # Save results
        self._save_datasets(all_datasets)

        # Generate summary
        summary = self._generate_summary(all_datasets)
        self._save_summary(summary)

        return summary

    def _save_datasets(self, datasets: List[MetaAnalysisMetadata]):
        """Save datasets as JSON"""
        output_file = self.output_dir / "metalearning_datasets.json"

        data = [asdict(d) for d in datasets]

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2)

        print(f"\nSaved {len(datasets)} datasets to {output_file}")

    def _generate_summary(self, datasets: List[MetaAnalysisMetadata]) -> Dict:
        """Generate summary statistics"""
        if not datasets:
            return {}

        # Count by source
        by_source = {}
        for d in datasets:
            by_source[d.source] = by_source.get(d.source, 0) + 1

        # Count by domain
        by_domain = {}
        for d in datasets:
            by_domain[d.domain] = by_domain.get(d.domain, 0) + 1

        # Count with effect sizes
        with_effect_sizes = sum(1 for d in datasets if d.has_effect_sizes)
        with_heterogeneity = sum(1 for d in datasets if d.I2 is not None)

        # Year range
        years = [d.year for d in datasets if d.year]
        year_range = (min(years), max(years)) if years else (None, None)

        # Study counts
        n_studies = [d.n_included for d in datasets]
        avg_studies = sum(n_studies) / len(n_studies) if n_studies else 0

        summary = {
            'total_datasets': len(datasets),
            'by_source': by_source,
            'by_domain': dict(sorted(by_domain.items(), key=lambda x: -x[1])[:10]),
            'with_effect_sizes': with_effect_sizes,
            'with_heterogeneity_stats': with_heterogeneity,
            'year_range': year_range,
            'avg_included_studies': round(avg_studies, 1),
            'median_included_studies': sorted(n_studies)[len(n_studies)//2] if n_studies else 0
        }

        return summary

    def _save_summary(self, summary: Dict):
        """Save summary as JSON and markdown"""
        # JSON
        json_file = self.output_dir / "metalearning_summary.json"
        with open(json_file, 'w') as f:
            json.dump(summary, f, indent=2)

        # Markdown report
        md_file = self.output_dir / "METALEARNING_REPORT.md"
        with open(md_file, 'w') as f:
            f.write("# Meta-Learning Database Report\n\n")
            f.write(f"**Generated:** {Path(json_file).stat().st_mtime}\n\n")
            f.write("## Summary Statistics\n\n")
            f.write(f"- **Total Datasets:** {summary['total_datasets']}\n")
            f.write(f"- **With Effect Sizes:** {summary['with_effect_sizes']}\n")
            f.write(f"- **With Heterogeneity Stats (I², τ²):** {summary['with_heterogeneity_stats']}\n")
            f.write(f"- **Year Range:** {summary['year_range'][0]}-{summary['year_range'][1]}\n")
            f.write(f"- **Avg Studies per Dataset:** {summary['avg_included_studies']}\n")
            f.write(f"- **Median Studies per Dataset:** {summary['median_included_studies']}\n\n")

            f.write("## Datasets by Source\n\n")
            for source, count in summary['by_source'].items():
                f.write(f"- **{source}:** {count}\n")

            f.write("\n## Top 10 Domains\n\n")
            for domain, count in summary['by_domain'].items():
                f.write(f"- {domain}: {count}\n")

            f.write("\n## Next Steps\n\n")
            f.write("### For SYNERGY datasets (screening data only):\n")
            f.write("- ✅ Extracted: n_studies, domain, year, screening statistics\n")
            f.write("- ❌ Missing: Effect sizes, I², τ², Q (not in SYNERGY)\n")
            f.write("- **Action:** Use as supplementary metadata only\n\n")

            f.write("### For metadat package (actual meta-analysis data):\n")
            f.write("- ❌ Not yet processed (requires R integration)\n")
            f.write("- **Action:** Run R script to extract effect sizes and heterogeneity\n\n")

            f.write("### Training Meta-Learning Models:\n")
            f.write("- **Need:** 500+ datasets with I² and τ² statistics\n")
            f.write("- **Have:** SYNERGY metadata (no effect sizes)\n")
            f.write("- **TODO:** Process metadat package (350+ datasets with effect sizes)\n")
            f.write("- **TODO:** Find additional sources with published meta-analysis results\n\n")

        print(f"Saved summary to {md_file}")


def main():
    """Main execution"""
    import argparse

    parser = argparse.ArgumentParser(description="Process meta-analysis datasets for meta-learning")
    parser.add_argument("--synergy-path", default="data/metalearning/github/synergy-dataset",
                       help="Path to SYNERGY dataset")
    parser.add_argument("--output-dir", default="data/metalearning/processed",
                       help="Output directory")
    parser.add_argument("--include-metadat", action="store_true",
                       help="Include metadat package datasets (requires R)")

    args = parser.parse_args()

    print("=" * 80)
    print("Meta-Learning Dataset Processor")
    print("=" * 80)

    # Build database
    db = MetaLearningDatabase(args.output_dir)
    summary = db.build(
        synergy_path=args.synergy_path,
        include_metadat=args.include_metadat
    )

    # Print summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total datasets: {summary.get('total_datasets', 0)}")
    print(f"With effect sizes: {summary.get('with_effect_sizes', 0)}")
    print(f"With heterogeneity: {summary.get('with_heterogeneity_stats', 0)}")
    print(f"Year range: {summary.get('year_range', (None, None))}")
    print("\nDatasets by source:")
    for source, count in summary.get('by_source', {}).items():
        print(f"  {source}: {count}")

    print("\n" + "=" * 80)
    print("✅ Processing complete!")
    print(f"📁 Output: {args.output_dir}")
    print("=" * 80)


if __name__ == "__main__":
    main()
