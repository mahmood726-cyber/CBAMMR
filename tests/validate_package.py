#!/usr/bin/env python3
"""
Comprehensive CBAMMR Package Validator
Validates structure, syntax, documentation, and best practices
"""

import os
import re
import sys
from pathlib import Path
from collections import defaultdict

class Colors:
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    BOLD = '\033[1m'
    END = '\033[0m'

class PackageValidator:
    def __init__(self, package_dir):
        self.package_dir = Path(package_dir)
        self.errors = []
        self.warnings = []
        self.info = []
        self.stats = defaultdict(int)

    def log_error(self, msg):
        self.errors.append(msg)
        print(f"{Colors.RED}✗ ERROR:{Colors.END} {msg}")

    def log_warning(self, msg):
        self.warnings.append(msg)
        print(f"{Colors.YELLOW}⚠ WARNING:{Colors.END} {msg}")

    def log_info(self, msg):
        self.info.append(msg)
        print(f"{Colors.BLUE}ℹ INFO:{Colors.END} {msg}")

    def log_success(self, msg):
        print(f"{Colors.GREEN}✓{Colors.END} {msg}")

    def validate_file_structure(self):
        """Validate basic package structure"""
        print(f"\n{Colors.BOLD}=== Validating Package Structure ==={Colors.END}")

        required_files = ['DESCRIPTION', 'NAMESPACE', 'R']
        recommended_files = ['README.md', 'tests', 'man']

        for f in required_files:
            path = self.package_dir / f
            if path.exists():
                self.log_success(f"Required: {f} exists")
            else:
                self.log_error(f"Missing required file/directory: {f}")

        for f in recommended_files:
            path = self.package_dir / f
            if path.exists():
                self.log_success(f"Recommended: {f} exists")
            else:
                self.log_warning(f"Recommended file/directory missing: {f}")

    def validate_description(self):
        """Validate DESCRIPTION file"""
        print(f"\n{Colors.BOLD}=== Validating DESCRIPTION ==={Colors.END}")

        desc_file = self.package_dir / 'DESCRIPTION'
        if not desc_file.exists():
            self.log_error("DESCRIPTION file not found")
            return

        content = desc_file.read_text()
        required_fields = ['Package', 'Type', 'Title', 'Version', 'Description',
                          'License', 'Encoding']

        for field in required_fields:
            if re.search(f'^{field}:', content, re.MULTILINE):
                self.log_success(f"DESCRIPTION has {field} field")
            else:
                self.log_error(f"DESCRIPTION missing required field: {field}")

        # Check dependencies
        if 'Imports:' in content or 'Depends:' in content:
            self.log_success("Dependencies declared")
        else:
            self.log_warning("No dependencies declared (unusual for this package)")

    def validate_namespace(self):
        """Validate NAMESPACE file"""
        print(f"\n{Colors.BOLD}=== Validating NAMESPACE ==={Colors.END}")

        namespace_file = self.package_dir / 'NAMESPACE'
        if not namespace_file.exists():
            self.log_error("NAMESPACE file not found")
            return

        content = namespace_file.read_text()

        # Count exports
        exports = re.findall(r'^export\(([^)]+)\)', content, re.MULTILINE)
        self.stats['exports'] = len(exports)
        self.log_success(f"Found {len(exports)} exported functions")

        # Check for imports
        imports = re.findall(r'^import\(([^)]+)\)', content, re.MULTILINE)
        importFroms = re.findall(r'^importFrom\(([^,]+),', content, re.MULTILINE)
        self.stats['imports'] = len(imports) + len(importFroms)
        self.log_success(f"Found {len(imports)} imports and {len(importFroms)} importFrom statements")

        if len(exports) == 0:
            self.log_error("No exported functions found")

    def validate_r_files(self):
        """Validate R source files"""
        print(f"\n{Colors.BOLD}=== Validating R Files ==={Colors.END}")

        r_dir = self.package_dir / 'R'
        if not r_dir.exists():
            self.log_error("R directory not found")
            return

        r_files = list(r_dir.glob('*.R'))
        self.stats['r_files'] = len(r_files)
        self.log_info(f"Found {len(r_files)} R files")

        total_functions = 0
        total_lines = 0
        documented_functions = 0

        for r_file in r_files:
            content = r_file.read_text()
            lines = len(content.splitlines())
            total_lines += lines

            # Count functions
            functions = re.findall(r'(\w+)\s*<-\s*function\s*\(', content)
            total_functions += len(functions)

            # Check for roxygen documentation
            roxygen_blocks = len(re.findall(r"#'\s*@export", content))
            documented_functions += roxygen_blocks

            # Check for syntax issues
            self._check_r_syntax(r_file, content)

        self.stats['total_functions'] = total_functions
        self.stats['total_lines'] = total_lines
        self.stats['documented_functions'] = documented_functions

        self.log_success(f"Total functions: {total_functions}")
        self.log_success(f"Documented functions: {documented_functions}")
        self.log_success(f"Total lines of code: {total_lines}")

        if documented_functions < total_functions * 0.5:
            self.log_warning(f"Less than 50% of functions are documented")

    def _check_r_syntax(self, file_path, content):
        """Check R file for common syntax issues"""
        filename = file_path.name
        lines = content.splitlines()

        for i, line in enumerate(lines, 1):
            # Check for very long lines
            if len(line) > 120:
                self.log_warning(f"{filename}:{i} Line exceeds 120 characters ({len(line)} chars)")

            # Check for tabs (spaces preferred in R)
            if '\t' in line and not line.strip().startswith('#'):
                self.log_warning(f"{filename}:{i} Contains tabs (spaces preferred)")

            # Check for trailing whitespace
            if line.endswith(' ') or line.endswith('\t'):
                self.log_info(f"{filename}:{i} Has trailing whitespace")

    def validate_new_functions(self):
        """Specifically validate new reporting and clinical-decision functions"""
        print(f"\n{Colors.BOLD}=== Validating New 2025 Functions ==={Colors.END}")

        # Check reporting.R
        reporting_file = self.package_dir / 'R' / 'reporting.R'
        if reporting_file.exists():
            content = reporting_file.read_text()

            expected_functions = [
                'cbamm_prisma_checklist',
                'cbamm_grade_profile',
                'cbamm_reproducibility_report',
                'cbamm_export_bundle',
                'cbamm_power_analysis'
            ]

            for func in expected_functions:
                if func in content:
                    self.log_success(f"reporting.R: {func}() defined")
                    # Check for roxygen documentation
                    pattern = rf"#'\s+{func}\("
                    if not re.search(pattern, content):
                        # Try alternate pattern
                        pattern = rf"#'.*\n.*{func}\s*<-\s*function"
                        if re.search(pattern, content, re.MULTILINE):
                            self.log_success(f"  └─ {func}() has roxygen documentation")
                        else:
                            self.log_warning(f"  └─ {func}() missing roxygen documentation")
                else:
                    self.log_error(f"reporting.R: {func}() not found")
        else:
            self.log_error("reporting.R file not found")

        # Check clinical-decision.R
        clinical_file = self.package_dir / 'R' / 'clinical-decision.R'
        if clinical_file.exists():
            content = clinical_file.read_text()

            expected_functions = [
                'cbamm_fragility_index',
                'cbamm_nnt_by_baseline_risk',
                'cbamm_clinical_significance',
                'cbamm_prediction_interval_threshold',
                'cbamm_net_clinical_benefit'
            ]

            for func in expected_functions:
                if func in content:
                    self.log_success(f"clinical-decision.R: {func}() defined")
                else:
                    self.log_error(f"clinical-decision.R: {func}() not found")
        else:
            self.log_error("clinical-decision.R file not found")

    def validate_namespace_exports(self):
        """Ensure all new functions are exported"""
        print(f"\n{Colors.BOLD}=== Validating Exports ==={Colors.END}")

        namespace_file = self.package_dir / 'NAMESPACE'
        if not namespace_file.exists():
            return

        namespace_content = namespace_file.read_text()

        new_functions = [
            'cbamm_prisma_checklist',
            'cbamm_grade_profile',
            'cbamm_reproducibility_report',
            'cbamm_export_bundle',
            'cbamm_power_analysis',
            'cbamm_fragility_index',
            'cbamm_nnt_by_baseline_risk',
            'cbamm_clinical_significance',
            'cbamm_prediction_interval_threshold',
            'cbamm_net_clinical_benefit'
        ]

        for func in new_functions:
            if f'export({func})' in namespace_content:
                self.log_success(f"{func}() is exported")
            else:
                self.log_error(f"{func}() not exported in NAMESPACE")

    def validate_documentation_consistency(self):
        """Check for documentation consistency"""
        print(f"\n{Colors.BOLD}=== Validating Documentation ==={Colors.END}")

        # Check if JOURNAL_ENHANCEMENTS.md exists and is comprehensive
        journal_doc = self.package_dir / 'JOURNAL_ENHANCEMENTS.md'
        if journal_doc.exists():
            content = journal_doc.read_text()
            self.log_success("JOURNAL_ENHANCEMENTS.md exists")

            # Check if it documents all new functions
            new_functions = ['cbamm_prisma_checklist', 'cbamm_grade_profile',
                           'cbamm_fragility_index', 'cbamm_nnt_by_baseline_risk']
            documented = sum(1 for f in new_functions if f in content)
            self.log_info(f"{documented}/{len(new_functions)} new functions documented")
        else:
            self.log_warning("JOURNAL_ENHANCEMENTS.md not found")

    def check_code_quality(self):
        """Check code quality issues"""
        print(f"\n{Colors.BOLD}=== Checking Code Quality ==={Colors.END}")

        r_dir = self.package_dir / 'R'
        if not r_dir.exists():
            return

        for r_file in r_dir.glob('*.R'):
            content = r_file.read_text()

            # Check for TODO/FIXME comments
            todos = len(re.findall(r'#\s*(TODO|FIXME)', content, re.IGNORECASE))
            if todos > 0:
                self.log_info(f"{r_file.name}: {todos} TODO/FIXME comments")

            # Check for browser() debug statements
            if 'browser()' in content:
                self.log_warning(f"{r_file.name}: Contains browser() debug statement")

            # Check for print() statements (message() or cat() preferred in packages)
            print_calls = len(re.findall(r'\bprint\s*\(', content))
            if print_calls > 2:
                self.log_info(f"{r_file.name}: Uses print() {print_calls} times (consider message() or cat())")

    def generate_report(self):
        """Generate final validation report"""
        print(f"\n{Colors.BOLD}{'='*60}{Colors.END}")
        print(f"{Colors.BOLD}VALIDATION REPORT{Colors.END}")
        print(f"{Colors.BOLD}{'='*60}{Colors.END}\n")

        print(f"{Colors.BOLD}Package Statistics:{Colors.END}")
        print(f"  R files: {self.stats.get('r_files', 0)}")
        print(f"  Total functions: {self.stats.get('total_functions', 0)}")
        print(f"  Documented functions: {self.stats.get('documented_functions', 0)}")
        print(f"  Exported functions: {self.stats.get('exports', 0)}")
        print(f"  Total lines of code: {self.stats.get('total_lines', 0)}")
        print(f"  Imports: {self.stats.get('imports', 0)}")

        print(f"\n{Colors.BOLD}Issues Found:{Colors.END}")
        print(f"  {Colors.RED}Errors: {len(self.errors)}{Colors.END}")
        print(f"  {Colors.YELLOW}Warnings: {len(self.warnings)}{Colors.END}")
        print(f"  {Colors.BLUE}Info: {len(self.info)}{Colors.END}")

        if len(self.errors) == 0:
            print(f"\n{Colors.GREEN}{Colors.BOLD}✓✓✓ VALIDATION PASSED ✓✓✓{Colors.END}")
            print(f"{Colors.GREEN}No critical errors found. Package structure is valid!{Colors.END}")
            return 0
        else:
            print(f"\n{Colors.RED}{Colors.BOLD}✗✗✗ VALIDATION FAILED ✗✗✗{Colors.END}")
            print(f"{Colors.RED}{len(self.errors)} error(s) must be fixed.{Colors.END}")
            return 1

    def run_all_validations(self):
        """Run all validation checks"""
        self.validate_file_structure()
        self.validate_description()
        self.validate_namespace()
        self.validate_r_files()
        self.validate_new_functions()
        self.validate_namespace_exports()
        self.validate_documentation_consistency()
        self.check_code_quality()
        return self.generate_report()

def main():
    # Determine package directory
    script_dir = Path(__file__).parent
    package_dir = script_dir.parent

    print(f"{Colors.BOLD}CBAMMR Package Validator{Colors.END}")
    print(f"Package directory: {package_dir}\n")

    validator = PackageValidator(package_dir)
    exit_code = validator.run_all_validations()
    sys.exit(exit_code)

if __name__ == '__main__':
    main()
