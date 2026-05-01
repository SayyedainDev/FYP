const fs = require('fs');

function preload(filePath) {
  if (!fs.existsSync(filePath)) return;
  let content = fs.readFileSync(filePath, 'utf8');
  if (!content.includes('getExtractor().then')) {
    content = content.replace(/const app = express\(\);/, (match) => {
      return match + '\n\n// Pre-load embedding model to avoid cold-start penalty on first request\ngetExtractor().then(() => console.log("Embedding model pre-loaded")).catch(console.error);\n';
    });
    fs.writeFileSync(filePath, content, 'utf8');
  }
}

preload('/home/bao/Videos/QUiz Dental FYP/fy_dental_backend/server_new.js');
preload('/home/bao/Videos/QUiz Dental FYP/fy_dental_backend/server.js');
preload('/home/bao/Videos/QUiz Dental FYP/temp_server.js');
