# CBAMMR Plot Customization Guide

## Overview

The CBAMMR Shiny app now provides **comprehensive customization** for forest and funnel plots. Every aspect of the plots can be customized, including colors, ranges, labels, styles, and more.

## Features

### Forest Plot Customization

#### Style Presets
Choose from publication-ready styles:
- **Classic** - Standard black & white style
- **Meta R Package** - Colorful style matching the meta R package
- **RevMan Style** - Cochrane RevMan style (black, square markers)
- **NEJM Style** - New England Journal of Medicine style (blue/red, diamond markers)

#### Range & Scale
- **X-axis Range**: Set custom min/max values (auto-calculated if not specified)
- **Tick Marks**: Control number of axis ticks (3-10)
- **Decimals**: Set precision (0-4 decimal places)

#### Colors (Full Customization)
- **Effect Color**: Color for individual study effect sizes
- **Border**: Border color for effect markers
- **Diamond**: Color for pooled effect diamond
- **Prediction Interval**: Color for prediction interval
- **Grid Lines**: Color for reference grid lines
- **Text**: Color for all text labels
- **Background**: Plot background color

#### Appearance
- **Text Size**: Adjustable from 0.5x to 2.0x
- **Line Width**: Control line thickness (0.5-5.0)
- **Point Style**: Choose marker shape
  - Square (15)
  - Circle (16)
  - Diamond (18)
  - Triangle (17)
  - Plus (3)

#### Options
- **Show Weights**: Display study weights (checkbox)
- **Show Prediction Interval**: Add 95% prediction interval (checkbox)
- **Show Annotations**: Display effect estimates and CIs (checkbox)

#### Labels
- **X-axis Label**: Custom x-axis text (auto-generated if blank)
- **Pooled Label**: Custom label for pooled effect

### Funnel Plot Customization

#### Range & Scale
- **X-axis Range**: Set custom min/max values
- **Y-axis Range**: Set custom min/max values
- **Tick Marks**: Control number of axis ticks (3-10)
- **Decimals**: Set precision (0-4 decimal places)

#### Colors (Full Customization)
- **Point Color**: Color for data points
- **Point Fill**: Fill color for points (if using filled markers)
- **Contours**: Color for funnel contour lines
- **Reference Line**: Color for central reference line
- **Text**: Color for all text labels
- **Background**: Plot background color

#### Appearance
- **Point Size**: Adjustable from 0.5x to 3.0x
- **Line Width**: Control line thickness (0.5-5.0)
- **Point Style**: Choose marker shape
  - Filled Circle (21)
  - Circle (1)
  - Square (0)
  - Diamond (5)
  - Triangle (2)

#### Options
- **Shade Contours**: Shade confidence regions (checkbox)
- **Confidence Level**: Set contour confidence level (80-99%)

#### Labels
- **X-axis Label**: Custom x-axis text
- **Y-axis Label**: Custom y-axis text (default: "Standard Error")
- **Title**: Custom plot title

## Usage in Shiny App

### Navigation
1. Run your meta-analysis
2. Go to the **Plots** tab
3. View default plots in main panels (left side)
4. Click **Forest Plot Settings** or **Funnel Plot Settings** to expand customization panels (right side)

### Customization Workflow
1. **Start with a preset** (forest plots only):
   - Select Classic, Meta R, RevMan, or NEJM style
   - Preset automatically adjusts colors, markers, and line widths

2. **Fine-tune individual settings**:
   - Adjust range if plots are too cramped or have too much white space
   - Change colors to match your journal's style guide
   - Modify text size for better readability
   - Add prediction intervals for forest plots

3. **Preview changes**:
   - All changes update the plot in real-time
   - No need to re-run the analysis

4. **Download**:
   - PNG format: High resolution (300 DPI) for publications
   - PDF format: Vector graphics for perfect scaling

5. **Reset if needed**:
   - Click "Reset to Defaults" button at bottom of settings panel

## Download Options

### Forest Plots
- **PNG**: 3600×3000 pixels at 300 DPI (publication-ready)
- **PDF**: 12×10 inches (vector, scalable)

### Funnel Plots
- **PNG**: 3000×3000 pixels at 300 DPI (publication-ready)
- **PDF**: 10×10 inches (vector, scalable)

All downloads respect your custom settings (colors, ranges, labels, etc.)

## Examples

### Example 1: RevMan-Style Forest Plot
```
1. Select "RevMan Style" preset
2. Result:
   - Black colors throughout
   - Square markers
   - Traditional Cochrane appearance
   - Header: "Study | Effect [95% CI]"
```

### Example 2: NEJM-Style Forest Plot with Prediction Interval
```
1. Select "NEJM Style" preset
2. Check "Show Prediction Interval"
3. Result:
   - Navy blue study effects
   - Dark red pooled diamond
   - Green prediction interval
   - Diamond markers
   - Professional journal appearance
```

### Example 3: Custom Color Scheme
```
1. Start with "Classic" preset
2. Customize colors:
   - Effect Color: #2E86AB (teal)
   - Border: #2E86AB (teal)
   - Diamond: #A23B72 (magenta)
   - Background: #F5F5F5 (light gray)
3. Adjust text size to 1.2x for better readability
4. Result: Modern, colorful plot with custom branding
```

### Example 4: Restricted Range Funnel Plot
```
1. Set X-axis Range: -1.5 to 1.5
2. Set Y-axis Range: 0 to 0.5
3. Increase Point Size to 1.5x
4. Change Point Color to dark blue
5. Result: Zoomed-in funnel plot highlighting central region
```

## Technical Details

### Implementation
- Custom plotting functions in `inst/shiny/global.R`:
  - `custom_forest_plot()`: Enhanced forest plot with 25+ parameters
  - `custom_funnel_plot()`: Enhanced funnel plot with 20+ parameters
- Both functions built on top of `metafor::forest()` and `metafor::funnel()`
- All parameters exposed to user through Shiny UI

### Forest Plot Parameters
```r
custom_forest_plot(
  fit,                  # metafor rma object
  style,                # "classic", "meta", "revman", "nejm"
  xlim,                 # X-axis limits c(min, max)
  alim,                 # Axis limits to display
  at,                   # Tick mark positions
  steps,                # Number of tick marks
  digits,               # Decimal places
  showweights,          # Show study weights
  show_pred,            # Show prediction interval
  col,                  # Effect color
  border,               # Border color
  col_diamond,          # Diamond color
  col_pred,             # Prediction interval color
  col_lines,            # Grid line color
  col_text,             # Text color
  col_background,       # Background color
  cex,                  # Text size
  cex_lab,              # Axis label size
  cex_axis,             # Axis tick label size
  lwd,                  # Line width
  pch,                  # Point character
  xlab,                 # X-axis label
  slab,                 # Study labels
  header,               # Custom header
  mlab,                 # Pooled effect label
  top,                  # Top margin
  annotate,             # Show annotations
  addfit,               # Add pooled estimate
  addpred               # Add prediction interval
)
```

### Funnel Plot Parameters
```r
custom_funnel_plot(
  fit,                  # metafor rma object
  xlim,                 # X-axis limits
  ylim,                 # Y-axis limits
  steps,                # Number of tick marks
  digits,               # Decimal places
  col,                  # Point color
  bg,                   # Point fill color
  pch,                  # Point character
  cex,                  # Point size
  lwd,                  # Line width
  col_contour,          # Contour line color
  col_ref,              # Reference line color
  col_background,       # Background color
  col_text,             # Text color
  shade_contours,       # Shade contour regions
  level,                # Confidence level
  xlab,                 # X-axis label
  ylab,                 # Y-axis label
  main,                 # Title
  refline,              # Reference line position
  cex_lab,              # Label size
  cex_axis              # Axis label size
)
```

## Journal-Specific Recommendations

### Cochrane Reviews
- Use **RevMan Style** preset
- Black and white only
- Square markers
- Keep default text sizes
- Include prediction intervals

### Nature/Science Journals
- Use **Classic** style
- High contrast colors
- Text size: 1.2-1.4x
- PDF format for submission
- Clean, minimal design

### Medical Journals (NEJM, JAMA, BMJ)
- Use **NEJM Style** preset or customize
- Professional blue/red color scheme
- Diamond markers for visual interest
- Clear, readable labels
- High-resolution PNG (300 DPI)

### Statistics Journals
- Use **Meta R Package** style
- Colorful but professional
- Show prediction intervals
- Include all annotations
- PDF format for vector graphics

## Tips and Best Practices

### Range Adjustment
- **Too cramped?** Increase max range
- **Too much white space?** Decrease range
- **Auto-calculate**: Leave both min and max blank

### Color Selection
- **High contrast**: Ensure text readable against background
- **Colorblind-friendly**: Avoid red-green combinations
- **Print-friendly**: Test in grayscale if printing B&W

### Text Size
- **Presentations**: 1.4-2.0x
- **Papers**: 1.0-1.2x
- **Posters**: 1.5-2.0x

### Download Format
- **PNG**: For PowerPoint, Word, most journals
- **PDF**: For LaTeX, vector graphics, perfect scaling

### Prediction Intervals
- **Always show** for clinical decision-making
- Shows range of true effects in future studies
- Green color distinguishes from confidence interval

## Troubleshooting

### Problem: Plot looks squished
**Solution**: Increase x-axis range or adjust tick marks (fewer ticks = more space)

### Problem: Text overlaps
**Solution**: Decrease text size or increase plot area in download

### Problem: Colors don't match preset after manual changes
**Solution**: Click "Reset to Defaults" then reselect preset

### Problem: Prediction interval not showing
**Solution**: Ensure "Show Prediction Interval" checkbox is checked and sufficient heterogeneity exists

### Problem: Downloaded plot differs from preview
**Solution**: All settings should transfer - check if browser blocked download, try again

## Future Enhancements

Planned for future versions:
- Additional style presets (Lancet, BMC, etc.)
- Custom annotation formats
- Study label formatting options
- Contour enhancement controls for funnel plots
- Export to additional formats (SVG, EPS)
- Save/load custom style profiles

## Support

For questions or issues:
- GitHub Issues: https://github.com/mahmood726-cyber/CBAMMR/issues
- Package Documentation: `?run_cbammr_app`

## Version History

- **v7.0**: Initial comprehensive plot customization (2025-10-27)
  - Forest plot: 4 style presets, 25+ parameters
  - Funnel plot: 20+ parameters
  - Real-time preview
  - High-resolution downloads (PNG, PDF)
