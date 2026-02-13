import os
import django

# Configurar el entorno de Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'inscripcion_backend.settings')
django.setup()

from inscripcion.models import Carrera, PlanEstudios, Materia, MateriaCarreraSemestre, Estudiante, EstudianteCarrera, PeriodoAcademico

def populate():
    print("Poblando datos académicos...")

    # 1. Asegurar Materias
    materias_data = [
        {"codigo": "LIN-100", "nombre": "Introducción a la Programación", "creditos": 5},
        {"codigo": "MAT-101", "nombre": "Cálculo I", "creditos": 5},
        {"codigo": "FIS-101", "nombre": "Física I", "creditos": 5},
        {"codigo": "LIN-200", "nombre": "Estructuras de Datos I", "creditos": 5},
        {"codigo": "MAT-102", "nombre": "Cálculo II", "creditos": 5},
        {"codigo": "LIN-300", "nombre": "Base de Datos I", "creditos": 6},
        {"codigo": "LIN-310", "nombre": "Sistemas Operativos I", "creditos": 4},
        {"codigo": "IND-101", "nombre": "Química General", "creditos": 4},
        {"codigo": "IND-102", "nombre": "Dibujo Técnico", "creditos": 3},
    ]

    materias_objs = {}
    for m in materias_data:
        obj, created = Materia.objects.get_or_create(
            codigo=m["codigo"],
            defaults={"nombre": m["nombre"], "creditos": m["creditos"]}
        )
        materias_objs[m["codigo"]] = obj
        if created: print(f"Materia creada: {m['codigo']}")

    # 0. Asegurar Estudiante 2150826 (Recomendado)
    est_2150826, created = Estudiante.objects.get_or_create(
        registro="2150826",
        defaults={
            "nombre": "Claudia",
            "apellido_paterno": "Vargas",
            "apellido_materno": "Solis",
            "documento_identidad": "8877665",
            "lugar_origen": "Santa Cruz",
            "email": "claudia.vargas@uagrm.edu.bo",
            "telefono": "70012345",
            "activo": True,
            "fecha_ingreso": "2020-02-15"
        }
    )
    if created: print("Estudiante 2150826 creado")

    #SIS (Carrera 1, Plan 1)
    sis_carrera = Carrera.objects.get(codigo="ING-SIS")
    sis_plan = PlanEstudios.objects.get(carrera=sis_carrera, vigente=True)

    # Asegurar Relación Carrera para 2150826
    EstudianteCarrera.objects.get_or_create(
        estudiante=est_2150826,
        carrera=sis_carrera,
        plan_estudios=sis_plan,
        defaults={"semestre_actual": 2, "modalidad": "PRESENCIAL", "activa": True}
    )

    # 1. Asegurar Materias
    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["MAT-101"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["LIN-100"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["FIS-101"], semestre=1)

    # SIS Semestre 2
    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["MAT-102"], semestre=2)
    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["LIN-200"], semestre=2)

    # SIS Semestre 3 (Juan Carlos 218001234 está aquí)
    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["LIN-300"], semestre=3)
    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["LIN-310"], semestre=3)

    # IND (Carrera 2, Plan 2)
    ind_carrera = Carrera.objects.get(codigo="ING-IND")
    ind_plan = PlanEstudios.objects.get(carrera=ind_carrera, vigente=True)

    # IND Semestre 1 (Juan Carlos 218001234 también está aquí)
    MateriaCarreraSemestre.objects.get_or_create(carrera=ind_carrera, plan_estudios=ind_plan, materia=materias_objs["MAT-101"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=ind_carrera, plan_estudios=ind_plan, materia=materias_objs["IND-101"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=ind_carrera, plan_estudios=ind_plan, materia=materias_objs["IND-102"], semestre=1)

    print("Datos poblados exitosamente.")

if __name__ == "__main__":
    populate()
