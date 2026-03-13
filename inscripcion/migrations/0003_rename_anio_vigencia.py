from django.db import migrations


def rename_column_if_exists(apps, schema_editor):
    from django.db import connection
    with connection.cursor() as cursor:
        # Check if "año_vigencia" exists in "inscripcion_planestudios"
        cursor.execute("""
            SELECT count(*) 
            FROM information_schema.columns 
            WHERE table_name = 'inscripcion_planestudios' 
            AND column_name = 'año_vigencia'
        """)
        if cursor.fetchone()[0] > 0:
            cursor.execute('ALTER TABLE inscripcion_planestudios RENAME COLUMN "año_vigencia" TO "anio_vigencia"')

def reverse_rename_column(apps, schema_editor):
    from django.db import connection
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT count(*) 
            FROM information_schema.columns 
            WHERE table_name = 'inscripcion_planestudios' 
            AND column_name = 'anio_vigencia'
        """)
        if cursor.fetchone()[0] > 0:
            cursor.execute('ALTER TABLE inscripcion_planestudios RENAME COLUMN "anio_vigencia" TO "año_vigencia"')

class Migration(migrations.Migration):

    dependencies = [
        ('inscripcion', '0002_alter_planestudios_options'),
    ]

    operations = [
        migrations.RunPython(rename_column_if_exists, reverse_rename_column),
    ]

