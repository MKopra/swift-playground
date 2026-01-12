# Dark Fantasy Shader Comparison Workflow

## Overview

This document tracks the systematic comparison between the reference image (`darkfantasy.png`) and our Metal shader output, using a grid overlay system to analyze and match each section.

## Grid System

Both the reference image and shader use a **4x6 grid** (4 columns, 6 rows):

```
+----+----+----+----+
| A1 | B1 | C1 | D1 |  <- Top row (mostly black/arch top)
+----+----+----+----+
| A2 | B2 | C2 | D2 |  <- Upper (nebula/glow center)
+----+----+----+----+
| A3 | B3 | C3 | D3 |  <- Middle (stars/arc)
+----+----+----+----+
| A4 | B4 | C4 | D4 |  <- Lower-mid (mountains)
+----+----+----+----+
| A5 | B5 | C5 | D5 |  <- Lower (path/figure)
+----+----+----+----+
| A6 | B6 | C6 | D6 |  <- Bottom (path/ground)
+----+----+----+----+
```

**Grid Labels:**
- Columns: A, B, C, D (left to right)
- Rows: 1-6 (top to bottom)

## Deep Link Commands

```bash
# Reference image with grid
xcrun simctl openurl B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D "apiplayground://reference-grid"

# Shader with grid
xcrun simctl openurl B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D "apiplayground://metal-grid"

# Shader without grid
xcrun simctl openurl B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D "apiplayground://metal"
```

## Screenshot Commands

```bash
# Screenshot reference with grid
xcrun simctl io B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D screenshot /tmp/reference_grid.png

# Screenshot shader with grid
xcrun simctl io B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D screenshot /tmp/shader_grid.png
```

---

## Element Breakdown by Shader File

The shader should be organized by visual element, not by grid quadrant:

| Element | Current File | Grid Regions | Status |
|---------|-------------|--------------|--------|
| Arch Structure | DarkFantasy.metal | A1-A6, D1-D6, B1, C1 | In Progress |
| Nebula/Sun | DarkFantasy.metal | B2, C2 | In Progress |
| Stars | DarkFantasy.metal | B2-C4 | In Progress |
| Blue Arc | DarkFantasy.metal | B3-C3 | In Progress |
| Mountains (Left) | DarkFantasy.metal | A4-B4 | In Progress |
| Mountains (Right) | DarkFantasy.metal | C4-D4 | In Progress |
| Moon | DarkFantasy.metal | B4-C4 | In Progress |
| Path | DarkFantasy.metal | B5-C6 | In Progress |
| Figure + Rock | DarkFantasy.metal | B5-C5 | In Progress |
| Side Ground | DarkFantasy.metal | A5-A6, D5-D6 | In Progress |

---

## Grid Square Analysis

### Row 1 (A1, B1, C1, D1) - Top

| Square | Reference | Shader | Match? | Notes |
|--------|-----------|--------|--------|-------|
| A1 | Black + arch edge | | | |
| B1 | Black | | | |
| C1 | Black | | | |
| D1 | Black + arch edge | | | |

### Row 2 (A2, B2, C2, D2) - Nebula Region

| Square | Reference | Shader | Match? | Notes |
|--------|-----------|--------|--------|-------|
| A2 | Arch pillar | | | |
| B2 | Nebula glow left | | | |
| C2 | Nebula glow right | | | |
| D2 | Arch pillar | | | |

### Row 3 (A3, B3, C3, D3) - Stars/Arc Region

| Square | Reference | Shader | Match? | Notes |
|--------|-----------|--------|--------|-------|
| A3 | Arch pillar | | | |
| B3 | Stars + blue arc | | | |
| C3 | Stars + blue arc | | | |
| D3 | Arch pillar | | | |

### Row 4 (A4, B4, C4, D4) - Mountains

| Square | Reference | Shader | Match? | Notes |
|--------|-----------|--------|--------|-------|
| A4 | Arch + left mtns | | | |
| B4 | Left ice spires + moon | | | |
| C4 | Right mtns + moon | | | |
| D4 | Arch + right mtns | | | |

### Row 5 (A5, B5, C5, D5) - Figure/Path

| Square | Reference | Shader | Match? | Notes |
|--------|-----------|--------|--------|-------|
| A5 | Arch base + ground | | | |
| B5 | Path + figure left | | | |
| C5 | Path + figure right | | | |
| D5 | Arch base + ground | | | |

### Row 6 (A6, B6, C6, D6) - Bottom

| Square | Reference | Shader | Match? | Notes |
|--------|-----------|--------|--------|-------|
| A6 | Arch base | | | |
| B6 | Path bottom left | | | |
| C6 | Path bottom right | | | |
| D6 | Arch base | | | |

---

## Current Iteration Progress

### Iteration 16 - Grid System Setup
- [x] Added reference image to bundle
- [x] Created ReferenceImageView with grid overlay
- [x] Added grid overlay to MetalView
- [x] Set up deep links for all views
- [ ] Take initial comparison screenshots
- [ ] Begin square-by-square analysis

---

## Workflow Steps

1. **Build and install app**
   ```bash
   osascript -e 'tell application "Xcode" to activate' && sleep 0.5 && osascript -e 'tell application "System Events" to tell process "Xcode" to keystroke "b" using command down'
   sleep 25
   xcrun simctl install B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D /Users/mattkopra/Library/Developer/Xcode/DerivedData/APIPlayground-hhcclueisxiqkrflnjzurxlobesc/Build/Products/Debug-iphonesimulator/APIPlayground.app
   ```

2. **Screenshot reference image with grid**
   ```bash
   xcrun simctl terminate B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D com.apiplayground 2>/dev/null
   xcrun simctl openurl B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D "apiplayground://reference-grid"
   sleep 2
   xcrun simctl io B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D screenshot /tmp/reference_grid.png
   ```

3. **Screenshot shader with grid**
   ```bash
   xcrun simctl terminate B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D com.apiplayground 2>/dev/null
   xcrun simctl openurl B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D "apiplayground://metal-grid"
   sleep 2
   xcrun simctl io B9EF2F79-BCA9-4497-9D0B-FCD437B5B35D screenshot /tmp/shader_grid.png
   ```

4. **Compare specific grid square** (e.g., B4 - left mountains)
   - Analyze reference image colors/shapes in that square
   - Identify differences in shader output
   - Make targeted shader edits
   - Rebuild and re-screenshot
   - Update this document with progress

5. **Repeat for each grid square until all match**

---

## Color Reference (from reference image analysis)

| Element | Approximate Hex | RGB |
|---------|----------------|-----|
| Arch deep red | #A02010 | (160, 32, 16) |
| Arch bright red | #E04525 | (224, 69, 37) |
| Path cream | #E0D4C0 | (224, 212, 192) |
| Mountain white | #F0F4F8 | (240, 244, 248) |
| Mountain shadow | #6878A0 | (104, 120, 160) |
| Rock blue-grey | #4A5868 | (74, 88, 104) |
| Figure orange | #C04520 | (192, 69, 32) |
| Moon silver | #A0A8B8 | (160, 168, 184) |
| Pure black | #000000 | (0, 0, 0) |

---

## Notes

- Always compare with grid overlay first
- Focus on one element at a time
- Document color/position differences precisely
- Test pan gesture periodically to ensure it still works
- Consider splitting shader into multiple files for complex elements
