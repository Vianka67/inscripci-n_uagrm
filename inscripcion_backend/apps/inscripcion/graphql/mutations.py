"""
Mutations GraphQL para el modulo de inscripción
"""
import graphene
from django.utils import timezone
from django.db import transaction


class MatSelecInput(graphene.InputObjectType):
    nroSerie = graphene.String(required=True)
    nivel = graphene.Int()
    codMat = graphene.Int(required=True)
    plan = graphene.String()
    sigla = graphene.String()
    nombreMateria = graphene.String()
    grupo = graphene.String(required=True)
    estado = graphene.String()
    ok = graphene.Int()

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
        proceso = graphene.String()

    ok = graphene.Boolean()
    mensaje = graphene.String()

    @staticmethod
    def mutate(root, info, registro, codigo_carrera, oferta_ids, proceso="Inscripción"):
        from ..models import (
            Estudiante, EstudianteCarrera, PeriodoAcademico,
            Inscripcion, InscripcionMateria, OfertaMateria
        )

        try:
            from ..tasks import procesar_inscripcion_asincrona
            procesar_inscripcion_asincrona.delay(registro, codigo_carrera, oferta_ids, proceso)
            
            return ConfirmarInscripcion(
                ok=True,
                mensaje="Tu inscripción ha sido recibida y se está procesando."
            )
        except Exception as e:
            return ConfirmarInscripcion(ok=False, mensaje=f"Error en el sistema: {str(e)}")


class MarcarMaterias(graphene.Mutation):
    class Arguments:
        matSelec = graphene.List(MatSelecInput, required=True)

    Output = graphene.Boolean

    @staticmethod
    def mutate(root, info, matSelec):
        from ..models.seleccion import MatSelec as MatSelecModel
        from django.db import transaction
        
        try:
            with transaction.atomic():
                for mat in matSelec:
                    MatSelecModel.objects.update_or_create(
                        nro_serie=mat.nroSerie,
                        cod_mat=mat.codMat,
                        grupo=mat.grupo,
                        defaults={
                            'nivel': mat.nivel or 0,
                            'plan': mat.plan or "",
                            'sigla': mat.sigla or "",
                            'nombre_materia': mat.nombreMateria or "",
                            'estado': mat.estado or "I",
                            'ok': mat.ok if mat.ok is not None else 1
                        }
                    )
            return True
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error en marcarMaterias: {str(e)}")
            return False


class Mutation(graphene.ObjectType):
    confirmar_inscripcion = ConfirmarInscripcion.Field(
        description="Confirma la inscripción guardando los grupos seleccionados en la base de datos."
    )
    marcar_materias = MarcarMaterias.Field(
        description="Guarda temporalmente las materias seleccionadas antes de confirmar."
    )
