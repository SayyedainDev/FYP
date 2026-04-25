const fs = require('fs');
const path = require('path');

function processDir(dir) {
    const files = fs.readdirSync(dir);
    for (const file of files) {
        const fullPath = path.join(dir, file);
        if (fs.statSync(fullPath).isDirectory()) {
            processDir(fullPath);
        } else if (fullPath.endsWith('.dart') && !fullPath.includes('provider') && !fullPath.includes('model') && !fullPath.includes('service')) {
            let content = fs.readFileSync(fullPath, 'utf8');
            let modified = false;

            // Replace ElevatedButton with PrimaryButton if label/onPressed matches (very simplistic)
            if (content.includes('ElevatedButton(')) {
                // Actually, ElevatedButton API is often different from PrimaryButton (child vs label). Let's skip automatic replacement for widgets we don't know the full structure of.
            }

            // Colors.red -> Theme.of(context).colorScheme.error or something
            if (content.includes('Colors.red') && !fullPath.includes('app_theme.dart')) {
              content = content.replace(/Colors\.red/g, 'Theme.of(context).colorScheme.error');
              modified = true;
            }
            if (content.includes('Colors.grey') && !fullPath.includes('app_theme.dart')) {
              content = content.replace(/Colors\.grey(\[\d+\])?/g, 'Theme.of(context).disabledColor');
              modified = true;
            }

            if (modified) {
                fs.writeFileSync(fullPath, content);
                console.log('Modified ' + fullPath);
            }
        }
    }
}

processDir('/home/bao/Videos/QUiz Dental FYP/dental_care/lib/view');
