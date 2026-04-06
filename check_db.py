import sqlite3, os

dbs = [
    'inscripcion_backend/db.sqlite3',
    'inscripcion_backend/config/db.sqlite3'
]

for db_path in dbs:
    size = os.path.getsize(db_path)
    print(f'\n=== {db_path} ({size} bytes) ===')
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
        tables = cursor.fetchall()
        print('Tablas:', [t[0] for t in tables])
        for table in tables:
            cursor.execute(f'SELECT COUNT(*) FROM "{table[0]}"')
            count = cursor.fetchone()[0]
            if count > 0:
                print(f'  {table[0]}: {count} registros')
        conn.close()
    except Exception as e:
        print(f'Error: {e}')
