import os
import django
import random

# Configurar el entorno de Django
import sys
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.append(project_root)

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'inscripcion_backend.settings')
django.setup()

from inscripcion.models import (
    Carrera, PlanEstudios, Materia, MateriaCarreraSemestre, 
    PeriodoAcademico, OfertaMateria
)

def populate_offers():
    print("Poblando ofertas de materias...")

    # 1. Asegurar Periodo 1/2026
    periodo, created = PeriodoAcademico.objects.get_or_create(
        codigo="1/2026",
        defaults={
            "nombre": "Primer Semestre 2026",
            "tipo": "1/2026",
            "fecha_inicio": "2026-02-01",
            "fecha_fin": "2026-06-30",
            "activo": True,
            "inscripciones_habilitadas": True
        }
    )
    if created:
        print(f"Periodo creado: {periodo}")
    else:
        print(f"Periodo existente: {periodo}")

    # 2. Obtener Materias por Carrera (mock data base)
    mcs_list = MateriaCarreraSemestre.objects.all()
    
    if not mcs_list.exists():
        print("No hay MateriaCarreraSemestre. Ejecuta populate_mock_data.py primero.")
        return

    # 3. Crear Ofertas (Grupos)
    docentes = ["Ing. Juan Perez", "Ing. Maria Lopez", "Lic. Carlos Ruiz", "Ing. Ana Soto", "Por designar"]
    horarios = ["Lun-Mie-Vie 07:00-09:00", "Mar-Jue 10:00-12:00", "Lun-Mie 14:00-16:00", "Sabado 08:00-12:00"]
    grupos = ["A", "B", "C", "D", "Z"]

    count = 0
    for mcs in mcs_list:
        # Crear 2-3 grupos por materia
        num_grupos = random.randint(2, 4)
        for i in range(num_grupos):
            grupo_sigla = grupos[i]
            
            offer, created = OfertaMateria.objects.get_or_create(
                materia_carrera=mcs,
                periodo=periodo,
                grupo=grupo_sigla,
                defaults={
                    "docente": random.choice(docentes),
                    "horario": random.choice(horarios),
                    "cupo_maximo": 40,
                    "cupo_actual": random.randint(0, 40)
                }
            )
            if created:
                count += 1
                print(f"Oferta creada: {offer}")
    
    print(f"Total ofertas creadas: {count}")

if __name__ == "__main__":
    populate_offers()
