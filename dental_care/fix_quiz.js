const fs = require('fs');

function findClosingParen(str, startPos) {
  let count = 0;
  for (let i = startPos; i < str.length; i++) {
    if (str[i] === '(') count++;
    else if (str[i] === ')') {
      count--;
      if (count === 0) return i;
    }
  }
  return -1;
}

function processFile(file) {
  let content = fs.readFileSync(file, 'utf-8');

  if (!content.includes("import '../widgets/loading_button.dart';")) {
    content = content.replace(
      /(import 'package:flutter\/material\.dart';)/,
      "$1\nimport '../widgets/loading_button.dart';\nimport '../../providers/loading_provider.dart';\nimport 'package:provider/provider.dart';"
    );
  }

  const btnRegex = /(ElevatedButton|TextButton|OutlinedButton|IconButton)(?:\.icon)?\s*\(/g;
  let match;
  let matches = [];

  while ((match = btnRegex.exec(content)) !== null) {
      if (content.substring(match.index - 20, match.index).includes('child: LoadingButton')) continue; // already wrapped
      matches.push({ type: match[1], start: match.index, pStart: match.index + match[0].length - 1 });
  }

  matches.reverse();

  let wrapped = 0;
  for (let m of matches) {
    let pEnd = findClosingParen(content, m.pStart);
    if (pEnd === -1) continue;

    let pre = content.substring(0, m.start);
    let btnContent = content.substring(m.start, pEnd + 1);
    let post = content.substring(pEnd + 1);
    
    // Convert onPressed logic cleanly into Dart syntax
    let onPressedRegex = /(onPressed\s*:\s*)(\((?:[^)]*)\)\s*(?:async)?\s*(?:=>|\{))/;
    
    if (onPressedRegex.test(btnContent)) {
       btnContent = btnContent.replace(onPressedRegex, (m2, key, val) => {
         // Wrap the original closure explicitly inside runAsyncAction
         // In Dart, you can instantly invoke a closure like: () async { await (() { original })(); }()
         // Or even simpler, if it takes 0 args, it matches the signature:
         return key + " loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async {  await (" + val + ")(); })";
       });
    }

    let indentMatch = pre.match(/(\s+)$/);
    let indent = indentMatch ? indentMatch[1].replace(/\n/g, '') : '';
    
    let wrappedBtn = `Consumer<LoadingProvider>(\n${indent}  builder: (context, loadingState, _) {\n${indent}    return LoadingButton(\n${indent}      isLoading: loadingState.isLoading,\n${indent}      child: ${btnContent},\n${indent}    );\n${indent}  },\n${indent})`;

    content = pre + wrappedBtn + post;
    wrapped++;
  }

  if (wrapped > 0) {
    fs.writeFileSync(file, content);
    console.log(`Wrapped ${wrapped} buttons in ${file}`);
  }
}

const files = [
  'dental_care/lib/view/ai_quiz_screen.dart',
  'dental_care/lib/view/create_case_screen.dart'
];

for (let file of files) {
  if (fs.existsSync(file)) {
      processFile(file);
  }
}
