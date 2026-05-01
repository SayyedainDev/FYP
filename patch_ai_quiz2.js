const fs = require('fs');

function findClosingBracket(str, startPos, openChar, closeChar) {
  let count = 0;
  for (let i = startPos; i < str.length; i++) {
    if (str[i] === openChar) count++;
    else if (str[i] === closeChar) {
      count--;
      if (count === 0) return i;
    }
  }
  return -1;
}

function processFile(file) {
  let content = fs.readFileSync(file, 'utf-8');

  // Add imports
  if (!content.includes("import '../widgets/loading_button.dart';")) {
    content = content.replace(
      /(import 'package:flutter\/material\.dart';)/,
      "$1\nimport '../widgets/loading_button.dart';\nimport '../../providers/loading_provider.dart';\nimport 'package:provider/provider.dart';"
    );
  }

  const btnPatterns = ["ElevatedButton", "TextButton", "OutlinedButton", "IconButton"];
  
  let wrappedCnt = 0;
  
  // To avoid endless loops and concurrent modification issues, we process completely bottom to top
  // First, find all Button instantiations
  let matches = [];
  const btnRegex = /(ElevatedButton|TextButton|OutlinedButton|IconButton)(?:\.icon)?\s*\(/g;
  let m;
  while ((m = btnRegex.exec(content)) !== null) {
      // check if wrapped
      let pre = content.substring(Math.max(0, m.index - 30), m.index);
      if (pre.includes('LoadingButton')) continue;
      matches.push({ type: m[1], start: m.index, pStart: m.index + m[0].length - 1 });
  }
  
  matches.reverse();

  for (let match of matches) {
      let endParen = findClosingBracket(content, match.pStart, '(', ')');
      if (endParen === -1) continue;
      
      let btnBlock = content.substring(match.start, endParen + 1);

      // Now within this btnBlock, find the top-level onPressed:
      let onPressedRegex = /(onPressed\s*:\s*)(.*)/;
      let opMatch = onPressedRegex.exec(btnBlock);
      
      if (opMatch) {
         let opStart = opMatch.index + opMatch[1].length;
         
         // extract the value of onPressed
         let opVal = "";
         let opEndIndex = -1;
         
         // The value could be bounded by a comma, but it could contain nested closures.
         // Let's parse character by character to find the comma at depth 0, 
         // or the end of the widget parameters (i.e. we hit a closing bracket/paren of the button).
         let depth = 0;
         for (let i = opStart; i < btnBlock.length; i++) {
             let c = btnBlock[i];
             if (c === '(' || c === '[' || c === '{') depth++;
             else if (c === ')' || c === ']' || c === '}') depth--;
             
             if (depth === 0 && c === ',') {
                 opEndIndex = i;
                 break;
             }
             if (depth < 0) { // e.g. closing parens of the button itself
                 opEndIndex = i;
                 break;
             }
         }
         
         if (opEndIndex !== -1) {
             let originalOp = btnBlock.substring(opStart, opEndIndex).trim();
             
             // If disabled btn: onPressed: null
             if (originalOp !== 'null') {
                // If it's a function pointer like: _submit or () => ...
                // we simply wrap it:
                let newOp = `loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async {
                                 var _res = ${originalOp};
                                 if (_res is Function) { await _res(); } else {
                                   try { await (_res as dynamic)(); } catch(e) {}
                                 }
                             })`;
                
                // Let's just create a very robust dart wrapper.
                // Actually await (_res as dynamic)() doesn't work if it's evaluated immediately e.g. `onPressed: () { ... }` 
                // In dart, if `originalOp` is `() { doSomething(); }`
                // `await (() { doSomething(); })();` is perfectly valid Dart!
                
                let safeOp = `loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { await (${originalOp})(); })`;
                
                btnBlock = btnBlock.substring(0, opMatch.index) + 
                           opMatch[1] + safeOp + 
                           btnBlock.substring(opEndIndex);
             }
         }
      }

      let preStr = content.substring(0, match.start);
      // find indentation
      const lastNewline = preStr.lastIndexOf('\n');
      const ind = lastNewline === -1 ? '' : preStr.substring(lastNewline + 1).match(/^\s*/)[0];
      
      let replacement = `Consumer<LoadingProvider>(
${ind}  builder: (context, loadingState, _) {
${ind}    return LoadingButton(
${ind}      isLoading: loadingState.isLoading,
${ind}      child: ${btnBlock},
${ind}    );
${ind}  },
${ind})`;

      content = preStr + replacement + content.substring(endParen + 1);
      wrappedCnt++;
  }
  
  if (wrappedCnt > 0) {
      fs.writeFileSync(file, content);
      console.log(`Processed ${wrappedCnt} buttons in ${file}`);
  }
}

// processFile('dental_care/lib/view/ai_quiz_screen.dart');
const glob = require('fs').readdirSync('dental_care/lib/view').filter(f => f.includes('quiz') || ['create_case_screen.dart'].includes(f));
for(let f of glob) {
    if (f.endsWith('.dart')) processFile('dental_care/lib/view/' + f);
}
