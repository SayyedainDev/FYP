const fs = require('fs');
let file = fs.readFileSync('../fy_dental_backend/server.js', 'utf8');

// Fix duplicates
file = file.replace(/await db\.collection\('knowledge_docs'\)\.doc\(documentId\)\.set\(\{ chunksCount: chunks\.length, status: 'indexing' \}\);\s*await db\.collection\('knowledge_docs'\)\.doc\(documentId\)\.set\(\{ chunksCount: chunks\.length, status: 'indexing' \}\);/g, "await db.collection('knowledge_docs').doc(documentId).set({ chunksCount: chunks.length, status: 'indexing' });");

file = file.replace(/await db\.collection\('knowledge_docs'\)\.doc\(documentId\)\.update\(\{ status: 'ready' \}\);\s*await db\.collection\('knowledge_docs'\)\.doc\(documentId\)\.update\(\{ status: 'ready' \}\);/g, "await db.collection('knowledge_docs').doc(documentId).update({ status: 'ready' });");

fs.writeFileSync('../fy_dental_backend/server.js', file, 'utf8');
