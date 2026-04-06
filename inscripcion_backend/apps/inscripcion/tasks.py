import time
from celery import shared_task
from django.db import transaction
from django.utils import timezone

@shared_task
def procesar_inscripcion_asincrona(registro, codigo_carrera, oferta_ids):
    from apps.inscripcion.models import (
        Estudiante, EstudianteCarrera, PeriodoAcademico,
        Inscripcion, InscripcionMateria, OfertaMateria, Bloqueo
)
    try:
        with transaction.atomic():
            estudiante = Estudiante.objects.get(registro=registro)
            
            est_carrera = EstudianteCarrera.objects.get(
                estudiante=estudiante,
                carrera__codigo=codigo_carrera,
                activa=True
            )

            bloqueo = Bloqueo.objects.filter(estudiante_carrera=est_carrera, activo=True).first()
            if bloqueo:
                return {"ok": False, "mensaje": f"Inscripción rechazada: {bloqueo.motivo}"}

            periodo = PeriodoAcademico.objects.filter(activo=True).first()
            if not periodo:
                return {"ok": False, "mensaje": "No hay un periodo académico activo."}

            inscripcion, created = Inscripcion.objects.get_or_create(
                estudiante_carrera=est_carrera,
                periodo_academico=periodo,
                defaults={
                    'fecha_inscripcion_asignada': timezone.now().date(),
                    'estado': 'PENDIENTE',
                }
            )

            ofertas = OfertaMateria.objects.filter(id__in=oferta_ids)
            if len(ofertas) != len(oferta_ids):
                encontrados = list(ofertas.values_list('id', flat=True))
                faltantes = [i for i in oferta_ids if i not in encontrados]
                return {"ok": False, "mensaje": f"Algunas ofertas no fueron encontradas: {faltantes}"}

            ofertas = OfertaMateria.objects.select_for_update().filter(id__in=oferta_ids)
            sin_cupo = []
            for oferta in ofertas:
                if oferta.cupo_actual >= oferta.cupo_maximo:
                    sin_cupo.append(oferta.materia_carrera.materia.codigo)
            if sin_cupo:
                return {"ok": False, "mensaje": f"Lo sentimos, los cupos se acaban de llenar en: {', '.join(sin_cupo)}"}

            # Liberar cupos de las materias anteriores con select_for_update para evitar condiciones de carrera
            inscripciones_anteriores = inscripcion.materias_inscritas.select_related('oferta').all()
            ofertas_anteriores_ids = [ia.oferta.id for ia in inscripciones_anteriores]
            if ofertas_anteriores_ids:
                ofertas_viejas = OfertaMateria.objects.select_for_update().filter(id__in=ofertas_anteriores_ids)
                for oferta_vieja in ofertas_viejas:
                    if oferta_vieja.cupo_actual > 0:
                        oferta_vieja.cupo_actual -= 1
                        oferta_vieja.save(update_fields=['cupo_actual'])
            
            inscripciones_anteriores.delete()

            for oferta in ofertas:
                InscripcionMateria.objects.create(
                    inscripcion=inscripcion,
                    oferta=oferta,
                    materia=oferta.materia_carrera.materia,
                    grupo=oferta.grupo,
                )
                oferta.cupo_actual += 1
                oferta.save(update_fields=['cupo_actual'])

            inscripcion.estado = 'CONFIRMADA'
            inscripcion.fecha_inscripcion_realizada = timezone.now()
            inscripcion.save(update_fields=['estado', 'fecha_inscripcion_realizada'])
            
            time.sleep(1)

            n = len(oferta_ids)
            return {"ok": True, "mensaje": f"Inscripción procesada y confirmada con {n} materia{'s' if n != 1 else ''} exitosamente."}

    except Exception as e:
        return {"ok": False, "mensaje": f"Error asíncrono: {str(e)}"}
