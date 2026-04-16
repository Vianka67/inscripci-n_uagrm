import os
import django

# Configurar el entorno de Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()

from apps.inscripcion.models import Carrera, PlanEstudios, Materia, MateriaCarreraSemestre, Estudiante, EstudianteCarrera, PeriodoAcademico

def populate():
    print("Poblando datos académicos...")

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

    est_2150826, created = Estudiante.objects.get_or_create(
        registro="2150826",
        defaults={
            "nombre": "Claudia",
            "apellido_paterno": "Vargas",
            "apellido_materno": "Solis",
            "contrasena": "123456",
            "documento_identidad": "8877665",
            "lugar_origen": "Santa Cruz",
            "email": "claudia.vargas@uagrm.edu.bo",
            "telefono": "70012345",
            "activo": True,
            "fecha_ingreso": "2020-02-15"
        }
    )
    if created: print("Estudiante 2150826 creado")

    sis_carrera = Carrera.objects.get(codigo="ING-SIS")
    sis_plan = PlanEstudios.objects.get(carrera=sis_carrera, vigente=True)

    EstudianteCarrera.objects.get_or_create(
        estudiante=est_2150826,
        carrera=sis_carrera,
        plan_estudios=sis_plan,
        defaults={"semestre_actual": 2, "modalidad": "PRESENCIAL", "activa": True}
    )

    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["MAT-101"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["LIN-100"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["FIS-101"], semestre=1)

    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["MAT-102"], semestre=2)
    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["LIN-200"], semestre=2)

    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["LIN-300"], semestre=3)
    MateriaCarreraSemestre.objects.get_or_create(carrera=sis_carrera, plan_estudios=sis_plan, materia=materias_objs["LIN-310"], semestre=3)

    ind_carrera = Carrera.objects.get(codigo="ING-IND")
    ind_plan = PlanEstudios.objects.get(carrera=ind_carrera, vigente=True)

    MateriaCarreraSemestre.objects.get_or_create(carrera=ind_carrera, plan_estudios=ind_plan, materia=materias_objs["MAT-101"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=ind_carrera, plan_estudios=ind_plan, materia=materias_objs["IND-101"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=ind_carrera, plan_estudios=ind_plan, materia=materias_objs["IND-102"], semestre=1)

    med_carrera, _ = Carrera.objects.get_or_create(codigo="MED-001", defaults={"nombre": "Medicina", "facultad": "Facultad de Ciencias de la Salud Humana", "duracion_semestres": 12, "activa": True})
    med_plan, _ = PlanEstudios.objects.get_or_create(carrera=med_carrera, codigo="PLAN-MED-2022", defaults={"nombre": "Plan de Estudios Medicina 2022", "anio_vigencia": 2022, "vigente": True})

    arq_carrera, _ = Carrera.objects.get_or_create(codigo="ARQ-001", defaults={"nombre": "Arquitectura", "facultad": "Facultad de Ciencias del Hábitat", "duracion_semestres": 10, "activa": True})
    arq_plan, _ = PlanEstudios.objects.get_or_create(carrera=arq_carrera, codigo="PLAN-ARQ-2020", defaults={"nombre": "Plan de Estudios Arquitectura 2020", "anio_vigencia": 2020, "vigente": True})

    nuevas_materias = [
        {"codigo": "ANA-101", "nombre": "Anatomía I", "creditos": 6},
        {"codigo": "BIO-101", "nombre": "Biología Celular", "creditos": 4},
        {"codigo": "HIS-101", "nombre": "Histología", "creditos": 5},
        {"codigo": "DIR-101", "nombre": "Dibujo Arquitectónico", "creditos": 5},
        {"codigo": "HIA-101", "nombre": "Historia de la Arquitectura", "creditos": 4},
        {"codigo": "DIS-101", "nombre": "Diseño I", "creditos": 6},
    ]
    for m in nuevas_materias:
        obj, c = Materia.objects.get_or_create(codigo=m["codigo"], defaults={"nombre": m["nombre"], "creditos": m["creditos"]})
        materias_objs[m["codigo"]] = obj

    MateriaCarreraSemestre.objects.get_or_create(carrera=med_carrera, plan_estudios=med_plan, materia=materias_objs["ANA-101"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=med_carrera, plan_estudios=med_plan, materia=materias_objs["BIO-101"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=med_carrera, plan_estudios=med_plan, materia=materias_objs["HIS-101"], semestre=2)

    MateriaCarreraSemestre.objects.get_or_create(carrera=arq_carrera, plan_estudios=arq_plan, materia=materias_objs["DIR-101"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=arq_carrera, plan_estudios=arq_plan, materia=materias_objs["DIS-101"], semestre=1)
    MateriaCarreraSemestre.objects.get_or_create(carrera=arq_carrera, plan_estudios=arq_plan, materia=materias_objs["HIA-101"], semestre=2)

    est_med, _ = Estudiante.objects.get_or_create(
        registro="220001111",
        defaults={"nombre": "Roberto", "apellido_paterno": "Suarez", "apellido_materno": "Gomez", "contrasena": "123456", "documento_identidad": "4455667", "email": "roberto@estudiante.uagrm.edu.bo", "telefono": "78111111", "activo": True, "fecha_ingreso": "2022-02-01"}
    )
    EstudianteCarrera.objects.get_or_create(estudiante=est_med, carrera=med_carrera, plan_estudios=med_plan, defaults={"semestre_actual": 1, "modalidad": "PRESENCIAL", "activa": True})

    est_arq, _ = Estudiante.objects.get_or_create(
        registro="221002222",
        defaults={"nombre": "Ana", "apellido_paterno": "Silva", "apellido_materno": "Rios", "contrasena": "123456", "documento_identidad": "5566778", "email": "ana.silva@estudiante.uagrm.edu.bo", "telefono": "78222222", "activo": True, "fecha_ingreso": "2021-02-01"}
    )
    EstudianteCarrera.objects.get_or_create(estudiante=est_arq, carrera=arq_carrera, plan_estudios=arq_plan, defaults={"semestre_actual": 2, "modalidad": "PRESENCIAL", "activa": True})

    est_sis_adv, _ = Estudiante.objects.get_or_create(
        registro="217003333",
        defaults={"nombre": "Luis", "apellido_paterno": "Mendez", "apellido_materno": "Paz", "contrasena": "123456", "documento_identidad": "3344556", "email": "luis.mendez@uagrm.edu.bo", "telefono": "78333333", "activo": True, "fecha_ingreso": "2017-02-01"}
    )
    EstudianteCarrera.objects.get_or_create(estudiante=est_sis_adv, carrera=sis_carrera, plan_estudios=sis_plan, defaults={"semestre_actual": 4, "modalidad": "PRESENCIAL", "activa": True})

    print("Datos poblados exitosamente.")

if __name__ == "__main__":
    populate()
