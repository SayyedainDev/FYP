const fs = require('fs');

let ragFile = fs.readFileSync('lib/service/rag_service.dart', 'utf8');

// Remove polling/waiting in _waitForDocumentReady
ragFile = ragFile.replace(/static Future<void> _waitForDocumentReady\([^}]*\n    debugPrintSynchronously\('\u26a0\ufe0f Proceeding with generation despite unknown status\.\.\.'\);\n  \}/s, `static Future<void> _waitForDocumentReady(String documentId) async {
    // The backend now handles indexing waits internally or fast enough.
    // Proceed immediately to generation endpoint! No artificial delays.
    debugPrintSynchronously('✅ Sending generate request immediately after upload.');
  }`);

// Just to be sure, maybe there's another _waitForDocumentReady if I didn't replace the whole thing properly.
// Let's replace the body of the function directly.
let waitForDocsStart = ragFile.indexOf('static Future<void> _waitForDocumentReady');
if (waitForDocsStart !== -1) {
  let endToken = 'Proceeding with generation despite unknown status...\');\n  }';
  let waitForDocsEnd = ragFile.indexOf(endToken, waitForDocsStart);
  if (waitForDocsEnd !== -1) {
    let toReplace = ragFile.substring(waitForDocsStart, waitForDocsEnd + endToken.length);
    let replacement = `static Future<void> _waitForDocumentReady(String documentId) async {
    // The backend now handles indexing waits handling internally.
    debugPrintSynchronously('⏩ Proceeding to quiz generation without delays...');
  }`;
    ragFile = ragFile.replace(toReplace, replacement);
  }
}

fs.writeFileSync('lib/service/rag_service.dart', ragFile, 'utf8');
console.log("Patched rag_service.dart");

let aiScreen = fs.readFileSync('lib/view/ai_quiz_screen.dart', 'utf8');

let sizeCheckStr = `final validationError = FileParserService.getValidationError(`;
let newCheck = `if (fileName.toLowerCase().endsWith(".pdf") && fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('⚠️ PDF is larger than 5MB. Only the first 50 pages will be processed.'),
                backgroundColor: _sem?.warning ?? Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }

        final validationError = FileParserService.getValidationError(`;

aiScreen = aiScreen.replace(sizeCheckStr, newCheck);

fs.writeFileSync('lib/view/ai_quiz_screen.dart', aiScreen, 'utf8');
console.log("Patched ai_quiz_screen.dart");

