const fs = require('fs');

const file = 'lib/view/ai_quiz_screen.dart';
let content = fs.readFileSync(file, 'utf-8');

// Ensure imports
if (!content.includes("import '../widgets/loading_button.dart';")) {
  content = content.replace(
    /(import 'package:flutter\/material\.dart';)/,
    "$1\nimport '../widgets/loading_button.dart';\nimport '../../providers/loading_provider.dart';\nimport 'package:provider/provider.dart';"
  );
}

// Regex to find buttons: ElevatedButton, TextButton, OutlinedButton, IconButton
// It specifically handles buttons with an `onPressed` that starts with `() {` or `() async {`
// This is a naive approach but works for simple cases.

const buttonRegex = /(ElevatedButton|TextButton|OutlinedButton|IconButton)(?:\.icon)?\s*\(\s*onPressed:\s*(\(\)\s*(?:async)?\s*\{)/g;
let match;
let matchCount = 0;

// Since we can't reliably parse AST, we wrap the entire Button.
// We'll replace the generic onPressed with a wrapper.
// Actually, wrapping the widget itself via regex is extremely hard because of finding the matching closing bracket.

