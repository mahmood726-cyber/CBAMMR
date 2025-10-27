#!/usr/bin/env python3
"""
Static Analysis for CBAMMR R Package
Checks for common issues without running R
"""

import os
import re
from pathlib import Path
from collections import defaultdict

class RPackageChecker:
    def __init__(self, package_dir):
        self.package_dir = Path(package_dir)
        self.issues = []
        self.warnings = []
        self.info = []

    def check_all(self):
        """Run all checks"""
        print("=" * 70)
        print("CBAMMR Package Static Analysis")
        print("=" * 70)
        print()

        self.check_description()
        self.check_namespace()
        self.check_r_files()
        self.check_documentation()
        self.check_dependencies()

        self.print_summary()

    def check_description(self):
        """Check DESCRIPTION file"""
        print("\n[1] Checking DESCRIPTION file...")
        desc_file = self.package_dir / "DESCRIPTION"

        if not desc_file.exists():
            self.issues.append("DESCRIPTION file missing")
            return

        with open(desc_file, 'r') as f:
            content = f.read()

        # Check required fields
        required = ['Package', 'Title', 'Version', 'Authors@R', 'Description', 'License']
        for field in required:
            if f"{field}:" not in content:
                self.issues.append(f"DESCRIPTION missing required field: {field}")
            else:
                print(f"  ✓ {field} present")

        # Check version format
        version_match = re.search(r'Version:\s*(\S+)', content)
        if version_match:
            version = version_match.group(1)
            if re.match(r'^\d+\.\d+\.\d+$', version):
                print(f"  ✓ Version format valid: {version}")
            else:
                self.warnings.append(f"Version format unusual: {version}")

        # Check dependencies
        if 'Imports:' in content:
            imports = re.search(r'Imports:\s*\n((?:\s+.+\n)*)', content)
            if imports:
                pkg_count = len([line for line in imports.group(1).split('\n') if line.strip()])
                print(f"  ✓ {pkg_count} import dependencies declared")

    def check_namespace(self):
        """Check NAMESPACE file"""
        print("\n[2] Checking NAMESPACE file...")
        ns_file = self.package_dir / "NAMESPACE"

        if not ns_file.exists():
            self.issues.append("NAMESPACE file missing")
            return

        with open(ns_file, 'r') as f:
            content = f.read()

        exports = re.findall(r'^export\((.+)\)', content, re.MULTILINE)
        importfroms = re.findall(r'^importFrom\(', content, re.MULTILINE)

        print(f"  ✓ {len(exports)} exported functions")
        print(f"  ✓ {len(importfroms)} selective imports")

        if len(exports) == 0:
            self.warnings.append("No exported functions in NAMESPACE")

    def check_r_files(self):
        """Check R source files"""
        print("\n[3] Checking R/ source files...")
        r_dir = self.package_dir / "R"

        if not r_dir.exists():
            self.issues.append("R/ directory missing")
            return

        r_files = list(r_dir.glob("*.R"))
        print(f"  ✓ Found {len(r_files)} R files")

        total_lines = 0
        total_functions = 0
        exported_funcs = set()
        internal_funcs = set()

        for r_file in r_files:
            with open(r_file, 'r') as f:
                content = f.read()

            lines = content.split('\n')
            total_lines += len(lines)

            # Find function definitions
            func_defs = re.findall(r'^(\w+)\s*<-\s*function\s*\(', content, re.MULTILINE)
            total_functions += len(func_defs)

            # Find exported functions
            exports = re.findall(r"#'\s*@export\s*\n(?:#'[^\n]*\n)*(\w+)\s*<-", content)
            exported_funcs.update(exports)

            # Find internal functions (start with .)
            internals = re.findall(r'^(\.[\w_]+)\s*<-\s*function', content, re.MULTILINE)
            internal_funcs.update(internals)

            # Check for syntax issues
            if 'library(' in content and r_file.name != 'cbammr-package.R':
                self.warnings.append(f"{r_file.name}: Contains library() call (use @import or @importFrom instead)")

            # Check for require() calls
            if 'require(' in content and '@examples' not in content:
                self.warnings.append(f"{r_file.name}: Contains require() call (use requireNamespace())")

        print(f"  ✓ Total lines: {total_lines:,}")
        print(f"  ✓ Total functions: {total_functions}")
        print(f"  ✓ Exported functions: {len(exported_funcs)}")
        print(f"  ✓ Internal functions (.xxx): {len(internal_funcs)}")

        if total_functions < 10:
            self.warnings.append(f"Only {total_functions} functions found - package may be incomplete")

    def check_documentation(self):
        """Check documentation"""
        print("\n[4] Checking documentation...")

        # Check for README
        readme_files = list(self.package_dir.glob("README.*"))
        if readme_files:
            print(f"  ✓ README found: {readme_files[0].name}")
        else:
            self.warnings.append("No README file found")

        # Check for NEWS
        if (self.package_dir / "NEWS.md").exists():
            print("  ✓ NEWS.md present")
        else:
            self.info.append("No NEWS.md file (optional)")

        # Check for vignettes
        vig_dir = self.package_dir / "vignettes"
        if vig_dir.exists():
            vignettes = list(vig_dir.glob("*.Rmd"))
            if vignettes:
                print(f"  ✓ {len(vignettes)} vignette(s) found")
            else:
                self.info.append("vignettes/ directory empty")
        else:
            self.info.append("No vignettes/ directory (optional)")

    def check_dependencies(self):
        """Analyze dependencies"""
        print("\n[5] Analyzing dependencies...")

        desc_file = self.package_dir / "DESCRIPTION"
        with open(desc_file, 'r') as f:
            content = f.read()

        # Extract all package dependencies
        deps = defaultdict(list)

        for section in ['Depends', 'Imports', 'Suggests']:
            pattern = f"{section}:\s*\n((?:\s+.+(?:\n|$))*)"
            match = re.search(pattern, content)
            if match:
                pkg_lines = match.group(1).strip().split('\n')
                for line in pkg_lines:
                    pkg_match = re.match(r'\s*(\w+)', line.strip())
                    if pkg_match:
                        deps[section].append(pkg_match.group(1))

        for section, pkgs in deps.items():
            if pkgs:
                print(f"  ✓ {section}: {len(pkgs)} packages")

        # Check for heavy dependencies
        heavy_deps = ['brms', 'rjags', 'RoBMA']
        present_heavy = [d for d in heavy_deps if any(d in pkgs for pkgs in deps.values())]
        if present_heavy:
            print(f"  ⚠ Heavy dependencies: {', '.join(present_heavy)}")
            self.info.append("Package has heavy optional dependencies - this is OK if in Suggests")

    def print_summary(self):
        """Print summary of findings"""
        print("\n" + "=" * 70)
        print("SUMMARY")
        print("=" * 70)

        if not self.issues and not self.warnings:
            print("\n✅ No issues found! Package structure looks good.")
        else:
            if self.issues:
                print(f"\n❌ ISSUES ({len(self.issues)}):")
                for issue in self.issues:
                    print(f"  • {issue}")

            if self.warnings:
                print(f"\n⚠️  WARNINGS ({len(self.warnings)}):")
                for warning in self.warnings:
                    print(f"  • {warning}")

        if self.info:
            print(f"\nℹ️  INFO ({len(self.info)}):")
            for info in self.info:
                print(f"  • {info}")

        print("\n" + "=" * 70)

        # Overall status
        if self.issues:
            print("❌ Status: ISSUES FOUND - needs fixing")
            return False
        elif self.warnings:
            print("⚠️  Status: WARNINGS - review recommended")
            return True
        else:
            print("✅ Status: EXCELLENT - ready for testing")
            return True

if __name__ == "__main__":
    checker = RPackageChecker("/home/user/CBAMMR")
    success = checker.check_all()

    exit(0 if success else 1)
