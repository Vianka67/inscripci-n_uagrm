import graphene
from graphene_django import DjangoObjectType
from inscripcion.models import (
    Carrera, PlanEstudios, Materia, MateriaCarreraSemestre,
    Estudiante, EstudianteCarrera, PeriodoAcademico, Inscripcion, 
    InscripcionMateria, Bloqueo, OfertaMateria
)

class CarreraType(DjangoObjectType):
    class Meta:
        model = Carrera
        fields = '__all__'

class PlanEstudiosType(DjangoObjectType):
    class Meta:
        model = PlanEstudios
        fields = '__all__'

class MateriaType(DjangoObjectType):
    class Meta:
        model = Materia
        fields = '__all__'

class MateriaCarreraSemestreType(DjangoObjectType):
    class Meta:
        model = MateriaCarreraSemestre
        fields = '__all__'

class EstudianteType(DjangoObjectType):
    nombre_completo = graphene.String()
    
    class Meta:
        model = Estudiante
        fields = '__all__'
    
    def resolve_nombre_completo(self, info):
        return self.nombre_completo

class EstudianteCarreraType(DjangoObjectType):
    class Meta:
        model = EstudianteCarrera
        fields = ('estudiante', 'carrera', 'plan_estudios', 'semestre_actual', 'modalidad', 'activa')

class PeriodoAcademicoType(DjangoObjectType):
    class Meta:
        model = PeriodoAcademico
        fields = '__all__'

class InscripcionType(DjangoObjectType):
    estudiante = graphene.Field('inscripcion.graphql.types.EstudianteType')
    
    class Meta:
        model = Inscripcion
        fields = '__all__'
        
    def resolve_estudiante(self, info):
        return self.estudiante_carrera.estudiante

class InscripcionMateriaType(DjangoObjectType):
    class Meta:
        model = InscripcionMateria
        fields = '__all__'

class BloqueoType(DjangoObjectType):
    class Meta:
        model = Bloqueo
        fields = '__all__'

class OfertaMateriaType(DjangoObjectType):
    materia_nombre = graphene.String()
    materia_codigo = graphene.String()
    carrera_nombre = graphene.String()
    cupos_disponibles = graphene.Int()
    semestre = graphene.Int()
    
    class Meta:
        model = OfertaMateria
        fields = '__all__'
        
    def resolve_materia_nombre(self, info):
        return self.materia_carrera.materia.nombre
        
    def resolve_materia_codigo(self, info):
        return self.materia_carrera.materia.codigo
        
    def resolve_carrera_nombre(self, info):
        return self.materia_carrera.carrera.nombre
        
    def resolve_cupos_disponibles(self, info):
        return self.cupo_maximo - self.cupo_actual

    def resolve_semestre(self, info):
        return self.materia_carrera.semestre


# ========== TIPOS COMPUESTOS PARA RESPUESTAS ==========

class EstudianteInfoType(graphene.ObjectType):
    """Información básica del estudiante para respuestas compuestas"""
    registro = graphene.String()
    nombre_completo = graphene.String()
    nombre = graphene.String()
    apellido_paterno = graphene.String()
    apellido_materno = graphene.String()


class CarreraInfoType(graphene.ObjectType):
    """Información de carrera para respuestas compuestas"""
    codigo = graphene.String()
    nombre = graphene.String()
    tipo = graphene.String()
    facultad = graphene.String()


class PeriodoInfoType(graphene.ObjectType):
    """Información de periodo para respuestas compuestas"""
    codigo = graphene.String()
    nombre = graphene.String()
    inscripciones_habilitadas = graphene.Boolean()
    fecha_inicio = graphene.String()
    fecha_fin = graphene.String()


class OpcionesDisponiblesType(graphene.ObjectType):
    """Opciones disponibles para el estudiante"""
    fechas_inscripcion = graphene.Boolean()
    boleta = graphene.Boolean()
    bloqueo = graphene.Boolean()
    inscripcion = graphene.Boolean()


class InscripcionInfoType(graphene.ObjectType):
    """Información de inscripción para respuestas compuestas"""
    fecha_asignada = graphene.String()
    fecha_realizada = graphene.String()
    estado = graphene.String()
    bloqueado = graphene.Boolean()
    boleta_generada = graphene.Boolean()
    numero_boleta = graphene.String()


class PanelEstudianteType(graphene.ObjectType):
    """Respuesta completa del panel del estudiante"""
    estudiante = graphene.Field(EstudianteInfoType)
    carrera = graphene.Field(CarreraInfoType)
    modalidad = graphene.String()
    semestre_actual = graphene.Int()
    estado = graphene.String()
    periodo_actual = graphene.Field(PeriodoInfoType)
    opciones_disponibles = graphene.Field(OpcionesDisponiblesType)
    inscripcion_actual = graphene.Field(InscripcionInfoType)
    error = graphene.String()


class SemestreInfoType(graphene.ObjectType):
    """Información de un semestre"""
    numero = graphene.Int()
    nombre = graphene.String()
    habilitado = graphene.Boolean()


class SemestresPorCarreraType(graphene.ObjectType):
    """Respuesta de semestres por carrera"""
    carrera = graphene.Field(CarreraInfoType)
    semestres = graphene.List(SemestreInfoType)
    total_semestres = graphene.Int()


class BloqueoInfoType(graphene.ObjectType):
    """Información de un bloqueo"""
    id = graphene.Int()
    tipo = graphene.String()
    motivo = graphene.String()
    fecha_bloqueo = graphene.String()
    fecha_desbloqueo_estimada = graphene.String()
    activo = graphene.Boolean()


class BloqueoEstudianteType(graphene.ObjectType):
    """Respuesta completa de bloqueos del estudiante"""
    bloqueado = graphene.Boolean()
    bloqueos = graphene.List(BloqueoInfoType)
    puede_inscribirse = graphene.Boolean()
    mensaje = graphene.String()


class MateriaInscritaInfoType(graphene.ObjectType):
    """Información de materia inscrita para boleta"""
    codigo = graphene.String()
    nombre = graphene.String()
    creditos = graphene.Int()
    grupo = graphene.String()
    semestre = graphene.Int()
    horas_teoricas = graphene.Int()
    horas_practicas = graphene.Int()


class BoletaInscripcionType(graphene.ObjectType):
    """Respuesta completa de boleta de inscripción"""
    estudiante = graphene.Field(EstudianteInfoType)
    carrera = graphene.Field(CarreraInfoType)
    periodo = graphene.Field(PeriodoInfoType)
    numero_boleta = graphene.String()
    fecha_generacion = graphene.String()
    estado = graphene.String()
    materias_inscritas = graphene.List(MateriaInscritaInfoType)
    total_creditos = graphene.Int()
    total_materias = graphene.Int()

class FechasInscripcionType(graphene.ObjectType):
    """Información de fechas de inscripción para compatibilidad"""
    fecha_inicio = graphene.String()
    fecha_fin = graphene.String()
    grupo = graphene.String()
    estado = graphene.String()
