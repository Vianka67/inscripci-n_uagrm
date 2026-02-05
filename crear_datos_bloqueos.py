"""
Script para crear datos de prueba con bloqueos
Ejecutar con: python manage.py shell < crear_datos_bloqueos.py
"""
from datetime import date, timedelta
from inscripcion.models import Estudiante, Bloqueo

print("=" * 60)
print("CREANDO DATOS DE PRUEBA - BLOQUEOS")
print("=" * 60)

# Obtener estudiante de prueba
# Obtener o crear estudiante de prueba
from inscripcion.models import Carrera, PlanEstudios, PeriodoAcademico

try:
    estudiante = Estudiante.objects.get(registro="2150826")
    print(f"\n✓ Estudiante encontrado: {estudiante.nombre_completo}")
except Estudiante.DoesNotExist:
    print("\n! Estudiante 2150826 no encontrado, creándolo...")
    try:
        carrera = Carrera.objects.first()
        plan = PlanEstudios.objects.first()
        if not carrera or not plan:
            print("✗ Error: No hay carreras o planes. Ejecuta loaddata first.")
            exit(1)
            
        estudiante = Estudiante.objects.create(
            registro="2150826",
            nombre="Estudiante",
            apellido_paterno="Demo",
            apellido_materno="Arquitectura",
            carrera_actual=carrera,
            semestre_actual=5,
            plan_estudios=plan,
            modalidad="PRESENCIAL",
            lugar_origen="Santa Cruz",
            email="demo@uagrm.edu.bo",
            fecha_ingreso=date(2021, 1, 1)
        )
        print(f"✓ Estudiante creado: {estudiante.nombre_completo}")
    except Exception as e:
        print(f"✗ Error creando estudiante: {e}")
        exit(1)

# Eliminar bloqueos existentes del estudiante de prueba
Bloqueo.objects.filter(estudiante=estudiante).delete()
print("\n✓ Bloqueos anteriores eliminados")

# Crear bloqueo activo (FINANCIERO)
bloqueo1 = Bloqueo.objects.create(
    estudiante=estudiante,
    tipo='FINANCIERO',
    motivo='Deuda pendiente de matrícula del semestre anterior',
    fecha_desbloqueo_estimada=date.today() + timedelta(days=165),  # ~5 meses
    activo=True,
    resuelto=False
)
print(f"\n✓ Bloqueo FINANCIERO creado (ID: {bloqueo1.id})")
print(f"  Motivo: {bloqueo1.motivo}")
print(f"  Fecha desbloqueo estimada: {bloqueo1.fecha_desbloqueo_estimada}")

# Crear bloqueo resuelto (ACADEMICO)
bloqueo2 = Bloqueo.objects.create(
    estudiante=estudiante,
    tipo='ACADEMICO',
    motivo='Materias pendientes de regularización',
    fecha_desbloqueo_estimada=date.today() - timedelta(days=30),
    activo=False,
    resuelto=True,
    fecha_resolucion=date.today() - timedelta(days=15),
    observaciones='Materias regularizadas correctamente'
)
print(f"\n✓ Bloqueo ACADEMICO creado y resuelto (ID: {bloqueo2.id})")
print(f"  Motivo: {bloqueo2.motivo}")
print(f"  Fecha resolución: {bloqueo2.fecha_resolucion}")

# Verificar bloqueos creados
bloqueos_activos = Bloqueo.objects.filter(estudiante=estudiante, activo=True, resuelto=False)
bloqueos_resueltos = Bloqueo.objects.filter(estudiante=estudiante, resuelto=True)

print("\n" + "=" * 60)
print("RESUMEN")
print("=" * 60)
print(f"Bloqueos activos: {bloqueos_activos.count()}")
print(f"Bloqueos resueltos: {bloqueos_resueltos.count()}")
print(f"Total bloqueos: {Bloqueo.objects.filter(estudiante=estudiante).count()}")

print("\n✓ Datos de prueba creados exitosamente!")
print("\nPuedes probar con esta query GraphQL:")
print("""
query {
  bloqueoEstudiante(registro: "2150826") {
    bloqueado
    bloqueos {
      tipo
      motivo
      fechaBloqueo
      fechaDesbloqueoEstimada
      activo
    }
    puedeInscribirse
    mensaje
  }
}
""")
