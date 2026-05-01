const fs = require('fs');

let code = fs.readFileSync('dental_care/lib/providers/quiz_provider.dart', 'utf-8');

// Connect the onProgress hook to the UI's progress variable
const originalCallBytes = `        if (_uploadedBytes != null && _uploadedFileName != null) {
          debugPrint('Uploading PDF bytes to RAG backend...');
          documentId = await _runAiRequestWithRetry(
            () => _withAiTimeout(
              RagService.uploadPdfBytes(_uploadedBytes!, _uploadedFileName!),
            ),
          );
        } else if (_uploadedFile != null) {
          debugPrint('Uploading PDF file to RAG backend...');
          documentId = await _runAiRequestWithRetry(
            () => _withAiTimeout(RagService.uploadPdfFile(_uploadedFile!)),
          );
        }`;

const replacementCallBytes = `        if (_uploadedBytes != null && _uploadedFileName != null) {
          debugPrint('Uploading PDF bytes to RAG backend...');
          documentId = await _runAiRequestWithRetry(
            () => _withAiTimeout(
              RagService.uploadPdfBytes(
                _uploadedBytes!, 
                _uploadedFileName!,
                onProgress: (p) {
                   _uploadProgress = p;
                   notifyListeners();
                }
              ),
            ),
          );
        } else if (_uploadedFile != null) {
          debugPrint('Uploading PDF file to RAG backend...');
          documentId = await _runAiRequestWithRetry(
            () => _withAiTimeout(
              RagService.uploadPdfFile(
                _uploadedFile!,
                onProgress: (p) {
                   _uploadProgress = p;
                   notifyListeners();
                }
              )
            ),
          );
        }`;

code = code.replace(originalCallBytes, replacementCallBytes);

fs.writeFileSync('dental_care/lib/providers/quiz_provider.dart', code, 'utf-8');
console.log('Quiz provider updated');
