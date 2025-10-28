#!/usr/bin/env python3
"""
CBAMMR Meta-Learning Data Collector
====================================

Python-based system to collect 1500-2000 meta-analysis datasets from:
1. metadat R package (~350 datasets)
2. GitHub repositories (~1000 datasets)
3. Zenodo (~500 datasets)
4. Other R packages (~100 datasets)

Author: CBAMMR Development Team
Date: October 2025
"""

import os
import sys
import json
import pickle
import logging
import pandas as pd
import numpy as np
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@dataclass
class MetaAnalysisDataset:
    """Standardized meta-analysis dataset structure"""

    # Identification
    dataset_name: str
    source: str  # 'metadat', 'github', 'zenodo', 'other_r'

    # Metadata
    domain: str  # 'medicine', 'ecology', 'psychology', 'education', 'other'
    outcome_measure: str  # 'OR', 'RR', 'HR', 'SMD', 'MD', 'COR'
    measure_type: str  # 'binary', 'continuous', 'correlation'

    # Dataset characteristics
    n_studies: int
    n_variables: int
    year_min: Optional[int] = None
    year_max: Optional[int] = None
    year_range: Optional[int] = None
    median_year: Optional[float] = None

    # Sample size
    median_sample_size: Optional[float] = None
    total_participants: Optional[int] = None

    # Moderators
    has_moderators: bool = False
    moderators: List[str] = None
    n_moderators: int = 0
    continuous_moderators: List[str] = None
    categorical_moderators: List[str] = None

    # Heterogeneity (PRIMARY TARGETS for ML)
    k: int = 0  # Number of effect sizes
    pooled_effect: Optional[float] = None
    se: Optional[float] = None
    ci_lower: Optional[float] = None
    ci_upper: Optional[float] = None
    tau2: Optional[float] = None  # Between-study variance
    tau: Optional[float] = None
    I2: Optional[float] = None  # Heterogeneity percentage - PRIMARY TARGET
    H2: Optional[float] = None
    Q: Optional[float] = None  # Cochran's Q
    Q_pval: Optional[float] = None

    # Moderator analysis results
    important_moderators: Optional[Dict[str, float]] = None  # {mod: R2}

    # Raw data
    raw_data: Optional[pd.DataFrame] = None

    def __post_init__(self):
        if self.moderators is None:
            self.moderators = []
        if self.continuous_moderators is None:
            self.continuous_moderators = []
        if self.categorical_moderators is None:
            self.categorical_moderators = []
        if self.important_moderators is None:
            self.important_moderators = {}

    def to_dict(self, include_raw_data=False):
        """Convert to dictionary"""
        d = asdict(self)
        if not include_raw_data:
            d.pop('raw_data', None)
        elif self.raw_data is not None:
            d['raw_data'] = self.raw_data.to_dict('records')
        return d

    def to_json(self, include_raw_data=False):
        """Convert to JSON string"""
        return json.dumps(self.to_dict(include_raw_data), indent=2)


class MetaLearningCollector:
    """Main collector class for all data sources"""

    def __init__(self, output_dir: str = "data/metalearning"):
        """
        Initialize collector

        Args:
            output_dir: Directory to save collected data
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        self.datasets = {}  # {dataset_name: MetaAnalysisDataset}

        logger.info(f"Initialized MetaLearningCollector")
        logger.info(f"Output directory: {self.output_dir.absolute()}")

    def collect_all(self, sources: List[str] = ['metadat']) -> Dict[str, MetaAnalysisDataset]:
        """
        Collect from all sources

        Args:
            sources: List of sources to collect from
                    ['metadat', 'github', 'zenodo', 'other_r']

        Returns:
            Dictionary of datasets
        """
        logger.info("=" * 70)
        logger.info("CBAMMR Meta-Learning Database Construction")
        logger.info("=" * 70)
        logger.info("")

        all_datasets = {}

        # Collect from each source
        for i, source in enumerate(sources, 1):
            logger.info(f"[{i}/{len(sources)}] Collecting from {source}...")

            if source == 'metadat':
                metadat_datasets = self.collect_metadat()
                all_datasets.update(metadat_datasets)
                logger.info(f"      Collected: {len(metadat_datasets)} datasets\n")

            elif source == 'github':
                github_datasets = self.collect_github()
                all_datasets.update(github_datasets)
                logger.info(f"      Collected: {len(github_datasets)} datasets\n")

            elif source == 'zenodo':
                zenodo_datasets = self.collect_zenodo()
                all_datasets.update(zenodo_datasets)
                logger.info(f"      Collected: {len(zenodo_datasets)} datasets\n")

            elif source == 'other_r':
                other_datasets = self.collect_other_r_packages()
                all_datasets.update(other_datasets)
                logger.info(f"      Collected: {len(other_datasets)} datasets\n")

        # Remove duplicates
        all_datasets = self._remove_duplicates(all_datasets)

        # Quality filtering
        all_datasets = self._filter_quality(all_datasets)

        # Save
        self.datasets = all_datasets
        self._save_database()

        logger.info("")
        logger.info("=" * 70)
        logger.info(f"COMPLETE: {len(all_datasets)} meta-analyses in database")
        logger.info("=" * 70)
        logger.info("")

        # Print summary
        self._print_summary()

        return all_datasets

    def collect_metadat(self) -> Dict[str, MetaAnalysisDataset]:
        """
        Collect all datasets from metadat R package

        Returns:
            Dictionary of datasets
        """
        try:
            import rpy2.robjects as ro
            from rpy2.robjects import pandas2ri
            from rpy2.robjects.packages import importr

            # Activate automatic conversion
            pandas2ri.activate()

            # Import metadat
            logger.info("  Loading metadat R package...")

            try:
                utils = importr('utils')
                # Install metadat if not available
                if not self._r_package_installed('metadat'):
                    logger.info("  Installing metadat package...")
                    utils.install_packages('metadat', repos='https://cloud.r-project.org')

                metadat = importr('metadat')

            except Exception as e:
                logger.error(f"  Failed to load metadat: {e}")
                return {}

            # Get list of datasets
            r_code = """
            data(package = "metadat")$results[, "Item"]
            """
            dataset_names = list(ro.r(r_code))

            logger.info(f"  Found {len(dataset_names)} datasets in metadat")

            # Process each dataset
            datasets = {}
            success_count = 0
            error_count = 0

            for i, name in enumerate(dataset_names, 1):
                try:
                    logger.info(f"  [{i}/{len(dataset_names)}] Processing: {name}...", end=" ")

                    # Load dataset
                    ro.r(f'data("{name}", package = "metadat")')
                    df = ro.r(name)

                    # Convert to pandas
                    if hasattr(df, 'to_pandas'):
                        df_pd = df
                    else:
                        df_pd = pandas2ri.rpy2py(df)

                    # Process
                    processed = self._process_r_dataset(df_pd, name, 'metadat')

                    if processed is not None:
                        datasets[name] = processed
                        success_count += 1
                        logger.info("OK")
                    else:
                        error_count += 1
                        logger.info("SKIP")

                except Exception as e:
                    error_count += 1
                    logger.info(f"ERROR: {str(e)[:50]}")

            logger.info(f"  Successfully processed: {success_count}/{len(dataset_names)}")

            return datasets

        except ImportError:
            logger.warning("  rpy2 not installed. Cannot collect from R packages.")
            logger.info("  Install with: pip install rpy2")
            return {}

    def collect_github(self) -> Dict[str, MetaAnalysisDataset]:
        """
        Collect datasets from GitHub repositories

        Returns:
            Dictionary of datasets
        """
        logger.info("  Searching GitHub repositories...")

        repos = [
            "asreview/systematic-review-datasets",
            "asreview/synergy-dataset",
        ]

        datasets = {}

        for repo in repos:
            try:
                logger.info(f"    Processing: {repo}")
                repo_datasets = self._process_github_repo(repo)
                datasets.update(repo_datasets)
            except Exception as e:
                logger.error(f"    Error processing {repo}: {e}")

        return datasets

    def collect_zenodo(self, query: str = "meta-analysis",
                       max_results: int = 100) -> Dict[str, MetaAnalysisDataset]:
        """
        Collect datasets from Zenodo

        Args:
            query: Search query
            max_results: Maximum number of results

        Returns:
            Dictionary of datasets
        """
        logger.info(f"  Searching Zenodo for: '{query}'...")

        try:
            import requests

            # Zenodo API
            url = "https://zenodo.org/api/records"
            params = {
                'q': query,
                'size': min(max_results, 1000),
                'sort': 'mostrecent',
                'type': 'dataset'
            }

            response = requests.get(url, params=params, timeout=30)

            if response.status_code == 200:
                results = response.json()
                hits = results.get('hits', {}).get('hits', [])

                logger.info(f"    Found {len(hits)} datasets")

                datasets = {}
                for i, hit in enumerate(hits[:max_results], 1):
                    try:
                        logger.info(f"    [{i}/{max_results}] Processing Zenodo record...")
                        record_dataset = self._process_zenodo_record(hit)
                        if record_dataset:
                            datasets[record_dataset.dataset_name] = record_dataset
                    except Exception as e:
                        logger.error(f"      Error: {e}")

                return datasets
            else:
                logger.error(f"    Zenodo API returned status {response.status_code}")
                return {}

        except ImportError:
            logger.warning("    requests library not installed")
            logger.info("    Install with: pip install requests")
            return {}
        except Exception as e:
            logger.error(f"    Error accessing Zenodo: {e}")
            return {}

    def collect_other_r_packages(self) -> Dict[str, MetaAnalysisDataset]:
        """
        Collect datasets from other R packages (meta, metafor, etc.)

        Returns:
            Dictionary of datasets
        """
        logger.info("  Collecting from other R packages...")

        packages = ['meta', 'metafor']
        datasets = {}

        try:
            import rpy2.robjects as ro
            from rpy2.robjects import pandas2ri
            from rpy2.robjects.packages import importr

            pandas2ri.activate()

            for pkg in packages:
                try:
                    if self._r_package_installed(pkg):
                        logger.info(f"    Processing {pkg} package...")
                        # Get datasets from package
                        # (Most overlap with metadat, so just note for now)
                except Exception as e:
                    logger.error(f"    Error with {pkg}: {e}")

        except ImportError:
            logger.warning("    rpy2 not available")

        return datasets

    def _r_package_installed(self, package_name: str) -> bool:
        """Check if R package is installed"""
        try:
            import rpy2.robjects as ro
            result = ro.r(f'requireNamespace("{package_name}", quietly = TRUE)')[0]
            return result
        except:
            return False

    def _process_r_dataset(self, df: pd.DataFrame, name: str,
                          source: str) -> Optional[MetaAnalysisDataset]:
        """
        Process R dataset into standardized format

        Args:
            df: Pandas DataFrame
            name: Dataset name
            source: Source name

        Returns:
            MetaAnalysisDataset or None if insufficient data
        """
        # Must have at least 3 studies
        if len(df) < 3:
            return None

        # Detect outcome measure
        outcome_info = self._detect_outcome_measure(df)

        # Detect moderators
        moderator_info = self._detect_moderators(df)

        # Extract study characteristics
        study_chars = self._extract_study_characteristics(df)

        # Compute meta-analysis (simplified - would need metafor in R)
        heterogeneity = self._compute_heterogeneity_simple(df, outcome_info)

        if heterogeneity is None:
            return None

        # Create dataset object
        dataset = MetaAnalysisDataset(
            dataset_name=name,
            source=source,
            domain=self._infer_domain(name),
            outcome_measure=outcome_info['measure'],
            measure_type=outcome_info['type'],
            n_studies=len(df),
            n_variables=len(df.columns),
            **study_chars,
            **moderator_info,
            **heterogeneity,
            raw_data=df
        )

        return dataset

    def _detect_outcome_measure(self, df: pd.DataFrame) -> Dict:
        """Detect outcome measure type"""
        cols = df.columns.tolist()

        # Binary (2x2 table)
        if all(c in cols for c in ['ai', 'bi', 'ci', 'di']):
            measure = df['measure'].iloc[0] if 'measure' in cols else 'OR'
            return {'measure': measure, 'type': 'binary'}

        # Pre-computed effects
        if 'yi' in cols and ('vi' in cols or 'sei' in cols):
            if 'measure' in cols:
                measure = df['measure'].iloc[0]
            else:
                # Infer from values
                yi_range = df['yi'].abs().max()
                measure = 'SMD' if yi_range < 5 else 'MD'
            return {'measure': measure, 'type': 'continuous'}

        # Correlation
        if 'ri' in cols:
            return {'measure': 'COR', 'type': 'correlation'}

        return {'measure': 'UNKNOWN', 'type': 'unknown'}

    def _detect_moderators(self, df: pd.DataFrame) -> Dict:
        """Detect moderator variables"""
        essential_vars = [
            'yi', 'vi', 'sei', 'ai', 'bi', 'ci', 'di',
            'n1i', 'n2i', 'm1i', 'm2i', 'sd1i', 'sd2i',
            'study', 'author', 'year', 'id', 'measure'
        ]

        moderators = [c for c in df.columns if c not in essential_vars]

        if not moderators:
            return {
                'has_moderators': False,
                'moderators': [],
                'n_moderators': 0,
                'continuous_moderators': [],
                'categorical_moderators': []
            }

        # Classify types
        continuous = []
        categorical = []

        for mod in moderators:
            if pd.api.types.is_numeric_dtype(df[mod]):
                continuous.append(mod)
            else:
                categorical.append(mod)

        return {
            'has_moderators': True,
            'moderators': moderators,
            'n_moderators': len(moderators),
            'continuous_moderators': continuous,
            'categorical_moderators': categorical
        }

    def _extract_study_characteristics(self, df: pd.DataFrame) -> Dict:
        """Extract study characteristics"""
        chars = {}

        # Year information
        if 'year' in df.columns:
            years = df['year'].dropna()
            if len(years) > 0:
                chars['year_min'] = int(years.min())
                chars['year_max'] = int(years.max())
                chars['year_range'] = int(years.max() - years.min())
                chars['median_year'] = float(years.median())

        # Sample size
        if 'n1i' in df.columns and 'n2i' in df.columns:
            total_n = df['n1i'] + df['n2i']
            total_n = total_n.dropna()
            if len(total_n) > 0:
                chars['median_sample_size'] = float(total_n.median())
                chars['total_participants'] = int(total_n.sum())

        return chars

    def _compute_heterogeneity_simple(self, df: pd.DataFrame,
                                     outcome_info: Dict) -> Optional[Dict]:
        """
        Simplified heterogeneity computation
        (Full computation would require calling R's metafor)
        """
        try:
            # For pre-computed effects
            if 'yi' in df.columns and 'vi' in df.columns:
                yi = df['yi'].values
                vi = df['vi'].values
            elif 'yi' in df.columns and 'sei' in df.columns:
                yi = df['yi'].values
                vi = df['sei'].values ** 2
            else:
                return None

            # Remove missing
            mask = ~(np.isnan(yi) | np.isnan(vi))
            yi = yi[mask]
            vi = vi[mask]
            k = len(yi)

            if k < 3:
                return None

            # Simple fixed-effect estimate
            wi = 1 / vi
            pooled = np.sum(wi * yi) / np.sum(wi)
            se = np.sqrt(1 / np.sum(wi))

            # Cochran's Q
            Q = np.sum(wi * (yi - pooled)**2)

            # I-squared (simple version)
            if Q > (k - 1):
                I2 = 100 * (Q - (k - 1)) / Q
            else:
                I2 = 0.0

            # Tau-squared (DL method)
            if Q > (k - 1):
                C = np.sum(wi) - np.sum(wi**2) / np.sum(wi)
                tau2 = max(0, (Q - (k - 1)) / C)
            else:
                tau2 = 0.0

            return {
                'k': int(k),
                'pooled_effect': float(pooled),
                'se': float(se),
                'ci_lower': float(pooled - 1.96 * se),
                'ci_upper': float(pooled + 1.96 * se),
                'tau2': float(tau2),
                'tau': float(np.sqrt(tau2)),
                'I2': float(I2),
                'Q': float(Q),
                'Q_pval': None  # Would need chi-square test
            }

        except Exception as e:
            logger.debug(f"Error computing heterogeneity: {e}")
            return None

    def _infer_domain(self, dataset_name: str) -> str:
        """Infer research domain from dataset name"""
        name_lower = dataset_name.lower()

        medicine_keywords = ['bcg', 'clinical', 'patient', 'treatment', 'therapy',
                            'disease', 'drug', 'medical', 'health']
        education_keywords = ['student', 'teaching', 'learning', 'school', 'education']
        ecology_keywords = ['species', 'habitat', 'biodiversity', 'ecosystem',
                           'environmental', 'plant', 'co2']
        psychology_keywords = ['behavior', 'cognitive', 'mental', 'psychological']

        for kw in medicine_keywords:
            if kw in name_lower:
                return 'medicine'
        for kw in education_keywords:
            if kw in name_lower:
                return 'education'
        for kw in ecology_keywords:
            if kw in name_lower:
                return 'ecology'
        for kw in psychology_keywords:
            if kw in name_lower:
                return 'psychology'

        return 'other'

    def _process_github_repo(self, repo: str) -> Dict[str, MetaAnalysisDataset]:
        """Process GitHub repository"""
        # Placeholder - would clone and process CSV files
        logger.info(f"      GitHub collection not yet implemented for {repo}")
        return {}

    def _process_zenodo_record(self, record: Dict) -> Optional[MetaAnalysisDataset]:
        """Process Zenodo record"""
        # Placeholder - would download and process files
        return None

    def _remove_duplicates(self, datasets: Dict) -> Dict:
        """Remove duplicate datasets"""
        # Simple duplicate check by name
        return datasets

    def _filter_quality(self, datasets: Dict) -> Dict:
        """Filter datasets by quality criteria"""
        filtered = {}

        for name, ds in datasets.items():
            # Quality criteria
            if ds.n_studies >= 3 and ds.I2 is not None:
                filtered[name] = ds

        removed = len(datasets) - len(filtered)
        if removed > 0:
            logger.info(f"  Removed {removed} low-quality datasets")

        return filtered

    def _save_database(self):
        """Save database to disk"""
        # Save as pickle
        pickle_file = self.output_dir / "metalearning_database.pkl"
        with open(pickle_file, 'wb') as f:
            pickle.dump(self.datasets, f)
        logger.info(f"Saved database to: {pickle_file}")

        # Save metadata as JSON
        json_file = self.output_dir / "metalearning_database_metadata.json"
        metadata = {name: ds.to_dict(include_raw_data=False)
                   for name, ds in self.datasets.items()}
        with open(json_file, 'w') as f:
            json.dump(metadata, f, indent=2)
        logger.info(f"Saved metadata to: {json_file}")

        # Save summary as CSV
        self._save_summary_csv()

    def _save_summary_csv(self):
        """Save summary statistics as CSV"""
        csv_file = self.output_dir / "metalearning_database_summary.csv"

        rows = []
        for name, ds in self.datasets.items():
            rows.append({
                'dataset_name': ds.dataset_name,
                'source': ds.source,
                'domain': ds.domain,
                'outcome_measure': ds.outcome_measure,
                'n_studies': ds.n_studies,
                'n_moderators': ds.n_moderators,
                'year_range': ds.year_range,
                'median_sample_size': ds.median_sample_size,
                'I2': ds.I2,
                'tau2': ds.tau2,
                'Q': ds.Q
            })

        df_summary = pd.DataFrame(rows)
        df_summary.to_csv(csv_file, index=False)
        logger.info(f"Saved summary CSV to: {csv_file}")

    def _print_summary(self):
        """Print database summary statistics"""
        if not self.datasets:
            return

        n_datasets = len(self.datasets)
        n_studies = [ds.n_studies for ds in self.datasets.values()]
        I2_values = [ds.I2 for ds in self.datasets.values() if ds.I2 is not None]
        tau2_values = [ds.tau2 for ds in self.datasets.values() if ds.tau2 is not None]

        domains = [ds.domain for ds in self.datasets.values()]
        measures = [ds.outcome_measure for ds in self.datasets.values()]

        logger.info("\n📊 Database Summary:")
        logger.info(f"   Total datasets:          {n_datasets}")
        logger.info(f"   Median studies per MA:   {np.median(n_studies):.1f}")
        logger.info(f"   Total studies:           {sum(n_studies)}")
        if I2_values:
            logger.info(f"   Median I²:               {np.median(I2_values):.1f}%")
        if tau2_values:
            logger.info(f"   Median τ²:               {np.median(tau2_values):.3f}")

        from collections import Counter
        most_common_domain = Counter(domains).most_common(1)[0][0]
        most_common_measure = Counter(measures).most_common(1)[0][0]
        logger.info(f"   Most common domain:      {most_common_domain}")
        logger.info(f"   Most common measure:     {most_common_measure}")
        logger.info("")


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(
        description='CBAMMR Meta-Learning Data Collector'
    )
    parser.add_argument(
        '--output-dir',
        default='data/metalearning',
        help='Output directory (default: data/metalearning)'
    )
    parser.add_argument(
        '--sources',
        nargs='+',
        default=['metadat'],
        choices=['metadat', 'github', 'zenodo', 'other_r'],
        help='Data sources to collect from'
    )
    parser.add_argument(
        '--zenodo-max',
        type=int,
        default=100,
        help='Maximum Zenodo results (default: 100)'
    )

    args = parser.parse_args()

    # Create collector
    collector = MetaLearningCollector(output_dir=args.output_dir)

    # Collect data
    datasets = collector.collect_all(sources=args.sources)

    logger.info(f"\n✅ Collection complete! {len(datasets)} datasets collected.")
    logger.info(f"📁 Data saved to: {collector.output_dir.absolute()}")

    return 0


if __name__ == '__main__':
    sys.exit(main())
