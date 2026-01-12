# SaaraNote Design System

## Overview

This design system implements the UI/UX specifications from `SAARANOTE_UI_UX_DESIGN.md` using Material Design 3 principles. It provides a comprehensive set of colors, typography, spacing, components, and themes to ensure consistency across the app.

## Quick Start

```dart
import 'package:saaranote_app/core/design_system/design_system.dart';

// Use design system components
AppCard(
  child: Text('Hello', style: AppTypography.body()),
  padding: AppSpacing.paddingMd,
)
```

---

## 📦 Components

### 1. Colors (`app_colors.dart`)

#### Usage

```dart
// Access colors by brightness
AppColors.primary(Brightness.light)       // #5B7BF5
AppColors.primary(Brightness.dark)        // #7B96F7

// Or use specific variants
AppColors.primaryLight                    // #5B7BF5
AppColors.primaryDark                     // #7B96F7

// Semantic colors
AppColors.successLight                    // #10B981
AppColors.errorLight                      // #EF4444
AppColors.warningLight                    // #F59E0B

// Gray scale (6 levels)
AppColors.gray50Light to AppColors.gray900Light

// Accent colors
AppColors.tagBlue                         // #3B82F6
AppColors.tagGreen                        // #10B981
AppColors.folderYellow                    // #FBBF24
```

#### Light Mode Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#5B7BF5` | Buttons, links, focus states |
| Success | `#10B981` | Success messages, confirmations |
| Error | `#EF4444` | Error states, destructive actions |
| Warning | `#F59E0B` | Warnings, caution states |
| Gray 50 | `#FAFAFA` | Input backgrounds |
| Gray 900 | `#212121` | Primary text |

#### Dark Mode Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary | `#7890FF` | Buttons, links, focus states (desaturated) |
| Success | `#34D399` | Success messages |
| Error | `#F87171` | Error states |
| Warning | `#FBBF24` | Warnings |
| Gray 50 | `#0F172A` | Page background |
| Gray 900 | `#F1F5F9` | Primary text |

Dark mode colors are automatically desaturated for reduced eye strain. All colors maintain WCAG AA contrast ratios (4.5:1+).

---

### 2. Typography (`app_typography.dart`)

Based on **Inter** font with optimized reading settings.

#### Text Styles

```dart
// Display (32px, Bold) - Main headlines
AppTypography.display(color: AppColors.textPrimaryLight)

// Heading 1 (24px, Semibold) - Section headers
AppTypography.h1()

// Heading 2 (20px, SemiBold) - Sub-sections
AppTypography.h2()

// Heading 3 (18px, Medium) - Card titles
AppTypography.h3()

// Body (16px, Regular) - Main content
AppTypography.body()

// Body Small (14px, Regular) - Descriptions
AppTypography.bodySmall()

// Label (14px, Medium) - Input labels, navigation
AppTypography.label()

// Button (16px, Medium) - Button text, CTAs
AppTypography.button()

// Caption (12px, Regular) - Timestamps
AppTypography.caption()

// Note Content (18px, Regular) - Reading-optimized for note detail
AppTypography.noteContent()
```

#### Line Heights

- **Body text**: 1.6 (standard for UI)
- **Note content**: 1.7 (optimal for reading)
- **Headings**: 1.3 (tighter for emphasis)
- **Labels**: 1.4 (balanced for UI elements)

#### Font Weights

```dart
AppTypography.regular    // 400
AppTypography.medium     // 500
AppTypography.semiBold   // 600
AppTypography.bold       // 700
```

#### Reading Optimization

For note detail views, use `AppTypography.noteContent()` which provides:
- Font size: 18px (larger for reading comfort)
- Line height: 1.7 (generous for comprehension)
- Optimal for long-form reading

---

### 3. Spacing (`app_spacing.dart`)

8px base unit with consistent scale.

#### Spacing Scale

```dart
AppSpacing.xs    // 4px
AppSpacing.sm    // 8px
AppSpacing.md    // 16px
AppSpacing.lg    // 24px
AppSpacing.xl    // 32px
AppSpacing.xxl   // 48px
AppSpacing.xxxl  // 64px
```

#### Edge Insets

```dart
// Padding presets
AppSpacing.paddingMd              // EdgeInsets.all(16)
AppSpacing.horizontalMd           // EdgeInsets.symmetric(horizontal: 16)
AppSpacing.verticalMd             // EdgeInsets.symmetric(vertical: 16)

// Page/screen padding
AppSpacing.pagePadding            // Horizontal 16px
AppSpacing.screenPadding          // All sides 16px
```

#### Gaps (SizedBox)

```dart
AppSpacing.gapMd       // SizedBox(width: 16, height: 16)
AppSpacing.hGapMd      // SizedBox(width: 16)
AppSpacing.vGapMd      // SizedBox(height: 16)
```

#### Border Radius

```dart
AppSpacing.radiusXs            // 4px
AppSpacing.radiusSm            // 8px
AppSpacing.radiusMd            // 12px
AppSpacing.radiusLg            // 16px
AppSpacing.radiusFull          // 999px (pill shape)

// BorderRadius presets
AppSpacing.borderRadiusMd      // BorderRadius.circular(12)
```

#### Icon Sizes

```dart
AppSpacing.iconSm      // 16px
AppSpacing.iconMd      // 20px
AppSpacing.iconLg      // 24px
AppSpacing.iconXl      // 32px
```

#### Touch Targets

```dart
AppSpacing.minTouchTarget      // 48px (accessibility minimum)
```

---

### 4. Components (`app_components.dart`)

#### AppCard

```dart
AppCard(
  child: Text('Content'),
  padding: AppSpacing.paddingLg,
  onTap: () => print('Tapped'),
)
```

#### AppListCard

```dart
AppListCard(
  title: 'Note Title',
  subtitle: 'Last edited today',
  leading: Icon(Icons.note),
  trailing: Icon(Icons.chevron_right),
  onTap: () => navigateToDetail(),
)
```

#### AppEmptyState

```dart
AppEmptyState(
  icon: Icons.note_add_outlined,
  title: 'No notes yet',
  message: 'Tap + to create your first note',
  action: ElevatedButton(
    onPressed: createNote,
    child: Text('Create Note'),
  ),
)
```

#### AppLoadingIndicator

```dart
AppLoadingIndicator(message: 'Loading notes...')
```

#### AppSearchBar

```dart
AppSearchBar(
  controller: _searchController,
  hintText: 'Search notes...',
  onChanged: (query) => search(query),
  onClear: () => clearSearch(),
)
```

#### AppChip

```dart
AppChip(
  label: 'Math',
  backgroundColor: AppColors.tagBlue,
  onTap: () => filterByTag(),
  onDeleted: () => removeTag(),
)
```

#### AppInfoBanner

```dart
AppInfoBanner(
  message: 'Note saved successfully',
  icon: Icons.check_circle,
  backgroundColor: AppColors.successLightBg,
  onDismiss: () => closeBanner(),
)
```

#### AppSectionHeader

```dart
AppSectionHeader(
  title: 'Recent Notes',
  action: TextButton(
    onPressed: viewAll,
    child: Text('View All'),
  ),
)
```

---

### 5. Theme (`app_theme.dart`)

Material Design 3 implementation with light and dark modes.

#### Usage

```dart
// In main.dart
MaterialApp(
  theme: AppTheme.lightTheme(),
  darkTheme: AppTheme.darkTheme(),
  themeMode: ThemeMode.system,
)
```

#### Themed Components

All Material components are pre-styled:
- ✅ AppBar (no elevation, system-adaptive)
- ✅ Card (bordered, 12px radius)
- ✅ ElevatedButton (48px minimum, 8px radius)
- ✅ TextButton, OutlinedButton
- ✅ TextField (filled style, rounded)
- ✅ Chip (pill-shaped)
- ✅ Dialog (16px radius)
- ✅ SnackBar (floating, rounded)
- ✅ FloatingActionButton

#### Accessing Theme Colors

```dart
final theme = Theme.of(context);
final primary = theme.colorScheme.primary;
final surface = theme.colorScheme.surface;
final textColor = theme.colorScheme.onSurface;
```

---

## 🎨 Design Principles

### 1. Calm & Focused
- Soft colors with high contrast for readability
- Minimal animations (200-300ms)
- Clean, uncluttered layouts

### 2. Student-Friendly
- Large touch targets (48px minimum)
- Clear visual hierarchy
- Intuitive navigation

### 3. Accessibility
- WCAG 2.1 AA compliant (4.5:1+ contrast)
- Readable font sizes (18px body)
- Screen reader support

### 4. Consistent
- 8px spacing grid
- Unified color palette
- Systematic typography

---

## 📱 Responsive Design

### Breakpoints

```dart
// Phone portrait
width < 600

// Phone landscape / small tablet
600 <= width < 840

// Tablet
840 <= width < 1200

// Desktop
width >= 1200
```

### Usage Example

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= 840) {
      return TabletLayout();
    }
    return PhoneLayout();
  },
)
```

---

## 🌙 Dark Mode

Dark mode automatically activates based on system settings. Colors are optimized for:
- Reduced eye strain (desaturated primaries)
- True black backgrounds (#121212)
- Proper elevation (surfaces lighter than background)

### Testing Dark Mode

```dart
// Force dark mode for testing
MaterialApp(
  themeMode: ThemeMode.dark,
  // ...
)
```

---

## 🧪 Testing

### Visual Consistency

1. Check spacing grid alignment
2. Verify touch target sizes
3. Test color contrast
4. Validate typography scale

### Accessibility

1. Enable TalkBack/VoiceOver
2. Test with large text
3. Verify color contrast
4. Check keyboard navigation

### Example Test

```dart
testWidgets('Button meets minimum touch target', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme(),
      home: ElevatedButton(
        onPressed: () {},
        child: Text('Test'),
      ),
    ),
  );

  final buttonSize = tester.getSize(find.byType(ElevatedButton));
  expect(buttonSize.height, greaterThanOrEqualTo(AppSpacing.minTouchTarget));
});
```

---

## 🚀 Best Practices

### DO ✅

```dart
// Use design system components
AppCard(child: content, padding: AppSpacing.paddingMd)

// Use semantic naming
color: AppColors.error(brightness)

// Use spacing constants
SizedBox(height: AppSpacing.md)

// Use typography styles
Text('Title', style: AppTypography.h3())
```

### DON'T ❌

```dart
// Don't use magic numbers
SizedBox(height: 13)

// Don't hardcode colors
color: Color(0xFF123456)

// Don't use arbitrary font sizes
fontSize: 17.5

// Don't skip design system
Card(color: Colors.red, elevation: 5)
```

---

## 📚 Related Documentation

- [SAARANOTE_UI_UX_DESIGN.md](../../../SAARANOTE_UI_UX_DESIGN.md) - Complete UI/UX specifications
- [SAARANOTE_2.0_DESIGN.md](../../../SAARANOTE_2.0_DESIGN.md) - System architecture
- [README.md](../../../saaranote_app/README.md) - Developer guide

---

## 🔄 Migration Guide

### Converting Existing Code

**Before:**
```dart
Card(
  margin: EdgeInsets.all(8),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Text(
      'Title',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
  ),
)
```

**After:**
```dart
AppCard(
  padding: AppSpacing.paddingMd,
  child: Text('Title', style: AppTypography.h3()),
)
```

---

## 🎯 Quick Reference

| Need | Use |
|------|-----|
| Card component | `AppCard` |
| List item | `AppListCard` |
| Empty screen | `AppEmptyState` |
| Loading | `AppLoadingIndicator` |
| Search input | `AppSearchBar` |
| Tag/filter | `AppChip` |
| Alert banner | `AppInfoBanner` |
| Section title | `AppSectionHeader` |
| Spacing | `AppSpacing.md`, `AppSpacing.gapLg` |
| Colors | `AppColors.primary(brightness)` |
| Text | `AppTypography.body()` |
| Theme | `Theme.of(context)` |

---

## 📞 Support

For questions or issues with the design system, refer to:
1. This documentation
2. Component source code in `lib/core/design_system/`
3. UI/UX specification document
4. Material Design 3 guidelines: https://m3.material.io/

---

**Last Updated:** January 2026  
**Version:** 1.0.0  
**Design System Status:** ✅ Production Ready
