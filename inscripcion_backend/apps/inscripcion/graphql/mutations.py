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
        return ConfirmarInscripcion(
            ok=False, 
            mensaje="Inscripción deshabilitada por seguridad (Modo Lectura activo para Informix)."
        )


class MarcarMaterias(graphene.Mutation):
    class Arguments:
        matSelec = graphene.List(MatSelecInput, required=True)

    Output = graphene.Boolean

    @staticmethod
    def mutate(root, info, matSelec):
        # Bloqueado por seguridad
        return False


class Mutation(graphene.ObjectType):
    confirmar_inscripcion = ConfirmarInscripcion.Field(
        description="Confirma la inscripción guardando los grupos seleccionados en la base de datos."
    )
    marcar_materias = MarcarMaterias.Field(
        description="Guarda temporalmente las materias seleccionadas antes de confirmar."
    )
