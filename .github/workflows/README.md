# GitHub Actions CI/CD Workflows for CBAMMR

This directory contains automated workflows for continuous integration, testing, and deployment of the CBAMMR package.

## Workflows

### 1. R-CMD-check.yaml

**Purpose:** Comprehensive package checking across multiple R versions and operating systems

**Triggers:**
- Push to main, master, or claude/* branches
- Pull requests to main or master
- Daily schedule at midnight UTC

**What it does:**
- Runs `R CMD check` on Ubuntu (devel, release, oldrel-1), macOS (release), and Windows (release)
- Tests package across 5 different configurations
- Checks for errors, warnings, and notes
- Uploads check results if failures occur

**Best for:** Ensuring package works across different environments

---

### 2. test-coverage.yaml

**Purpose:** Measure and report test coverage

**Triggers:**
- Push to main, master, or claude/* branches
- Pull requests to main or master

**What it does:**
- Runs all tests with coverage measurement using `covr`
- Uploads coverage reports to Codecov
- Shows which lines of code are tested

**Best for:** Monitoring code quality and test completeness

---

### 3. lint.yaml

**Purpose:** Check code style and quality

**Triggers:**
- Push to main, master, or claude/* branches
- Pull requests to main or master

**What it does:**
- Runs `lintr` to check code style
- Runs `styler` to verify consistent formatting
- Fails if code doesn't meet style guidelines

**Best for:** Maintaining consistent code style

---

### 4. pkgdown.yaml

**Purpose:** Build and deploy package documentation website

**Triggers:**
- Push to main or master
- Pull requests to main or master
- Package releases
- Manual trigger

**What it does:**
- Builds documentation website using `pkgdown`
- Deploys to GitHub Pages (gh-pages branch)
- Creates searchable function reference

**Best for:** User documentation and package website

---

### 5. pr-commands.yaml

**Purpose:** Allow PR reviewers to trigger actions via comments

**Triggers:**
- Issue/PR comments containing special commands

**Commands:**
- `/document` - Re-runs roxygen2 documentation generation
- `/style` - Applies code styling with styler

**What it does:**
- Responds to commands in PR comments
- Automatically commits changes back to PR

**Best for:** Quick fixes during PR review

---

## Configuration Files

### .lintr

Configures `lintr` for code quality checks:
- Line length: 120 characters
- Flexible object naming for backwards compatibility
- Exclusions for Shiny apps and test setup

### _pkgdown.yml

Configures package documentation website:
- Bootstrap 5 theme with Flatly bootswatch
- Custom navbar with reference, articles, news
- Organized function reference by category
- GitHub integration

### .github/dependabot.yml

Configures Dependabot for automated dependency updates:
- Weekly checks for GitHub Actions updates
- Monthly checks for container dependencies
- Automatic PR creation for updates

---

## Setting Up

### 1. Enable GitHub Actions

GitHub Actions are automatically enabled for repositories. No setup required.

### 2. Configure Secrets (Optional)

For full functionality, add these secrets in repository settings:

**CODECOV_TOKEN** (Optional but recommended)
- Sign up at https://codecov.io
- Add your repository
- Copy the token
- Add as repository secret

**How to add secrets:**
1. Go to repository Settings
2. Click Secrets and variables > Actions
3. Click "New repository secret"
4. Add name and value

### 3. Enable GitHub Pages (for documentation)

1. Go to repository Settings
2. Click Pages
3. Under "Source", select "Deploy from a branch"
4. Under "Branch", select `gh-pages` and `/ (root)`
5. Click Save

Your documentation will be available at:
`https://mahmood726-cyber.github.io/CBAMMR/`

---

## Monitoring Workflows

### View Workflow Runs

1. Go to the "Actions" tab in your repository
2. See all workflow runs and their status
3. Click on a run to see details

### Badges

Add these to your README.md to show workflow status:

```markdown
[![R-CMD-check](https://github.com/mahmood726-cyber/CBAMMR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mahmood726-cyber/CBAMMR/actions/workflows/R-CMD-check.yaml)
[![test-coverage](https://github.com/mahmood726-cyber/CBAMMR/actions/workflows/test-coverage.yaml/badge.svg)](https://github.com/mahmood726-cyber/CBAMMR/actions/workflows/test-coverage.yaml)
[![Codecov](https://codecov.io/gh/mahmood726-cyber/CBAMMR/branch/main/graph/badge.svg)](https://codecov.io/gh/mahmood726-cyber/CBAMMR)
```

---

## Troubleshooting

### Workflow fails on specific OS

- Check the workflow run logs
- OS-specific issues often relate to system dependencies
- Add system dependencies in the "Install system dependencies" step

### Coverage upload fails

- Ensure CODECOV_TOKEN is set (or remove token requirement)
- Check Codecov is enabled for your repository

### Documentation deployment fails

- Ensure gh-pages branch exists
- Check GitHub Pages is enabled in settings
- Verify permissions in workflow (contents: write, pages: write)

### Lint failures

- Run `lintr::lint_package()` locally
- Fix identified issues
- Or adjust `.lintr` configuration if rules are too strict

---

## Best Practices

### For Package Development

1. **Always run checks locally first:**
   ```r
   devtools::check()
   ```

2. **Write tests for new functions:**
   ```r
   usethis::use_test("function_name")
   ```

3. **Document functions with roxygen2:**
   ```r
   #' Title
   #' @export
   function_name <- function() {}
   ```

4. **Keep code coverage high:**
   - Aim for >80% coverage
   - Test edge cases and error conditions

### For Pull Requests

1. **Ensure all checks pass** before requesting review
2. **Use PR commands** (/document, /style) for quick fixes
3. **Add tests** for bug fixes and new features
4. **Update documentation** if adding/changing functionality

### For Releases

1. **Update NEWS.md** with changes
2. **Increment version** in DESCRIPTION
3. **Tag release** in GitHub
4. **Documentation** automatically deploys

---

## CI/CD Pipeline Flow

```
┌─────────────────┐
│   Git Push      │
└────────┬────────┘
         │
         ├──────────────┬──────────────┬─────────────┐
         ▼              ▼              ▼             ▼
    ┌────────┐     ┌────────┐    ┌────────┐   ┌─────────┐
    │R-CMD   │     │Coverage│    │ Lint   │   │pkgdown  │
    │check   │     │        │    │        │   │         │
    └────┬───┘     └───┬────┘    └───┬────┘   └────┬────┘
         │             │             │             │
         └─────────────┴─────────────┴─────────────┘
                        │
                        ▼
              ┌─────────────────┐
              │All checks pass? │
              └────────┬────────┘
                       │
                 Yes   │   No
            ┌──────────┼──────────┐
            ▼                     ▼
       ┌─────────┐         ┌──────────┐
       │ Deploy  │         │  Notify  │
       │  Docs   │         │  Failure │
       └─────────┘         └──────────┘
```

---

## Support

For issues with workflows:
1. Check workflow run logs in GitHub Actions
2. Review this README
3. Check r-lib/actions documentation: https://github.com/r-lib/actions
4. Open an issue in the repository

---

**Last Updated:** 2025-11-05
**CBAMMR Version:** 8.15.0
