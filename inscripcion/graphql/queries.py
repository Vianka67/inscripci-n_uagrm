import graphene
from .types import (
    CarreraType, EstudianteType, MateriaCarreraSemestreType, 
    PeriodoAcademicoType, InscripcionType, MateriaType, PlanEstudiosType,
    BloqueoType, PanelEstudianteType, SemestresPorCarreraType, 
    BloqueoEstudianteType, BoletaInscripcionType
)
from ..services import (
    EstudianteService, InscripcionService, PeriodoAcademicoService,
    CarreraService, BloqueoService, PanelService
)
from ..models import Carrera, Materia

class Query(graphene.ObjectType):
    # ========== QUERIES PRINCIPALES (NUEVAS) ==========
    
    # Panel completo del estudiante
    panel_estudiante = graphene.Field(
        PanelEstudianteType,
        registro=graphene.String(required=True),
        description="Obtiene toda la información del panel del estudiante en una sola llamada"
    )
    
    # Información de bloqueos
    bloqueo_estudiante = graphene.Field(
        BloqueoEstudianteType,
        registro=graphene.String(required=True),
        description="Obtiene información completa de bloqueos del estudiante"
    )
    
    # Semestres por carrera (respuesta estructurada)
    semestres_carrera = graphene.Field(
        SemestresPorCarreraType,
        codigo_carrera=graphene.String(required=True),
        description="Obtiene los semestres disponibles para una carrera"
    )
    
    # Boleta de inscripción completa
    boleta_inscripcion = graphene.Field(
        BoletaInscripcionType,
        registro=graphene.String(required=True),
        description="Obtiene la boleta de inscripción completa del estudiante"
    )
    
    # ========== QUERIES EXISTENTES (COMPATIBILIDAD) ==========
    
    # --- Estudiante y Perfil ---
    estudiante_por_registro = graphene.Field(EstudianteType, registro=graphene.String(required=True))
    perfil_estudiante = graphene.Field(EstudianteType, registro=graphene.String(required=True))
    
    # --- Estado e Inscripción ---
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
    
    # --- Académico ---
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
    inscripcion_completa = graphene.Field(
        InscripcionType,
        registro=graphene.String(required=True),
        codigo_periodo=graphene.String()
    )

    # --- Catálogos y Utilidades ---
    todas_carreras = graphene.List(CarreraType, activa=graphene.Boolean())
    semestres_por_carrera = graphene.List(graphene.Int, codigo_carrera=graphene.String(required=True))
    todos_periodos = graphene.List(PeriodoAcademicoType, activo=graphene.Boolean())
    todas_materias = graphene.List(MateriaType)
    todos_bloqueos = graphene.List(BloqueoType, registro=graphene.String())

    # ================= RESOLVERS NUEVOS =================
    
    def resolve_panel_estudiante(self, info, registro):
        """Resolver para obtener el panel completo del estudiante"""
        return PanelService.get_panel_estudiante(registro)
    
    def resolve_bloqueo_estudiante(self, info, registro):
        """Resolver para obtener información de bloqueos"""
        return BloqueoService.get_info_bloqueo_estudiante(registro)
    
    def resolve_semestres_carrera(self, info, codigo_carrera):
        """Resolver para obtener semestres por carrera"""
        return CarreraService.get_semestres_por_carrera(codigo_carrera)
    
    def resolve_boleta_inscripcion(self, info, registro):
        """Resolver para obtener boleta de inscripción"""
        return PanelService.get_info_boleta(registro)

    # ================= RESOLVERS EXISTENTES =================
    
    def resolve_estudiante_por_registro(self, info, registro):
        return EstudianteService.get_by_registro(registro)

    def resolve_perfil_estudiante(self, info, registro):
        return EstudianteService.get_by_registro(registro)

    def resolve_fecha_inscripcion_estudiante(self, info, registro, codigo_periodo=None):
        inscripcion = InscripcionService.get_inscripcion_actual(registro, codigo_periodo)
        return inscripcion.fecha_inscripcion_asignada if inscripcion else None

    def resolve_estado_bloqueo_estudiante(self, info, registro, codigo_periodo=None):
        # Ahora usa el nuevo servicio de bloqueos
        return BloqueoService.tiene_bloqueos_activos(registro)

    def resolve_motivo_bloqueo_estudiante(self, info, registro, codigo_periodo=None):
        # Obtiene el primer bloqueo activo
        bloqueos = BloqueoService.get_bloqueos_estudiante(registro, solo_activos=True)
        return bloqueos[0].motivo if bloqueos else ""

    def resolve_materias_habilitadas(self, info, registro):
        return InscripcionService.get_materias_habilitadas(registro)

    def resolve_periodo_habilitado(self, info):
        return PeriodoAcademicoService.get_periodo_habilitado_inscripcion()

    def resolve_boleta_estudiante(self, info, registro, codigo_periodo=None):
        return InscripcionService.get_boleta_estudiante(registro, codigo_periodo)

    def resolve_inscripcion_completa(self, info, registro, codigo_periodo=None):
        return InscripcionService.get_inscripcion_actual(registro, codigo_periodo)

    def resolve_todas_carreras(self, info, activa=None):
        if activa is not None:
            return Carrera.objects.filter(activa=activa)
        return Carrera.objects.all()

    def resolve_semestres_por_carrera(self, info, codigo_carrera):
        """Retorna lista simple de números de semestres (compatibilidad)"""
        try:
            carrera = Carrera.objects.get(codigo=codigo_carrera)
            return list(range(1, carrera.duracion_semestres + 1))
        except Carrera.DoesNotExist:
            return []

    def resolve_todos_periodos(self, info, activo=None):
        return PeriodoAcademicoService.get_todos_periodos(activo)

    def resolve_todas_materias(self, info):
        return Materia.objects.all()
    
    def resolve_todos_bloqueos(self, info, registro=None):
        """Obtiene todos los bloqueos, opcionalmente filtrados por estudiante"""
        if registro:
            return BloqueoService.get_bloqueos_estudiante(registro, solo_activos=False)
        from ..models import Bloqueo
        return Bloqueo.objects.all()

