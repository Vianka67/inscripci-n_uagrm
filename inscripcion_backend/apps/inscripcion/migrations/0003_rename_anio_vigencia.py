from django.db import migrations


def rename_column_if_exists(apps, schema_editor):
    from django.db import connection
    with connection.cursor() as cursor:
        # Compatible con SQLite: usar PRAGMA table_info en vez de information_schema
        cursor.execute("PRAGMA table_info(inscripcion_planestudios)")
        columns = [row[1] for row in cursor.fetchall()]
        if 'año_vigencia' in columns:
            cursor.execute('ALTER TABLE inscripcion_planestudios RENAME COLUMN "año_vigencia" TO "anio_vigencia"')

def reverse_rename_column(apps, schema_editor):
    from django.db import connection
    with connection.cursor() as cursor:
        cursor.execute("PRAGMA table_info(inscripcion_planestudios)")
        columns = [row[1] for row in cursor.fetchall()]
        if 'anio_vigencia' in columns:
            cursor.execute('ALTER TABLE inscripcion_planestudios RENAME COLUMN "anio_vigencia" TO "año_vigencia"')

class Migration(migrations.Migration):

    dependencies = [
        ('inscripcion', '0002_alter_planestudios_options'),
    ]

    operations = [
        migrations.RunPython(rename_column_if_exists, reverse_rename_column),
    ]

