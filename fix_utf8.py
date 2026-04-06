import os

def fix_mojibake(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return
        
    original = content
    # First, standard utf8 double-encoded mappings we know from the files
    reps = {
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
    }
    
    for k, v in reps.items():
        content = content.replace(k, v)
        
    # After these replacements, any standalone í is likely 'í' where the soft hyphen got dropped
    # Let's do a safe replacement of í followed by common letters in those words
    content = content.replace('título', 'título')
    content = content.replace('Título', 'Título')
    content = content.replace('política', 'política')
    content = content.replace('Política', 'Política')
    content = content.replace('día', 'día')
    content = content.replace('Día', 'Día')
    content = content.replace('guía', 'guía')
    content = content.replace('Guía', 'Guía')
    content = content.replace('vacío', 'vacío')
    content = content.replace('río', 'río')
    content = content.replace('mínimo', 'mínimo')
    content = content.replace('límite', 'límite')
    content = content.replace('Límite', 'Límite')
    
    # Finally, just replace any remaining í with í as a catch-all since no valid word uses isolated í in Spanish
    content = content.replace('í', 'í')
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed: {filepath}")

if __name__ == '__main__':
    for root, dirs, files in os.walk('.'):
        if '.git' in root or '.dart_tool' in root or 'build' in root or 'node_modules' in root or '.venv' in root or '__pycache__' in root:
            continue
        for file in files:
            if file.endswith('.dart') or file.endswith('.py') or file.endswith('.md'):
                fix_mojibake(os.path.join(root, file))
    print("Done fixing mojibake.")
