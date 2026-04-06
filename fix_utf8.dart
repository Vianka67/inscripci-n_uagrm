import 'dart:io';

void fixMojibake(File file) {
  try {
    final original = file.readAsStringSync();
    var content = original;
    
    final reps = {
      'á': 'á',
      'é': 'é',
      'í\xad': 'í',
      'ó': 'ó',
      'ú': 'ú',
      'ñ': 'ñ',
      'Ñ': 'Ñ',
      'Ó': 'Ó',
      'í\x81': 'Á',
      'í\x89': 'É',
      'í\x8d': 'Í',
      'í\x9a': 'Ú',
      '·': '·',
      '—': '—',
      '¡': '¡',
      '›': '›',
      '¿': '¿',
    };
    
    reps.forEach((k, v) {
      content = content.replaceAll(k, v);
    });
    
    content = content.replaceAll('título', 'título');
    content = content.replaceAll('Título', 'Título');
    content = content.replaceAll('política', 'política');
    content = content.replaceAll('Política', 'Política');
    content = content.replaceAll('día', 'día');
    content = content.replaceAll('Día', 'Día');
    content = content.replaceAll('guía', 'guía');
    content = content.replaceAll('Guía', 'Guía');
    content = content.replaceAll('vacío', 'vacío');
    content = content.replaceAll('río', 'río');
    content = content.replaceAll('mínimo', 'mínimo');
    content = content.replaceAll('límite', 'límite');
    content = content.replaceAll('Límite', 'Límite');
    
    content = content.replaceAll('í', 'í');
    
    if (content != original) {
      file.writeAsStringSync(content);
      print('Fixed: \${file.path}');
    }
  } catch (e) {
    // skip non-utf8 files
  }
}

void main() {
  final dir = Directory('.');
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File) {
      if (entity.path.contains('.git') || 
          entity.path.contains('.dart_tool') || 
          entity.path.contains('build') || 
          entity.path.contains('node_modules') || 
          entity.path.contains('.venv') || 
          entity.path.contains('__pycache__')) {
        continue;
      }
      
      if (entity.path.endsWith('.dart') || 
          entity.path.endsWith('.py') || 
          entity.path.endsWith('.md')) {
        fixMojibake(entity);
      }
    }
  }
  print('Done fixing mojibake.');
}
