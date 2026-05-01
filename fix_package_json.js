const fs = require('fs');

function fix(filePath) {
  if (!fs.existsSync(filePath)) return;
  let pkg = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  pkg.scripts = pkg.scripts || {};
  pkg.scripts.start = "node server.js";
  fs.writeFileSync(filePath, JSON.stringify(pkg, null, 2), 'utf8');
}

fix('/home/bao/Videos/QUiz Dental FYP/fy_dental_backend/package.json');
