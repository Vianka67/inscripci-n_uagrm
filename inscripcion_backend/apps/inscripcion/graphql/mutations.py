"""
Mutations GraphQL para el modulo de inscripción
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
        from ..models import (
            Estudiante, EstudianteCarrera, PeriodoAcademico,
            Inscripcion, InscripcionMateria, OfertaMateria
        )

        try:
            from ..tasks import procesar_inscripcion_asincrona
            procesar_inscripcion_asincrona.delay(registro, codigo_carrera, oferta_ids)
            
            return ConfirmarInscripcion(
                ok=True,
                mensaje="Tu inscripción ha sido recibida y se está procesando."
            )
        except Exception as e:
            return ConfirmarInscripcion(ok=False, mensaje=f"Error en el sistema: {str(e)}")


class Mutation(graphene.ObjectType):
    confirmar_inscripcion = ConfirmarInscripcion.Field(
        description="Confirma la inscripción guardando los grupos seleccionados en la base de datos."
    )
