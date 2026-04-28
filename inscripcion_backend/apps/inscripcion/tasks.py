import time
from celery import shared_task
from django.db import transaction
from django.utils import timezone

@shared_task
def procesar_inscripcion_asincrona(registro, codigo_carrera, oferta_ids, proceso='Inscripción'):
    from .models import (
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
                    'estado': 'PENDIENTE_PAGO',
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

            if proceso == 'Retiro':
                # Retirar materias seleccionadas
                inscritas = inscripcion.materias_inscritas.filter(oferta_id__in=oferta_ids).select_related('oferta')
                n_retiradas = inscritas.count()
                
                for mi in inscritas:
                    if mi.oferta:
                        oferta_update = OfertaMateria.objects.select_for_update().get(id=mi.oferta.id)
                        if oferta_update.cupo_actual > 0:
                            oferta_update.cupo_actual -= 1
                            oferta_update.save(update_fields=['cupo_actual'])
                
                inscritas.delete()
                
                # Actualizar estado de la inscripción si es necesario
                inscripcion.fecha_inscripcion_realizada = timezone.now()
                inscripcion.save(update_fields=['fecha_inscripcion_realizada'])

                return {
                    "ok": True,
                    "mensaje": f"Retiro exitoso de {n_retiradas} materia{'s' if n_retiradas != 1 else ''}.",
                    "inscripcion_id": inscripcion.id
                }

            elif proceso == 'Adición':
                # Adicionar materias sin borrar las anteriores
                inscritas_ids = list(inscripcion.materias_inscritas.values_list('oferta_id', flat=True))
                nuevas_ofertas = [o for o in ofertas if o.id not in inscritas_ids]
                
                if not nuevas_ofertas:
                    return {"ok": False, "mensaje": "Las materias seleccionadas ya están inscritas."}

                for oferta in nuevas_ofertas:
                    InscripcionMateria.objects.create(
                        inscripcion=inscripcion,
                        oferta=oferta,
                        materia=oferta.materia_carrera.materia,
                        grupo=oferta.grupo,
                    )
                    oferta.cupo_actual += 1
                    oferta.save(update_fields=['cupo_actual'])
                
                inscripcion.estado = 'PENDIENTE_PAGO'
                inscripcion.fecha_inscripcion_realizada = timezone.now()
                inscripcion.save(update_fields=['estado', 'fecha_inscripcion_realizada'])
                
                # Programar la liberación de cupos si no paga
                liberar_cupos_por_impago.apply_async((inscripcion.id,), countdown=600)

                n = len(nuevas_ofertas)
                return {
                    "ok": True, 
                    "mensaje": f"Adición realizada. Tienes 10 minutos para completar el pago de {n} nueva{'s' if n != 1 else ''} materia{'s' if n != 1 else ''}.",
                    "inscripcion_id": inscripcion.id
                }

            else:  # Inscripción (Proceso regular)
                # Liberar cupos de las materias anteriores si ya existía una inscripción previa
                inscripciones_anteriores = inscripcion.materias_inscritas.select_related('oferta').all()
                for ia in inscripciones_anteriores:
                    if ia.oferta:
                        oferta_vieja = OfertaMateria.objects.select_for_update().get(id=ia.oferta.id)
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

                inscripcion.estado = 'PENDIENTE_PAGO'
                inscripcion.fecha_inscripcion_realizada = timezone.now()
                inscripcion.save(update_fields=['estado', 'fecha_inscripcion_realizada'])
                
                # Programar la liberación de cupos
                liberar_cupos_por_impago.apply_async((inscripcion.id,), countdown=600)

                n = len(oferta_ids)
                return {
                    "ok": True, 
                    "mensaje": f"Reserva realizada. Tienes 10 minutos para completar el pago de {n} materia{'s' if n != 1 else ''}.",
                    "inscripcion_id": inscripcion.id
                }

    except Exception as e:
        return {"ok": False, "mensaje": f"Error asíncrono: {str(e)}"}


@shared_task
def liberar_cupos_por_impago(inscripcion_id):
    """
    Libera los cupos de una inscripción si no ha sido confirmada (pagada) en el tiempo límite.
    """
    from .models import Inscripcion, OfertaMateria
    
    try:
        with transaction.atomic():
            inscripcion = Inscripcion.objects.select_for_update().get(id=inscripcion_id)
            
            # Solo liberamos si sigue pendiente de pago
            if inscripcion.estado == 'PENDIENTE_PAGO':
                print(f"Liberando cupos por impago para inscripción {inscripcion_id}")
                
                materias_inscritas = inscripcion.materias_inscritas.select_related('oferta').all()
                for mi in materias_inscritas:
                    if mi.oferta:
                        oferta = OfertaMateria.objects.select_for_update().get(id=mi.oferta.id)
                        if oferta.cupo_actual > 0:
                            oferta.cupo_actual -= 1
                            oferta.save(update_fields=['cupo_actual'])
                
                inscripcion.estado = 'CANCELADA'
                inscripcion.save(update_fields=['estado'])
                return f"Inscripción {inscripcion_id} cancelada por falta de pago. Cupos liberados."
            
            return f"Inscripción {inscripcion_id} ya se encuentra en estado {inscripcion.estado}. No se requiere limpieza."
            
    except Inscripcion.DoesNotExist:
        return f"Error: Inscripción {inscripcion_id} no encontrada."
    except Exception as e:
        return f"Error en liberar_cupos_por_impago: {str(e)}"
