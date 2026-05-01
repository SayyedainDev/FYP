# Theme System Guide

## Overview

Your app now has a **unified, professional theme system** that applies consistently across all screens for both doctor and student users. The theme automatically adapts based on the user's role.

## Features

✅ **Consistent Design** - All screens use the same professional theme  
✅ **Role-Based Themes** - Separate subtle color schemes for doctors and students  
✅ **Professional Typography** - Google Fonts (Sora for headers, DM Sans for body)  
✅ **Material 3 Design** - Modern, accessible UI components  
✅ **Semantic Colors** - Dedicated colors for success, warning, danger, info  
✅ **Dark Mode Support** - Full dark theme implementation  
✅ **Dynamic Theme Switching** - Themes automatically update based on user role  

## Theme Architecture

### File Structure

```
lib/
├── core/theme/
│   ├── app_theme.dart           # Main theme definitions
│   ├── app_semantic_colors.dart # Semantic color extension
│   ├── app_tokens.dart          # Design tokens & spacing
│   └── app_breakpoints.dart     # Responsive breakpoints
└── providers/
    └── theme_provider.dart      # Theme management provider
```

## How It Works

### 1. AppTheme Class (lib/core/theme/app_theme.dart)

The `AppTheme` class provides theme methods for different user roles:

```dart
// For doctors
ThemeData doctorLightTheme()
ThemeData doctorDarkTheme()

// For students
ThemeData studentLightTheme()
ThemeData studentDarkTheme()

// Universal themes
ThemeData light()
ThemeData dark()
```

### 2. ThemeProvider (lib/providers/theme_provider.dart)

Manages theme state and user role:

```dart
class ThemeProvider extends ChangeNotifier {
  UserRole _userRole;  // doctor, student, or unknown
  ThemeMode _themeMode; // light, dark, or system
  
  ThemeData get currentTheme // Returns theme based on role
  void setUserRole(UserRole role) // Updates user role
  void setThemeMode(ThemeMode mode) // Updates theme mode
}
```

### 3. Main App (lib/main.dart)

The app uses `Consumer2` to listen to both `AuthProvider` and `ThemeProvider`:

```dart
Consumer2<AuthProvider, ThemeProvider>(
  builder: (context, authProvider, themeProvider, _) {
    // Auto-update theme when user logs in
    if (authProvider.user?.role != null) {
      themeProvider.setUserRole(
        ThemeProvider.parseUserRole(authProvider.user!.role)
      );
    }
    
    return MaterialApp(
      theme: themeProvider.currentTheme,
      darkTheme: themeProvider.currentDarkTheme,
      // ...
    );
  }
)
```

## Color Scheme

### Doctor Theme (Professional Blue)
- **Primary**: `#3BA2F6` (Professional Blue)
- **Secondary**: Consistent secondary color
- **Surface**: Light gray backgrounds
- **On Surface**: Dark text on light backgrounds

### Student Theme (Learning Blue)
- **Primary**: `#50A0F5` (Learning Blue)
- **Secondary**: Consistent secondary color
- **Surface**: Light gray backgrounds
- **On Surface**: Dark text on light backgrounds

### Semantic Colors (Same for Both)
- **Success**: Green `#4ADE80`
- **Warning**: Amber `#FBBF24`
- **Danger**: Red `#F87171`
- **Info**: Cyan `#38BDF8`

## Typography

### Font Families
- **Headers** (H1, H2, H3): Google Fonts Sora (Bold, Semi-Bold)
- **Body Text**: Google Fonts DM Sans (Regular, Medium)

### Text Styles
```dart
headlineLarge:  32px, Bold
headlineMedium: 24px, Bold
headlineSmall:  20px, Semi-Bold
titleLarge:     20px, Semi-Bold
titleMedium:    16px, Semi-Bold
bodyLarge:      16px, Regular
bodyMedium:     14px, Regular
bodySmall:      12px, Regular
```

## Using the Theme in Screens

### Always use Theme.of(context)

```dart
// ✅ CORRECT - Uses app's theme
Container(
  color: Theme.of(context).colorScheme.primary,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.headlineSmall,
  ),
)

// ❌ WRONG - Hardcoded colors
Container(
  color: Colors.blue,
  child: Text(
    'Hello',
    style: TextStyle(color: Color(0xFF0000FF)),
  ),
)
```

### Accessing Semantic Colors

```dart
// Get semantic color extension
final semanticColors = Theme.of(context).extension<AppSemanticColors>();

// Use semantic colors
Container(
  color: semanticColors?.danger ?? Colors.red,
  child: Text('Error'),
)
```

### Building Custom Widgets

```dart
Widget _buildCustomCard(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  return Container(
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: colorScheme.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      'Card Content',
      style: theme.textTheme.bodyMedium,
    ),
  );
}
```

## Design Tokens

All spacing, radius, and sizing values are defined in `app_tokens.dart`:

```dart
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}
```

### Usage

```dart
Container(
  padding: const EdgeInsets.all(AppSpacing.lg),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)
```

## Switching Themes Programmatically

### Change Theme Mode (Light/Dark)

```dart
context.read<ThemeProvider>().setThemeMode(ThemeMode.dark);
```

### Change User Role

```dart
context.read<ThemeProvider>().setUserRole(UserRole.student);
```

## Component Styling

### Buttons

All button styles are defined in the theme:

```dart
// Elevated Button
ElevatedButton(
  onPressed: () {},
  child: Text('Primary Action'),
)

// Filled Button
FilledButton(
  onPressed: () {},
  child: Text('Secondary Action'),
)

// Text Button
TextButton(
  onPressed: () {},
  child: Text('Tertiary Action'),
)

// Outlined Button
OutlinedButton(
  onPressed: () {},
  child: Text('Alternative Action'),
)
```

### Input Fields

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Username',
    hintText: 'Enter your username',
    // All styling comes from theme
  ),
)
```

### Cards

```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Text('Card Content'),
  ),
)
```

### App Bar

```dart
AppBar(
  title: Text('Screen Title'),
  // Automatically styled from theme
)
```

## Common Use Cases

### 1. Building a Header Section

```dart
Container(
  color: Theme.of(context).colorScheme.surface,
  padding: const EdgeInsets.all(AppSpacing.lg),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Welcome Back',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Here\'s what\'s new today',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  ),
)
```

### 2. Building an Info Card with Status

```dart
Container(
  padding: const EdgeInsets.all(AppSpacing.lg),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(AppRadius.md),
    border: Border.all(
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  ),
  child: Row(
    children: [
      Icon(
        Icons.check_circle,
        color: Theme.of(context).extension<AppSemanticColors>()?.success,
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Text(
          'Operation completed successfully',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ],
  ),
)
```

### 3. Building a Chat Message

```dart
Align(
  alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
  child: Container(
    margin: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: isMyMessage
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: isMyMessage
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
      ),
    ),
  ),
)
```

## Accessibility Considerations

- ✅ All text colors meet WCAG AA contrast ratio (4.5:1 for normal text)
- ✅ Interactive elements are at least 48x48 dp (Material 3 standard)
- ✅ Color is not the only indicator (icons + text for status)
- ✅ Dark mode provides sufficient contrast
- ✅ Font sizes respect system settings

## Troubleshooting

### Theme not updating after user login?

Make sure `AuthProvider` is being listened to in the main app. The theme automatically updates when the user role changes.

### Custom color not visible?

Check that you're using `Theme.of(context).colorScheme.[property]` instead of hardcoded colors.

### Text too small/large?

Use the predefined text styles from `Theme.of(context).textTheme` instead of defining custom `TextStyle`s.

### Button styling not working?

Ensure buttons are using theme-defined styles. Custom styling might override theme defaults.

## Best Practices

1. **Always use `Theme.of(context)`** for accessing colors and text styles
2. **Use semantic colors** for status indication (success, danger, warning, info)
3. **Leverage design tokens** for spacing and radius consistency
4. **Avoid hardcoded colors** - let the theme handle styling
5. **Test both light and dark modes** during development
6. **Use predefined text styles** for consistency
7. **Keep custom styling minimal** - use theme where possible
8. **Document any custom extensions** to the theme

## Summary

Your app now has a **professional, consistent, and maintainable theme system** that:

- Applies the same design language across all screens
- Automatically adapts to user role (doctor vs student)
- Supports light and dark modes
- Uses industry-standard typography and colors
- Is easy to maintain and extend
- Follows Material 3 design principles

All screens are now using the unified theme system, ensuring a cohesive user experience for both doctors and students!
