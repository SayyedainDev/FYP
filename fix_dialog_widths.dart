import 'dart:io';

void main() {
  final dir = Directory('lib/view');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (var file in files) {
    var content = file.readAsStringSync();
    bool modified = false;

    // Look for Container( width: 650, ... and replace with ConstrainedBox
    var newContent = content.replaceAllMapped(
      RegExp(r'Dialog\([\s]*shape:\s*([^\n]+),\s*(elevation:\s*\d+,\s*)?child:\s*Container\([\s]*width:\s*(\d+),[\s]*(constraints:\s*const\s*BoxConstraints\([^\)]+\),\s*)?'),
      (match) {
        modified = true;
        String shape = match.group(1)!;
        String elevation = match.group(2) ?? '';
        String width = match.group(3)!;
        return 'Dialog(\n      shape: $shape,\n      $elevation'
               'child: ConstrainedBox(\n        constraints: BoxConstraints(\n          maxWidth: $width,\n          maxHeight: MediaQuery.of(context).size.height * 0.85,\n        ),\n        child: Container(';
      }
    );

    // Some dialogs might not have shape
    newContent = newContent.replaceAllMapped(
      RegExp(r'Dialog\([\s]*child:\s*Container\([\s]*width:\s*(\d+),[\s]*(constraints:\s*const\s*BoxConstraints\([^\)]+\),\s*)?'),
      (match) {
        modified = true;
        String width = match.group(1)!;
        return 'Dialog(\n      child: ConstrainedBox(\n        constraints: BoxConstraints(\n          maxWidth: $width,\n          maxHeight: MediaQuery.of(context).size.height * 0.85,\n        ),\n        child: Container(';
      }
    );

    if (modified) {
      // Check for SingleChildScrollView. Wrap the child of the Container if it is Column or Form.
      // Let's do this carefully.
      file.writeAsStringSync(newContent);
      print('Fixed width in \${file.path}');
    }
  }
}
