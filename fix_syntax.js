const fs = require('fs');

function fix(filePath) {
  if (!fs.existsSync(filePath)) return;
  let content = fs.readFileSync(filePath, 'utf8');
  // Fix the backticks
  content = content.replace(/\\`🚀 Server is running on port \\\${PORT}\\`/g, '`🚀 Server is running on port ${PORT}`');
  // Fix the "What is on page X?" quotes
  content = content.replace(/'What is on page X\?' or 'What chapter is Y\?'/g, '"What is on page X?" or "What chapter is Y?"');

  fs.writeFileSync(filePath, content, 'utf8');
}

fix('/home/bao/Videos/QUiz Dental FYP/fy_dental_backend/server.js');
fix('/home/bao/Videos/QUiz Dental FYP/fy_dental_backend/server_new.js');
fix('/home/bao/Videos/QUiz Dental FYP/temp_server.js');
