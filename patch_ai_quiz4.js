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

  // Add imports safely
  if (!content.includes("import '../widgets/loading_button.dart';")) {
     content = `import '../widgets/loading_button.dart';\nimport '../../providers/loading_provider.dart';\nimport 'package:provider/provider.dart';\n` + content;
  }

  const btnPatterns = ["ElevatedButton", "TextButton", "OutlinedButton", "IconButton"];
  
  let wrappedCnt = 0;
  
  // bottom up
  let matches = [];
  const btnRegex = /(ElevatedButton|TextButton|OutlinedButton|IconButton)(?:\.icon)?\s*\(/g;
  let m;
  while ((m = btnRegex.exec(content)) !== null) {
      let pre = content.substring(Math.max(0, m.index - 40), m.index);
      if (pre.includes('LoadingButton')) continue; // skip already wrapped
      matches.push({ type: m[1], start: m.index, pStart: m.index + m[0].length - 1 });
  }
  matches.reverse();

  for (let match of matches) {
      let endParen = findClosingBracket(content, match.pStart, '(', ')');
      if (endParen === -1) continue;
      
      let btnBlock = content.substring(match.start, endParen + 1);

      let onPressedRegex = /(onPressed\s*:\s*)(.*)/;
      let opMatch = onPressedRegex.exec(btnBlock);
      
      if (opMatch) {
         let opStart = opMatch.index + opMatch[1].length;
         
         let opEndIndex = -1;
         let depth = 0;
         for (let i = opStart; i < btnBlock.length; i++) {
             let c = btnBlock[i];
             if (c === '(' || c === '[' || c === '{') depth++;
             else if (c === ')' || c === ']' || c === '}') depth--;
             
             if (depth === 0 && c === ',') { opEndIndex = i; break; }
             if (depth < 0) { opEndIndex = i; break; }
         }
         
         if (opEndIndex !== -1) {
             let originalOp = btnBlock.substring(opStart, opEndIndex).trim();
             
             if (originalOp !== 'null') {
                let safeOp = `loadingState.isLoading ? null : () => loadingState.runAsyncAction(() async { final _op = ${originalOp}; if (_op != null) await Future.sync(() => (_op as dynamic)()); })`;
                
                btnBlock = btnBlock.substring(0, opMatch.index) + 
                           opMatch[1] + safeOp + 
                           btnBlock.substring(opEndIndex);
             }
         }
      }

      let preStr = content.substring(0, match.start);
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

// reset and apply
const glob = require('fs').readdirSync('dental_care/lib/view').filter(f => f.includes('quiz') || ['create_case_screen.dart'].includes(f));
for(let f of glob) {
    if (f.endsWith('.dart')) {
       // execute shell to check out
       require('child_process').execSync('git checkout dental_care/lib/view/' + f);
       processFile('dental_care/lib/view/' + f);
    }
}
