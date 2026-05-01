const fs = require('fs');

let content = fs.readFileSync('dental_care/lib/service/rag_service.dart', 'utf-8');

const flutterWaitOriginal = `      // Wait for document to be ready (with retry logic)
      debugPrintSynchronously(
          '⏳ Waiting for document to be indexed ($documentId)...');
      await _waitForDocumentReady(documentId);

      debugPrintSynchronously(
          '🤖 Document ready. Generating quiz from $documentId...');`;

const flutterWaitNew = `      debugPrintSynchronously(
          '🤖 Requesting quiz generation from $documentId...');`;

content = content.replace(flutterWaitOriginal, flutterWaitNew);

fs.writeFileSync('dental_care/lib/service/rag_service.dart', content, 'utf-8');
console.log('Flutter edits applied successfully!');
