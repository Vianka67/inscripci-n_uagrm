"""
Mutations GraphQL para el módulo de inscripción
"""
import graphene
from django.utils import timezone
from django.db import transaction


class ConfirmarInscripcionResult(graphene.ObjectType):
    ok = graphene.Boolean()
    mensaje = graphene.String()


class ConfirmarInscripcion(graphene.Mutation):
    """
    Confirma la inscripción de un estudiante guardando los grupos seleccionados.
    Recibe una lista de IDs de OfertaMateria y los vincula a la Inscripcion del estudiante.
    """

    class Arguments:
        registro = graphene.String(required=True)
        codigo_carrera = graphene.String(required=True)
        oferta_ids = graphene.List(graphene.Int, required=True)

    ok = graphene.Boolean()
    mensaje = graphene.String()

    @staticmethod
    def mutate(root, info, registro, codigo_carrera, oferta_ids):
        from inscripcion.models import (
            Estudiante, EstudianteCarrera, PeriodoAcademico,
            Inscripcion, InscripcionMateria, OfertaMateria
        )

        try:
            with transaction.atomic():
                # 1. Buscar estudiante
                try:
                    estudiante = Estudiante.objects.get(registro=registro)
                except Estudiante.DoesNotExist:
                    return ConfirmarInscripcion(
                        ok=False,
                        mensaje=f"Estudiante con registro {registro} no encontrado."
                    )

                # 2. Buscar relación estudiante-carrera activa
                try:
                    est_carrera = EstudianteCarrera.objects.get(
                        estudiante=estudiante,
                        carrera__codigo=codigo_carrera,
                        activa=True
                    )
                except EstudianteCarrera.DoesNotExist:
                    return ConfirmarInscripcion(
                        ok=False,
                        mensaje=f"El estudiante no está activo en la carrera {codigo_carrera}."
                    )

                # 3. Obtener periodo activo
                periodo = PeriodoAcademico.objects.filter(activo=True).first()
                if not periodo:
                    return ConfirmarInscripcion(
                        ok=False,
                        mensaje="No hay un periodo académico activo."
                    )

                # 4. Buscar o crear la Inscripcion
                inscripcion, created = Inscripcion.objects.get_or_create(
                    estudiante_carrera=est_carrera,
                    periodo_academico=periodo,
                    defaults={
                        'fecha_inscripcion_asignada': timezone.now().date(),
                        'estado': 'PENDIENTE',
                    }
                )

                # 5. Validar las ofertas
                ofertas = OfertaMateria.objects.filter(id__in=oferta_ids)
                if len(ofertas) != len(oferta_ids):
                    encontrados = list(ofertas.values_list('id', flat=True))
                    faltantes = [i for i in oferta_ids if i not in encontrados]
                    return ConfirmarInscripcion(
                        ok=False,
                        mensaje=f"Algunas ofertas no fueron encontradas: {faltantes}"
                    )

                # 6. Verificar cupos disponibles
                sin_cupo = []
                for oferta in ofertas:
                    if oferta.cupo_actual >= oferta.cupo_maximo:
                        sin_cupo.append(oferta.materia_carrera.materia.codigo)
                if sin_cupo:
                    return ConfirmarInscripcion(
                        ok=False,
                        mensaje=f"Sin cupo en: {', '.join(sin_cupo)}"
                    )

                # 7. Limpiar inscripciones anteriores de este periodo (reemplazo)
                inscripcion.materias_inscritas.all().delete()

                # 8. Crear los InscripcionMateria y actualizar cupos
                for oferta in ofertas:
                    InscripcionMateria.objects.create(
                        inscripcion=inscripcion,
                        oferta=oferta,
                        materia=oferta.materia_carrera.materia,
                        grupo=oferta.grupo,
                    )
                    # Incrementar cupo actual
                    oferta.cupo_actual += 1
                    oferta.save(update_fields=['cupo_actual'])

                # 9. Marcar inscripción como confirmada
                inscripcion.estado = 'CONFIRMADA'
                inscripcion.fecha_inscripcion_realizada = timezone.now()
                inscripcion.save(update_fields=['estado', 'fecha_inscripcion_realizada'])

                n = len(oferta_ids)
                return ConfirmarInscripcion(
                    ok=True,
                    mensaje=f"Inscripción confirmada con {n} materia{'s' if n != 1 else ''}."
                )

        except Exception as e:
            return ConfirmarInscripcion(ok=False, mensaje=f"Error inesperado: {str(e)}")


class Mutation(graphene.ObjectType):
    confirmar_inscripcion = ConfirmarInscripcion.Field(
        description="Confirma la inscripción guardando los grupos seleccionados en la base de datos."
    )
