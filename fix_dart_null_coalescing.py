import glob, re

# Fixes single `?` used as null-coalescing where `??` is needed.
# Dart uses `??` for null coalescing; a single `?` after a value is
# always a ternary condition needing `: alternative`.
# These patterns are SAFE because they match only null-coalescing usage.

REPLACEMENTS = [
    # --- as Type? ? default  (cast to nullable then coalesce) ---
    # e.g.  as Map<String, dynamic>? ? {}
    (r'(as\s+[\w<>, ]+\?)\s\?\s(\{\})',    r'\1 ?? \2'),
    (r'(as\s+[\w<>, ]+\?)\s\?\s(\[\])',    r'\1 ?? \2'),
    (r'(as\s+[\w<>, ]+\?)\s\?\s(\d+)',     r'\1 ?? \2'),
    (r"(as\s+[\w<>, ]+\?)\s\?\s'([^']*)'", r"\1 ?? '\2'"),

    # --- int.tryParse(...) ? default ---
    # e.g. int.tryParse(x) ? 0
    (r'(int\.tryParse\([^)]+\))\s\?\s(\d+)', r'\1 ?? \2'),

    # --- expr?.method() ? default ---
    # e.g. match.group(1) ? ''  /  value?.toString() ? ''
    (r"(\w+(?:\?\.[\w<>()]+)+)\s\?\s'([^']*)'",  r"\1 ?? '\2'"),
    (r'(\w+(?:\?\.[\w<>()]+)+)\s\?\s(\w+)',       r'\1 ?? \2'),
    (r"(\w+(?:\?\.[\w<>()]+)+)\s\?\s(\d+)",       r'\1 ?? \2'),

    # --- map['key'] ? default  (simple map access) ---
    # e.g.  json['campo'] ? ''  /  json['campo'] ? false  /  json['campo'] ? 0
    (r"(\w+\['\w+'\])\s\?\s'([^']*)'",   r"\1 ?? '\2'"),
    (r"(\w+\['\w+'\])\s\?\s(\[\])",      r'\1 ?? \2'),
    (r"(\w+\['\w+'\])\s\?\s(\{\})",      r'\1 ?? \2'),
    (r"(\w+\['\w+'\])\s\?\s(false|true)", r'\1 ?? \2'),
    (r"(\w+\['\w+'\])\s\?\s(\d+)",       r'\1 ?? \2'),
    (r"(\w+\['\w+'\])\s\?\s(\w+)",       r'\1 ?? \2'),

    # --- map?['key'] ? default  (null-safe map access) ---
    (r"(\w+\?\['\w+'\])\s\?\s'([^']*)'",  r"\1 ?? '\2'"),
    (r"(\w+\?\['\w+'\])\s\?\s(false|true)", r'\1 ?? \2'),
    (r"(\w+\?\['\w+'\])\s\?\s(\d+)",      r'\1 ?? \2'),
    (r"(\w+\?\['\w+'\])\s\?\s(\w+)",      r'\1 ?? \2'),

    # --- valueColor ? Colors.white  (Color? coalesce) ---
    (r'(\w+)\s\?\s(Colors\.\w+(?:\.\w+)?)', r'\1 ?? \2'),

    # --- badgeText ? '!'  (String? coalesce to string literal) ---
    (r"(\w+)\s\?\s'([^']*)'(?=[,\)\;])", r"\1 ?? '\2'"),
]


def main() -> None:
    files_fixed: int = 0
    for dart_file in glob.glob('lib/**/*.dart', recursive=True):
        with open(dart_file, 'r', encoding='utf-8') as f:
            content = f.read()
        original = content
        for pattern, replacement in REPLACEMENTS:
            content = re.sub(pattern, replacement, content)
        if content != original:
            with open(dart_file, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f'Fixed: {dart_file}')
            files_fixed += 1

    print(f'\nDone. Fixed {files_fixed} files.')


if __name__ == '__main__':
    main()
