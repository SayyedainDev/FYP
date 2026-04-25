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

            // These were breaking things because they replaced Colors.grey.shade100 to Theme.of(context).disabledColor.shade100, which doesn't exist
            // Let's do a regex replacement back to some safe things
            
            // Undo Colors.red
            if (content.includes('Theme.of(context).colorScheme.errorAccent')) {
                content = content.replace(/Theme\.of\(context\)\.colorScheme\.errorAccent/g, 'Colors.redAccent');
                modified = true;
            }

            // The issue is Colors.grey[number] or Colors.grey.shadeN got replaced with Theme.of(context).disabledColor.shadeN
            // Actually fix_ui.js did: content = content.replace(/Colors\.grey(\[\d+\])?/g, 'Theme.of(context).disabledColor');
            // So Colors.grey.shade600 became Theme.of(context).disabledColor.shade600
            // disabledColor is a Color, not a MaterialColor. Color doesn't have .shade600 or [300].

            // Fix shades
            content = content.replace(/Theme\.of\(context\)\.disabledColor\.shade(\d+)/g, 'Colors.grey.shade$1');
            content = content.replace(/Theme\.of\(context\)\.disabledColor\[(\d+)\]/g, 'Colors.grey[$1]');
            content = content.replace(/const Theme\.of\(context\)\.disabledColor/g, 'Colors.grey');
            content = content.replace(/const Theme\.of\(context\)\.colorScheme\.error/g, 'Colors.red');
            
            // Fix loading in AuthProvider
            // Some places tried to use authProvider.loading. The getter is isLoading.
            content = content.replace(/\.loading\b/g, '.isLoading');

            if (content !== fs.readFileSync(fullPath, 'utf8')) {
                fs.writeFileSync(fullPath, content);
                console.log('Fixed ' + fullPath);
            }
        }
    }
}

processDir('/home/bao/Videos/QUiz Dental FYP/dental_care/lib/view');
