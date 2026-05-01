const fs = require('fs');

function addHealth(filePath) {
  if (!fs.existsSync(filePath)) return;
  let content = fs.readFileSync(filePath, 'utf8');
  if (!content.includes('/health')) {
    content = content.replace(/app\.use\(cors\([^\)]*\)\);|app\.use\(cors\(\)\);/, (match) => {
      return match + '\n\n// Health Check Endpoint for Keep-Alive\napp.get("/health", (req, res) => res.status(200).json({ status: "ok" }));\n';
    });
    fs.writeFileSync(filePath, content, 'utf8');
  }
}

addHealth('/home/bao/Videos/QUiz Dental FYP/fy_dental_backend/server_new.js');
addHealth('/home/bao/Videos/QUiz Dental FYP/fy_dental_backend/server.js');
addHealth('/home/bao/Videos/QUiz Dental FYP/temp_server.js');
