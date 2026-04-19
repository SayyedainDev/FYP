    text = text.replace(/\r\n/g, '\n').replace(/\n\s*\d+\s*\n/g, '\n').replace(/\f/g, '');

    // Chunking parameters based on requirements:
    const chunkSize = 800;
    const Math = global.Math; // Ensure Math is available
    const chunks = [];

    // Split into paragraphs first, then chunk if too big, or group if too small
    const paragraphs = text.split(/\n\s*\n/);
    let currentChunk = '';

    for (const p of paragraphs) {
      const cleanP = p.trim();
      if (!cleanP) continue;

      if (currentChunk.length + cleanP.length > chunkSize) {
        if (currentChunk) {
          chunks.push(currentChunk.trim());
          // Create overlap dynamically by keeping the last 100-200 chars of the previous chunk
          const words = currentChunk.split(' ');
          const overlapWords = words.slice(-25).join(' '); // roughly 100-150 chars overlap
          currentChunk = overlapWords + ' ' + cleanP + ' ';
        } else {
          chunks.push(cleanP.substring(0, chunkSize));
          currentChunk = cleanP.substring(chunkSize);
        }
      } else {
        currentChunk += cleanP + '\n\n';
      }
    }
    if (currentChunk.trim()) {
      chunks.push(currentChunk.trim());
    }

    const documentId = req.body.documentId || `doc_${Date.now()}`;
