# CSV Templates and Examples

This directory contains example CSV files and blank templates for CBAMMR meta-analyses.

## Example Files (With Data)

### 1. `binary_outcomes_example.csv`
Example of binary outcome data (2x2 table format) from 6 RCTs.
**Use for:** Treatment vs control with binary outcomes (death, recovery, adverse events)

### 2. `continuous_outcomes_example.csv`
Example of continuous outcome data (means and SDs) from 6 RCTs.
**Use for:** Treatment vs control with continuous outcomes (pain scores, depression, blood pressure)

### 3. `effect_sizes_example.csv`
Example of pre-calculated effect sizes with variances.
**Use for:** When you already have effect sizes calculated

## Blank Templates

### 1. `blank_template_binary.csv`
Empty template for binary outcome data (10 studies).

### 2. `blank_template_continuous.csv`
Empty template for continuous outcome data (10 studies).

## How to Use

### Method 1: Use Example Data
```r
library(CBAMMR)

# Read example file
data <- read.csv("examples/csv_templates/binary_outcomes_example.csv")

# Run analysis
result <- cbamm_auto(data, pathway = "standard", study_id = "study")
```

### Method 2: Fill in Blank Template
1. Open blank template in Excel/Google Sheets/Numbers
2. Fill in your study data
3. Save as CSV
4. Load and analyze:
```r
data <- read.csv("your_data.csv")
result <- cbamm_auto(data, pathway = "standard")
```

### Method 3: Create Your Own
- See column names from examples
- Create your own CSV with same structure
- Add or remove columns as needed

## Quick Test

Test that everything works:
```r
library(CBAMMR)

# Test with binary data
data_binary <- read.csv("examples/csv_templates/binary_outcomes_example.csv")
result1 <- cbamm_auto(data_binary, pathway = "standard", study_id = "study")
print(result1)

# Test with continuous data
data_cont <- read.csv("examples/csv_templates/continuous_outcomes_example.csv")
result2 <- cbamm_auto(data_cont, pathway = "standard", study_id = "study")
print(result2)
```

## Need Help?

See `AUTHOR_GUIDE.md` in the main directory for complete instructions.
