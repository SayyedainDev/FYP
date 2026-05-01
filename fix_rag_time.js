const fs = require('fs');

let code = fs.readFileSync('dental_care/lib/service/rag_service.dart', 'utf-8');

// 1 & 2. Fix timeouts
code = code.replace(
  "static const Duration _uploadTimeout = Duration(minutes: 3);",
  "static const Duration _uploadTimeout = Duration(seconds: 120);"
);

code = code.replace(
  "static const Duration _generationTimeout = Duration(minutes: 2);",
  "static const Duration _generationTimeout = Duration(seconds: 90);"
);

// 3. Add stream capability for progress and retry
// Since it's complex to regex rewrite the entire upload function cleanly, we'll replace uploadPdfBytes and uploadPdfFile

const originalBytes = `  static Future<String> uploadPdfBytes(Uint8List bytes, String filename) async {
    try {
      debugPrintSynchronously(
          '📤 Uploading PDF bytes ($filename, \${bytes.length} bytes)...');
      final uri = Uri.parse('$baseUrl/api/upload-pdf');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename));

      debugPrintSynchronously('⏳ Waiting for upload response...');
      final response = await request.send().timeout(_uploadTimeout);
      final responseData =
          await response.stream.bytesToString().timeout(_uploadTimeout);

      debugPrintSynchronously(
          '📡 Upload response status: \${response.statusCode}');
      debugPrintSynchronously('📋 Full upload response: $responseData');

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData) as Map<String, dynamic>;
        debugPrintSynchronously('🔍 Response JSON keys: \${json.keys.toList()}');
        final docId = json['documentId']?.toString() ?? '';
        debugPrintSynchronously('✅ PDF uploaded successfully (DocID: $docId)');
        if (docId.isEmpty) {
          debugPrintSynchronously(
              '⚠️ WARNING: documentId is empty in response!');
        }
        return docId;
      }

      debugPrintSynchronously('❌ Upload failed. Response: $responseData');

      // Try to extract error from backend
      String errorMsg = 'Failed to process PDF. Please try again.';
      try {
        final errorData = jsonDecode(responseData) as Map<String, dynamic>;
        errorMsg = errorData['error'] ?? errorData['message'] ?? errorMsg;
      } catch (_) {
        errorMsg =
            'Backend error (\${response.statusCode}): \${responseData.isEmpty ? 'No details' : responseData.substring(0, 100)}';
      }

      throw GroqException(errorMsg, statusCode: response.statusCode);
    } on TimeoutException {
      throw GroqException(
          'PDF upload timed out. The file may be too large or your connection is slow.');
    } catch (e) {
      if (e is GroqException) rethrow;
      throw GroqException('Failed to upload PDF: \${e.toString()}');
    }
  }`;

const replacementBytes = `  static Future<String> uploadPdfBytes(
      Uint8List bytes, String filename, {void Function(double)? onProgress}) async {
    // PDF Size validation (4)
    if (bytes.length > 10 * 1024 * 1024) {
      throw GroqException(
          'File too large. Please upload a PDF under 10MB.');
    } else if (bytes.length > 2 * 1024 * 1024) {
      debugPrintSynchronously('Large file detected, compressing... (Warning only)');
    }

    Future<String> attemptUpload() async {
      debugPrintSynchronously(
          '📤 Uploading PDF bytes ($filename, \${bytes.length} bytes)...');
      final uri = Uri.parse('$baseUrl/api/upload-pdf');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename));

      // Progress Tracker
      final http.StreamedResponse response = await request.send().timeout(_uploadTimeout);
      int total = response.contentLength ?? 0;
      int bytesReceived = 0;
      List<int> responseBytes = [];
      
      await for (final chunk in response.stream.timeout(_uploadTimeout)) {
          responseBytes.addAll(chunk);
          if (total > 0 && onProgress != null) {
              bytesReceived += chunk.length;
              onProgress(bytesReceived / total);
          }
      }
      
      final responseData = utf8.decode(responseBytes);

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData) as Map<String, dynamic>;
        final docId = json['documentId']?.toString() ?? '';
        debugPrintSynchronously('✅ PDF uploaded successfully (DocID: $docId)');
        return docId;
      }

      String errorMsg = 'Failed to process PDF. Please try again.';
      try {
        final errorData = jsonDecode(responseData) as Map<String, dynamic>;
        errorMsg = errorData['error'] ?? errorData['message'] ?? errorMsg;
      } catch (_) {
        errorMsg = 'Backend error (\${response.statusCode})';
      }
      throw GroqException(errorMsg, statusCode: response.statusCode);
    }

    try {
      return await attemptUpload();
    } on TimeoutException {
      debugPrintSynchronously('⏱️ Upload timed out. Retrying once...');
      try {
         return await attemptUpload();
      } catch (e) {
         throw GroqException('Upload is taking too long. Check your internet or try a smaller PDF.');
      }
    } catch (e) {
      if (e is GroqException) rethrow;
      throw GroqException('Server error. Please try again.');
    }
  }`;

code = code.replace(originalBytes, replacementBytes);

const originalFile = `  static Future<String> uploadPdfFile(File file) async {
    try {
      debugPrintSynchronously('📤 Uploading PDF file (\${file.path})...');
      final fileSize = await file.length();
      debugPrintSynchronously('📏 File size: $fileSize bytes');

      final uri = Uri.parse('$baseUrl/api/upload-pdf');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      debugPrintSynchronously('⏳ Waiting for upload response...');
      final response = await request.send().timeout(_uploadTimeout);
      final responseData =
          await response.stream.bytesToString().timeout(_uploadTimeout);

      debugPrintSynchronously(
          '📡 Upload response status: \${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(responseData) as Map<String, dynamic>;
        final docId = json['documentId']?.toString() ?? '';
        debugPrintSynchronously('✅ PDF uploaded successfully (DocID: $docId)');
        return docId;
      }

      debugPrintSynchronously('❌ Upload failed. Response: $responseData');

      String errorMsg = 'Failed to process PDF. Please try again.';
      try {
        final errorData = jsonDecode(responseData) as Map<String, dynamic>;
        errorMsg = errorData['error'] ?? errorData['message'] ?? errorMsg;
      } catch (_) {
        errorMsg =
            'Backend error (\${response.statusCode}): \${responseData.isEmpty ? 'No details' : responseData.substring(0, 100)}';
      }

      throw GroqException(errorMsg, statusCode: response.statusCode);
    } on TimeoutException {
      throw GroqException(
          'PDF upload timed out. The file may be too large or your connection is slow.');
    } catch (e) {
      if (e is GroqException) rethrow;
      throw GroqException('Failed to upload PDF: \${e.toString()}');
    }
  }`;

const replacementFile = `  static Future<String> uploadPdfFile(File file, {void Function(double)? onProgress}) async {
    Future<String> attemptUpload() async {
       final fileSize = await file.length();
       // PDF Size validation (4)
       if (fileSize > 10 * 1024 * 1024) {
         throw GroqException(
             'File too large. Please upload a PDF under 10MB.');
       } else if (fileSize > 2 * 1024 * 1024) {
         debugPrintSynchronously('Large file detected, compressing... (Warning only)');
       }
 
       debugPrintSynchronously('📤 Uploading PDF file (\${file.path})...');
       final uri = Uri.parse('$baseUrl/api/upload-pdf');
       final request = http.MultipartRequest('POST', uri)
         ..files.add(await http.MultipartFile.fromPath('file', file.path));
 
       final response = await request.send().timeout(_uploadTimeout);
       
       int total = response.contentLength ?? 0;
       int bytesReceived = 0;
       List<int> responseBytes = [];
       await for (final chunk in response.stream.timeout(_uploadTimeout)) {
           responseBytes.addAll(chunk);
           if (total > 0 && onProgress != null) {
               bytesReceived += chunk.length;
               onProgress(bytesReceived / total);
           }
       }
       
       final responseData = utf8.decode(responseBytes);
 
       if (response.statusCode == 200) {
         final json = jsonDecode(responseData) as Map<String, dynamic>;
         final docId = json['documentId']?.toString() ?? '';
         return docId;
       }
 
       String errorMsg = 'Failed to process PDF. Please try again.';
       try {
         final errorData = jsonDecode(responseData) as Map<String, dynamic>;
         errorMsg = errorData['error'] ?? errorData['message'] ?? errorMsg;
       } catch (_) {
         errorMsg = 'Backend error (\${response.statusCode})';
       }
       throw GroqException(errorMsg, statusCode: response.statusCode);
    }
    
    try {
      return await attemptUpload();
    } on TimeoutException {
      try { return await attemptUpload(); } catch(e) {
          throw GroqException('Upload is taking too long. Check your internet or try a smaller PDF.');
      }
    } catch (e) {
      if (e is GroqException) rethrow;
      throw GroqException('Server error. Please try again.');
    }
  }`;

code = code.replace(originalFile, replacementFile);


code = code.replace(
    `      } catch (_) {
        // If parsing fails, use generic message with status code
        errorMessage =
            'Backend error (\${response.statusCode}): \${response.body.isNotEmpty ? response.body.substring(0, 100) : "No details"}';
      }
      throw GroqException(
        errorMessage,
        statusCode: response.statusCode,
      );
    }`,
    `      } catch (_) {
        errorMessage = 'Server error. Please try again.';
      }
      throw GroqException(errorMessage, statusCode: response.statusCode);
    }`
);

code = code.replace(
      `      throw GroqException(
        'Quiz generation timed out. The backend took too long to process your PDF. Try with a smaller file or fewer questions.',
      );`,
      `      throw GroqException('Upload is taking too long. Check your internet or try a smaller PDF.');`
);

code = code.replace(
    `throw GroqException('Failed to generate quiz: \${e.toString()}');`,
    `throw GroqException('Quiz generation failed. Please try again.');`
);

fs.writeFileSync('dental_care/lib/service/rag_service.dart', code, 'utf-8');
console.log('Dart file replaced updates');
