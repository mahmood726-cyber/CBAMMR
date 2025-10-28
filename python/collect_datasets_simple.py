#!/usr/bin/env python3
"""
Simplified Meta-Learning Data Collector
Uses only Python standard library + basic requests
"""

import json
import os
import sys
from pathlib import Path
from urllib.request import urlopen, Request
from urllib.parse import urlencode
import ssl

# For downloading files
try:
    # Create unverified SSL context for downloads
    ssl._create_default_https_context = ssl._create_unverified_context
except:
    pass


def collect_zenodo_metaanalyses(output_dir="data/metalearning/zenodo", max_results=50):
    """Collect meta-analysis datasets from Zenodo"""

    os.makedirs(output_dir, exist_ok=True)

    print("=" * 70)
    print("Collecting Meta-Analysis Datasets from Zenodo")
    print("=" * 70)
    print()

    # Zenodo API endpoint
    base_url = "https://zenodo.org/api/records"

    queries = [
        "meta-analysis",
        "systematic review meta-analysis",
        "meta analysis data"
    ]

    all_records = []

    for query in queries:
        print(f"Searching: '{query}'...")

        params = {
            'q': query,
            'size': min(max_results, 100),
            'sort': 'mostrecent',
            'type': 'dataset'
        }

        url = f"{base_url}?{urlencode(params)}"

        try:
            request = Request(url, headers={'User-Agent': 'CBAMMR-Collector/1.0'})
            with urlopen(request, timeout=30) as response:
                data = json.loads(response.read().decode())

                hits = data.get('hits', {}).get('hits', [])
                print(f"  Found: {len(hits)} datasets")

                for hit in hits:
                    record_id = hit.get('id')
                    title = hit.get('metadata', {}).get('title', 'Unknown')
                    doi = hit.get('doi', '')
                    created = hit.get('created', '')

                    record_info = {
                        'id': record_id,
                        'title': title,
                        'doi': doi,
                        'created': created,
                        'url': hit.get('links', {}).get('self', ''),
                        'files': hit.get('files', []),
                        'source': 'zenodo',
                        'query': query
                    }

                    all_records.append(record_info)

        except Exception as e:
            print(f"  Error: {e}")
            continue

    # Remove duplicates by DOI
    seen_dois = set()
    unique_records = []
    for record in all_records:
        doi = record['doi']
        if doi and doi not in seen_dois:
            seen_dois.add(doi)
            unique_records.append(record)

    print()
    print(f"Total unique datasets found: {len(unique_records)}")

    # Save metadata
    metadata_file = os.path.join(output_dir, 'zenodo_datasets.json')
    with open(metadata_file, 'w') as f:
        json.dump(unique_records, f, indent=2)

    print(f"Saved metadata to: {metadata_file}")

    # Save summary
    summary_file = os.path.join(output_dir, 'zenodo_summary.txt')
    with open(summary_file, 'w') as f:
        f.write(f"Zenodo Meta-Analysis Datasets Collection\n")
        f.write(f"=" * 70 + "\n\n")
        f.write(f"Total datasets: {len(unique_records)}\n\n")
        f.write(f"Recent datasets:\n")
        f.write(f"-" * 70 + "\n")

        for i, record in enumerate(unique_records[:20], 1):
            f.write(f"\n{i}. {record['title']}\n")
            f.write(f"   DOI: {record['doi']}\n")
            f.write(f"   Date: {record['created'][:10]}\n")
            f.write(f"   Files: {len(record.get('files', []))}\n")

    print(f"Saved summary to: {summary_file}")
    print()

    return unique_records


def collect_github_datasets(output_dir="data/metalearning/github"):
    """Collect meta-analysis datasets from GitHub"""

    os.makedirs(output_dir, exist_ok=True)

    print("=" * 70)
    print("Collecting Meta-Analysis Datasets from GitHub")
    print("=" * 70)
    print()

    # GitHub API search for meta-analysis datasets
    base_url = "https://api.github.com/search/repositories"

    queries = [
        "meta-analysis data",
        "systematic review dataset",
        "meta analysis csv"
    ]

    all_repos = []

    for query in queries:
        print(f"Searching GitHub: '{query}'...")

        params = {
            'q': query,
            'sort': 'stars',
            'order': 'desc',
            'per_page': 30
        }

        url = f"{base_url}?{urlencode(params)}"

        try:
            request = Request(url, headers={
                'User-Agent': 'CBAMMR-Collector/1.0',
                'Accept': 'application/vnd.github.v3+json'
            })

            with urlopen(request, timeout=30) as response:
                data = json.loads(response.read().decode())

                items = data.get('items', [])
                print(f"  Found: {len(items)} repositories")

                for item in items:
                    repo_info = {
                        'name': item.get('full_name'),
                        'description': item.get('description', ''),
                        'url': item.get('html_url'),
                        'stars': item.get('stargazers_count', 0),
                        'updated': item.get('updated_at', ''),
                        'language': item.get('language', ''),
                        'topics': item.get('topics', []),
                        'source': 'github',
                        'query': query
                    }

                    all_repos.append(repo_info)

        except Exception as e:
            print(f"  Error: {e}")
            continue

    # Remove duplicates
    seen_names = set()
    unique_repos = []
    for repo in all_repos:
        name = repo['name']
        if name not in seen_names:
            seen_names.add(name)
            unique_repos.append(repo)

    print()
    print(f"Total unique repositories found: {len(unique_repos)}")

    # Save metadata
    metadata_file = os.path.join(output_dir, 'github_repositories.json')
    with open(metadata_file, 'w') as f:
        json.dump(unique_repos, f, indent=2)

    print(f"Saved metadata to: {metadata_file}")

    # Save summary
    summary_file = os.path.join(output_dir, 'github_summary.txt')
    with open(summary_file, 'w') as f:
        f.write(f"GitHub Meta-Analysis Repositories Collection\n")
        f.write(f"=" * 70 + "\n\n")
        f.write(f"Total repositories: {len(unique_repos)}\n\n")
        f.write(f"Top repositories by stars:\n")
        f.write(f"-" * 70 + "\n")

        # Sort by stars
        sorted_repos = sorted(unique_repos, key=lambda x: x['stars'], reverse=True)

        for i, repo in enumerate(sorted_repos[:20], 1):
            f.write(f"\n{i}. {repo['name']} ({repo['stars']} ⭐)\n")
            f.write(f"   {repo['description'][:100]}\n")
            f.write(f"   {repo['url']}\n")

    print(f"Saved summary to: {summary_file}")
    print()

    return unique_repos


def create_collection_report(zenodo_records, github_repos, output_dir="data/metalearning"):
    """Create comprehensive collection report"""

    os.makedirs(output_dir, exist_ok=True)

    report_file = os.path.join(output_dir, 'COLLECTION_REPORT.md')

    with open(report_file, 'w') as f:
        f.write("# CBAMMR Meta-Learning Data Collection Report\n\n")
        f.write(f"**Date:** {os.popen('date').read().strip()}\n\n")
        f.write("---\n\n")

        # Summary statistics
        f.write("## Summary Statistics\n\n")
        f.write(f"- **Zenodo Datasets:** {len(zenodo_records)}\n")
        f.write(f"- **GitHub Repositories:** {len(github_repos)}\n")
        f.write(f"- **Total Resources:** {len(zenodo_records) + len(github_repos)}\n\n")

        # Zenodo details
        f.write("## Zenodo Datasets\n\n")
        f.write("Recent meta-analysis datasets from Zenodo:\n\n")

        for i, record in enumerate(zenodo_records[:30], 1):
            f.write(f"{i}. **{record['title']}**\n")
            f.write(f"   - DOI: {record['doi']}\n")
            f.write(f"   - Created: {record['created'][:10]}\n")
            f.write(f"   - Files: {len(record.get('files', []))}\n")
            f.write(f"   - URL: https://zenodo.org/record/{record['id']}\n\n")

        # GitHub details
        f.write("\n## GitHub Repositories\n\n")
        f.write("Repositories containing meta-analysis data:\n\n")

        sorted_repos = sorted(github_repos, key=lambda x: x['stars'], reverse=True)

        for i, repo in enumerate(sorted_repos[:30], 1):
            f.write(f"{i}. **{repo['name']}** ({repo['stars']} ⭐)\n")
            desc = repo['description'][:150] if repo['description'] else 'No description'
            f.write(f"   - Description: {desc}\n")
            f.write(f"   - Language: {repo['language']}\n")
            f.write(f"   - URL: {repo['url']}\n\n")

        # Next steps
        f.write("\n## Next Steps\n\n")
        f.write("1. Download and process Zenodo datasets\n")
        f.write("2. Clone and extract data from GitHub repositories\n")
        f.write("3. Standardize all datasets into common format\n")
        f.write("4. Compute meta-analysis statistics for each dataset\n")
        f.write("5. Build machine learning training dataset\n\n")

        # Key repositories
        f.write("## Key Repositories to Process\n\n")

        meta_repos = [r for r in github_repos if 'meta' in r['name'].lower() or 'systematic' in r['name'].lower()]

        for repo in meta_repos[:10]:
            f.write(f"- [{repo['name']}]({repo['url']})\n")

    print(f"Created collection report: {report_file}")

    return report_file


def main():
    """Main collection pipeline"""

    print("\n")
    print("=" * 70)
    print("CBAMMR Meta-Learning Data Collection")
    print("=" * 70)
    print("\n")

    # Create output directory
    output_dir = "data/metalearning"
    os.makedirs(output_dir, exist_ok=True)

    # Collect from Zenodo
    print("STEP 1: Collecting from Zenodo...")
    print()
    zenodo_records = collect_zenodo_metaanalyses(
        output_dir=os.path.join(output_dir, "zenodo"),
        max_results=50
    )

    # Collect from GitHub
    print("\nSTEP 2: Collecting from GitHub...")
    print()
    github_repos = collect_github_datasets(
        output_dir=os.path.join(output_dir, "github")
    )

    # Create comprehensive report
    print("\nSTEP 3: Creating collection report...")
    print()
    report_file = create_collection_report(zenodo_records, github_repos, output_dir)

    # Final summary
    print("\n")
    print("=" * 70)
    print("✅ COLLECTION COMPLETE")
    print("=" * 70)
    print()
    print(f"📊 Zenodo datasets found: {len(zenodo_records)}")
    print(f"📦 GitHub repositories found: {len(github_repos)}")
    print(f"📁 Data saved to: {os.path.abspath(output_dir)}")
    print(f"📄 Report: {report_file}")
    print()
    print("Next: Process these resources to extract meta-analysis datasets")
    print()

    return 0


if __name__ == '__main__':
    sys.exit(main())
