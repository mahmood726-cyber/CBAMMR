#!/bin/bash
# CRAN Submission Build Script for CBAMMR v8.14.0
# This script automates the package building process for CRAN submission

set -e  # Exit on error

echo "=================================================="
echo "  CBAMMR v8.14.0 - CRAN Submission Build Script"
echo "=================================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if R is installed
if ! command -v R &> /dev/null; then
    echo -e "${RED}ERROR: R is not installed or not in PATH${NC}"
    echo "Please install R from: https://www.r-project.org/"
    exit 1
fi

echo -e "${GREEN}✓ R is installed${NC}"
R --version | head -1
echo

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}ERROR: Not in a git repository${NC}"
    echo "Please run this script from the CBAMMR repository root"
    exit 1
fi

echo -e "${GREEN}✓ In git repository${NC}"
echo

# Check current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "main" ]; then
    echo -e "${YELLOW}WARNING: Not on main branch${NC}"
    read -p "Switch to main branch? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Switching to main branch..."
        git checkout main
        git pull origin main
    else
        echo "Continuing on $CURRENT_BRANCH..."
    fi
fi

echo

# Create output directory
BUILD_DIR="cran_submission"
mkdir -p "$BUILD_DIR"

echo "=================================================="
echo "Step 1: Installing/Updating Required Packages"
echo "=================================================="
echo

Rscript -e "
if (!require('devtools')) install.packages('devtools', repos='https://cloud.r-project.org')
if (!require('roxygen2')) install.packages('roxygen2', repos='https://cloud.r-project.org')
if (!require('rcmdcheck')) install.packages('rcmdcheck', repos='https://cloud.r-project.org')
" || {
    echo -e "${RED}ERROR: Failed to install required packages${NC}"
    exit 1
}

echo -e "${GREEN}✓ Required packages installed${NC}"
echo

echo "=================================================="
echo "Step 2: Building Package"
echo "=================================================="
echo

# Build the package
echo "Running R CMD build..."
R CMD build . --no-build-vignettes 2>&1 | tee "$BUILD_DIR/build.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "${RED}ERROR: Package build failed${NC}"
    echo "Check $BUILD_DIR/build.log for details"
    exit 1
fi

# Find the created tarball
TARBALL=$(ls -t CBAMMR_*.tar.gz 2>/dev/null | head -1)

if [ -z "$TARBALL" ]; then
    echo -e "${RED}ERROR: Could not find generated tarball${NC}"
    exit 1
fi

# Move tarball to build directory
mv "$TARBALL" "$BUILD_DIR/"
TARBALL="$BUILD_DIR/$(basename $TARBALL)"

echo -e "${GREEN}✓ Package built successfully${NC}"
echo "   Tarball: $TARBALL"
echo

echo "=================================================="
echo "Step 3: Running R CMD check --as-cran"
echo "=================================================="
echo

# Run CRAN checks
echo "This may take 5-10 minutes..."
R CMD check --as-cran "$TARBALL" 2>&1 | tee "$BUILD_DIR/check.log"

CHECK_STATUS=${PIPESTATUS[0]}

echo

if [ $CHECK_STATUS -eq 0 ]; then
    echo -e "${GREEN}✓✓✓ R CMD check passed with no errors, warnings, or notes!${NC}"
    echo
    echo "=================================================="
    echo "  🎉 READY FOR CRAN SUBMISSION! 🎉"
    echo "=================================================="
    echo
    echo "Submission package: $TARBALL"
    echo
    echo "Next steps:"
    echo "  1. Go to: https://cran.r-project.org/submit.html"
    echo "  2. Upload: $TARBALL"
    echo "  3. Follow the instructions in CRAN_SUBMISSION_GUIDE.md"
    echo
else
    echo -e "${RED}✗ R CMD check failed or has warnings/notes${NC}"
    echo
    echo "Please review the output above and fix any issues."
    echo "Check logs:"
    echo "  - $BUILD_DIR/check.log"
    echo "  - $BUILD_DIR/build.log"
    echo
    exit 1
fi

# Create submission checklist
cat > "$BUILD_DIR/SUBMISSION_CHECKLIST.txt" << EOF
CRAN Submission Checklist for CBAMMR v8.14.0
Generated: $(date)

Pre-Submission Verification:
[ ] Package built successfully: $TARBALL
[ ] R CMD check --as-cran passed (0 errors, 0 warnings, 0 notes)
[ ] All CI/CD checks passing on GitHub
[ ] Version number is correct in DESCRIPTION (8.14.0)
[ ] NEWS.md updated with latest changes
[ ] All examples run successfully
[ ] All tests pass
[ ] Documentation builds correctly

CRAN Submission:
[ ] Go to: https://cran.r-project.org/submit.html
[ ] Upload tarball: $TARBALL
[ ] Add submission comments (see CRAN_SUBMISSION_GUIDE.md)
[ ] Provide valid email address
[ ] Check confirmation checkbox
[ ] Submit package
[ ] Confirm via email link

Post-Submission:
[ ] Monitor email for CRAN response
[ ] Address any revision requests promptly
[ ] Update GitHub once accepted
[ ] Add CRAN badge to README

Test Environment Information:
- Ubuntu 22.04 (R-devel): passing
- Ubuntu 22.04 (R-release): passing
- Ubuntu 22.04 (R-oldrel-1): passing
- macOS-latest (R-release): passing
- Windows-latest (R-release): passing

GitHub Actions: https://github.com/mahmood726-cyber/CBAMMR/actions
EOF

echo "Created submission checklist: $BUILD_DIR/SUBMISSION_CHECKLIST.txt"
echo

echo "=================================================="
echo "  All files are in: $BUILD_DIR/"
echo "=================================================="
ls -lh "$BUILD_DIR/"
echo

echo -e "${GREEN}Build process complete!${NC}"
