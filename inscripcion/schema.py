import graphene
from graphene_django import DjangoObjectType
from .models import (
    Carrera, PlanEstudios, Materia, MateriaCarreraSemestre,
    Estudiante, PeriodoAcademico, Inscripcion, InscripcionMateria
)


# ============= TYPES =============

class CarreraType(DjangoObjectType):
    """Type para Carrera"""
    class Meta:
        model = Carrera
        fields = '__all__'


class PlanEstudiosType(DjangoObjectType):
    """Type para Plan de Estudios"""
    class Meta:
        model = PlanEstudios
        fields = '__all__'


class MateriaType(DjangoObjectType):
    """Type para Materia"""
    class Meta:
        model = Materia
        fields = '__all__'


class MateriaCarreraSemestreType(DjangoObjectType):
    """Type para Materia por Carrera y Semestre"""
    class Meta:
        model = MateriaCarreraSemestre
        fields = '__all__'


class EstudianteType(DjangoObjectType):
    """Type para Estudiante"""
    nombre_completo = graphene.String()
    
    class Meta:
        model = Estudiante
        fields = '__all__'
    
    def resolve_nombre_completo(self, info):
        return self.nombre_completo


class PeriodoAcademicoType(DjangoObjectType):
    """Type para Periodo Académico"""
    class Meta:
        model = PeriodoAcademico
        fields = '__all__'


class InscripcionType(DjangoObjectType):
    """Type para Inscripción"""
    class Meta:
        model = Inscripcion
        fields = '__all__'


class InscripcionMateriaType(DjangoObjectType):
    """Type para Materia Inscrita"""
    class Meta:
        model = InscripcionMateria
        fields = '__all__'


# ============= QUERIES =============

class Query(graphene.ObjectType):
    """Queries principales del sistema"""
    
    # ===== QUERIES PARA INICIO (Carreras y Semestres) =====
    todas_carreras = graphene.List(CarreraType, activa=graphene.Boolean())
    carrera_por_codigo = graphene.Field(CarreraType, codigo=graphene.String(required=True))
    semestres_por_carrera = graphene.List(
        graphene.Int,
        codigo_carrera=graphene.String(required=True)
    )
    
    # ===== QUERIES PARA PERFIL DE ESTUDIANTE =====
    estudiante_por_registro = graphene.Field(
        EstudianteType,
        registro=graphene.String(required=True)
    )
    perfil_estudiante = graphene.Field(
        EstudianteType,
        registro=graphene.String(required=True)
    )
    
    # ===== QUERIES DE MÓDULOS ESPECÍFICOS =====
    fecha_inscripcion_estudiante = graphene.Field(
        graphene.Date,
        registro=graphene.String(required=True),
        codigo_periodo=graphene.String()
    )
    
    estado_bloqueo_estudiante = graphene.Field(
        graphene.Boolean,
        registro=graphene.String(required=True),
        codigo_periodo=graphene.String()
    )
    
    motivo_bloqueo_estudiante = graphene.Field(
        graphene.String,
        registro=graphene.String(required=True),
        codigo_periodo=graphene.String()
    )
    
    materias_habilitadas = graphene.List(
        MateriaCarreraSemestreType,
        registro=graphene.String(required=True)
    )
    
    periodo_habilitado = graphene.Field(PeriodoAcademicoType)
    
    boleta_estudiante = graphene.Field(
        InscripcionType,
        registro=graphene.String(required=True),
        codigo_periodo=graphene.String()
    )
    
    # ===== QUERY COMPLETA DE INSCRIPCIÓN =====
    inscripcion_completa = graphene.Field(
        InscripcionType,
        registro=graphene.String(required=True),
        codigo_periodo=graphene.String()
    )
    
    # ===== QUERIES ADICIONALES =====
    todos_periodos = graphene.List(PeriodoAcademicoType, activo=graphene.Boolean())
    todas_materias = graphene.List(MateriaType)
    
    
    # ============= RESOLVERS =============
    
    def resolve_todas_carreras(self, info, activa=None):
        """Obtiene todas las carreras, opcionalmente filtradas por estado activo"""
        if activa is not None:
            return Carrera.objects.filter(activa=activa)
        return Carrera.objects.all()
    
    def resolve_carrera_por_codigo(self, info, codigo):
        """Obtiene una carrera específica por su código"""
        try:
            return Carrera.objects.get(codigo=codigo)
        except Carrera.DoesNotExist:
            return None
    
    def resolve_semestres_por_carrera(self, info, codigo_carrera):
        """Obtiene la lista de semestres disponibles para una carrera"""
        try:
            carrera = Carrera.objects.get(codigo=codigo_carrera)
            # Retorna una lista de números de semestre (1 hasta duracion_semestres)
            return list(range(1, carrera.duracion_semestres + 1))
        except Carrera.DoesNotExist:
            return []
    
    def resolve_estudiante_por_registro(self, info, registro):
        """Obtiene un estudiante por su registro"""
        try:
            return Estudiante.objects.select_related(
                'carrera_actual', 'plan_estudios'
            ).get(registro=registro)
        except Estudiante.DoesNotExist:
            return None
    
    def resolve_perfil_estudiante(self, info, registro):
        """Obtiene el perfil completo del estudiante (mismo que estudiante_por_registro)"""
        return self.resolve_estudiante_por_registro(info, registro)
    
    def resolve_fecha_inscripcion_estudiante(self, info, registro, codigo_periodo=None):
        """Obtiene la fecha de inscripción asignada al estudiante"""
        try:
            if codigo_periodo:
                periodo = PeriodoAcademico.objects.get(codigo=codigo_periodo)
            else:
                periodo = PeriodoAcademico.objects.filter(activo=True).first()
            
            if not periodo:
                return None
            
            inscripcion = Inscripcion.objects.get(
                estudiante__registro=registro,
                periodo_academico=periodo
            )
            return inscripcion.fecha_inscripcion_asignada
        except (Inscripcion.DoesNotExist, PeriodoAcademico.DoesNotExist):
            return None
    
    def resolve_estado_bloqueo_estudiante(self, info, registro, codigo_periodo=None):
        """Verifica si el estudiante está bloqueado"""
        try:
            if codigo_periodo:
                periodo = PeriodoAcademico.objects.get(codigo=codigo_periodo)
            else:
                periodo = PeriodoAcademico.objects.filter(activo=True).first()
            
            if not periodo:
                return False
            
            inscripcion = Inscripcion.objects.get(
                estudiante__registro=registro,
                periodo_academico=periodo
            )
            return inscripcion.bloqueado
        except (Inscripcion.DoesNotExist, PeriodoAcademico.DoesNotExist):
            return False
    
    def resolve_motivo_bloqueo_estudiante(self, info, registro, codigo_periodo=None):
        """Obtiene el motivo del bloqueo si existe"""
        try:
            if codigo_periodo:
                periodo = PeriodoAcademico.objects.get(codigo=codigo_periodo)
            else:
                periodo = PeriodoAcademico.objects.filter(activo=True).first()
            
            if not periodo:
                return ""
            
            inscripcion = Inscripcion.objects.get(
                estudiante__registro=registro,
                periodo_academico=periodo
            )
            return inscripcion.motivo_bloqueo if inscripcion.bloqueado else ""
        except (Inscripcion.DoesNotExist, PeriodoAcademico.DoesNotExist):
            return ""
    
    def resolve_materias_habilitadas(self, info, registro):
        """Obtiene las materias habilitadas para el estudiante según su carrera y semestre"""
        try:
            estudiante = Estudiante.objects.get(registro=registro)
            materias = MateriaCarreraSemestre.objects.filter(
                carrera=estudiante.carrera_actual,
                plan_estudios=estudiante.plan_estudios,
                semestre=estudiante.semestre_actual,
                habilitada=True
            ).select_related('materia', 'carrera', 'plan_estudios')
            return materias
        except Estudiante.DoesNotExist:
            return []
    
    def resolve_periodo_habilitado(self, info):
        """Obtiene el periodo académico activo actualmente"""
        return PeriodoAcademico.objects.filter(
            activo=True,
            inscripciones_habilitadas=True
        ).first()
    
    def resolve_boleta_estudiante(self, info, registro, codigo_periodo=None):
        """Obtiene la boleta de inscripción del estudiante"""
        try:
            if codigo_periodo:
                periodo = PeriodoAcademico.objects.get(codigo=codigo_periodo)
            else:
                periodo = PeriodoAcademico.objects.filter(activo=True).first()
            
            if not periodo:
                return None
            
            inscripcion = Inscripcion.objects.select_related(
                'estudiante', 'periodo_academico'
            ).prefetch_related('materias_inscritas__materia').get(
                estudiante__registro=registro,
                periodo_academico=periodo,
                boleta_generada=True
            )
            return inscripcion
        except (Inscripcion.DoesNotExist, PeriodoAcademico.DoesNotExist):
            return None
    
    def resolve_inscripcion_completa(self, info, registro, codigo_periodo=None):
        """Obtiene toda la información de inscripción del estudiante"""
        try:
            if codigo_periodo:
                periodo = PeriodoAcademico.objects.get(codigo=codigo_periodo)
            else:
                periodo = PeriodoAcademico.objects.filter(activo=True).first()
            
            if not periodo:
                return None
            
            inscripcion = Inscripcion.objects.select_related(
                'estudiante', 'periodo_academico'
            ).prefetch_related('materias_inscritas__materia').get(
                estudiante__registro=registro,
                periodo_academico=periodo
            )
            return inscripcion
        except (Inscripcion.DoesNotExist, PeriodoAcademico.DoesNotExist):
            return None
    
    def resolve_todos_periodos(self, info, activo=None):
        """Obtiene todos los periodos académicos"""
        if activo is not None:
            return PeriodoAcademico.objects.filter(activo=activo)
        return PeriodoAcademico.objects.all()
    
    def resolve_todas_materias(self, info):
        """Obtiene todas las materias"""
        return Materia.objects.all()


# ============= SCHEMA =============

schema = graphene.Schema(query=Query)
