import graphene
from .types import (
    CarreraType, EstudianteType, EstudianteCarreraType, MateriaCarreraSemestreType, 
    PeriodoAcademicoType, InscripcionType, MateriaType, PlanEstudiosType,
    BloqueoType, PanelEstudianteType, SemestresPorCarreraType, 
    BloqueoEstudianteType, BoletaInscripcionType, FechasInscripcionType,
    OfertaMateriaType
)
from ..services import (
    EstudianteService, InscripcionService, PeriodoAcademicoService,
    CarreraService, BloqueoService, PanelService
)
from django.core.cache import cache
from ..models import Carrera, Materia, Bloqueo

class Query(graphene.ObjectType):
    panel_estudiante = graphene.Field(
        PanelEstudianteType,
        registro=graphene.String(required=True),
        codigo_carrera=graphene.String(),
        description="Información principal del estudiante"
    )

    login_estudiante = graphene.Field(
        EstudianteType,
        registro=graphene.String(required=True),
        contrasena=graphene.String(required=True),
        description="Autenticación de estudiante"
    )
    
    bloqueo_estudiante = graphene.Field(
        BloqueoEstudianteType,
        registro=graphene.String(required=True),
        description="Datos de bloqueos"
    )
    
    semestres_carrera = graphene.Field(
        SemestresPorCarreraType,
        codigo_carrera=graphene.String(required=True),
        description="Semestres disponibles"
    )
    
    boleta_inscripcion = graphene.Field(
        BoletaInscripcionType,
        registro=graphene.String(required=True),
        description="Boleta del estudiante"
    )
    
    ofertas_materia = graphene.List(
        OfertaMateriaType,
        codigo_materia=graphene.String(),
        codigo_carrera=graphene.String(),
        codigo_periodo=graphene.String(),
        turno=graphene.String(),
        tiene_cupo=graphene.Boolean(),
        docente=graphene.String(),
        grupo=graphene.String(),
        description="Ofertas de materias"
    )
    
    
    estudiante_por_registro = graphene.Field(EstudianteType, registro=graphene.String(required=True))
    perfil_estudiante = graphene.Field(EstudianteType, registro=graphene.String(required=True))
    
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
        registro=graphene.String(required=True),
        codigo_carrera=graphene.String()
    )
    periodo_habilitado = graphene.Field(PeriodoAcademicoType)
    boleta_estudiante = graphene.Field(
        InscripcionType,
        registro=graphene.String(required=True),
        codigo_periodo=graphene.String(),
        codigo_carrera=graphene.String()
    )
    inscripcion_completa = graphene.Field(
        InscripcionType,
        registro=graphene.String(required=True),
        codigo_periodo=graphene.String(),
        codigo_carrera=graphene.String()
    )

    todas_carreras = graphene.List(CarreraType, activa=graphene.Boolean(), registro=graphene.String())
    semestres_por_carrera = graphene.List(graphene.Int, codigo_carrera=graphene.String(required=True))
    todos_periodos = graphene.List(PeriodoAcademicoType, activo=graphene.Boolean())
    todas_materias = graphene.List(MateriaType)
    todos_bloqueos = graphene.List(BloqueoType, registro=graphene.String())
    mis_registros = graphene.List(EstudianteType, registro=graphene.String(required=True))
    mis_carreras = graphene.List(EstudianteCarreraType, registro=graphene.String(required=True))
    fechas_inscripcion = graphene.List(FechasInscripcionType, registro=graphene.String(required=True))

    def resolve_panel_estudiante(self, info, registro, codigo_carrera=None):
        return PanelService.get_panel_estudiante(registro, codigo_carrera)
    
    def resolve_login_estudiante(self, info, registro, contrasena):
        estudiante = EstudianteService.authenticate(registro, contrasena)
        if not estudiante:
            raise Exception("Credenciales incorrectas")
        return estudiante
    
    def resolve_bloqueo_estudiante(self, info, registro):
        return BloqueoService.get_info_bloqueo_estudiante(registro)
    
    def resolve_semestres_carrera(self, info, codigo_carrera):
        return CarreraService.get_semestres_por_carrera(codigo_carrera)
    
    def resolve_boleta_inscripcion(self, info, registro):
        return PanelService.get_info_boleta(registro)

    def resolve_ofertas_materia(self, info, **kwargs):
        return InscripcionService.get_ofertas_filtered(**kwargs)

    def resolve_estudiante_por_registro(self, info, registro):
        return EstudianteService.get_by_registro(registro)

    def resolve_perfil_estudiante(self, info, registro):
        return EstudianteService.get_by_registro(registro)

    def resolve_fecha_inscripcion_estudiante(self, info, registro, codigo_periodo=None):
        inscripcion = InscripcionService.get_inscripcion_actual(registro, codigo_periodo)
        return inscripcion.fecha_inscripcion_asignada if inscripcion else None

    def resolve_estado_bloqueo_estudiante(self, info, registro, codigo_periodo=None):
        return BloqueoService.tiene_bloqueos_activos(registro)

    def resolve_motivo_bloqueo_estudiante(self, info, registro, codigo_periodo=None):
        bloqueos = BloqueoService.get_bloqueos_estudiante(registro, solo_activos=True)
        return bloqueos[0].motivo if bloqueos else ""

    def resolve_materias_habilitadas(self, info, registro, codigo_carrera=None):
        return InscripcionService.get_materias_habilitadas(registro, codigo_carrera)

    def resolve_periodo_habilitado(self, info):
        return PeriodoAcademicoService.get_periodo_habilitado_inscripcion()

    def resolve_boleta_estudiante(self, info, registro, codigo_periodo=None, codigo_carrera=None):
        return InscripcionService.get_boleta_estudiante(registro, codigo_periodo, codigo_carrera)

    def resolve_inscripcion_completa(self, info, registro, codigo_periodo=None, codigo_carrera=None):
        return InscripcionService.get_inscripcion_actual(registro, codigo_periodo, codigo_carrera)

    def resolve_todas_carreras(self, info, activa=None, registro=None):
        if registro:
            carreras = EstudianteService.get_carreras_estudiante(registro)
            return [c.carrera for c in carreras]
        return CarreraService.get_todas(activa=activa)

    def resolve_semestres_por_carrera(self, info, codigo_carrera):
        try:
            carrera = Carrera.objects.get(codigo=codigo_carrera)
            return list(range(1, carrera.duracion_semestres + 1))
        except Carrera.DoesNotExist:
            return []

    def resolve_todos_periodos(self, info, activo=None):
        return PeriodoAcademicoService.get_todos_periodos(activo)

    def resolve_todas_materias(self, info):
        return cache.get_or_set(
            'todas_materias_plano',
            lambda: list(Materia.objects.all()),
            timeout=3600
        )
    
    def resolve_todos_bloqueos(self, info, registro=None):
        if registro:
            return BloqueoService.get_bloqueos_estudiante(registro, solo_activos=False)
        return Bloqueo.objects.all()

    def resolve_mis_registros(self, info, registro):
        estudiante = EstudianteService.get_by_registro(registro)
        if estudiante:
            return EstudianteService.get_all_by_documento(estudiante.documento_identidad)
        return []

    def resolve_mis_carreras(self, info, registro):
        return EstudianteService.get_carreras_estudiante(registro)

    def resolve_fechas_inscripcion(self, info, registro):
        inscripcion = InscripcionService.get_inscripcion_actual(registro)
        if not inscripcion:
            return []
        
        return [{
            'fecha_inicio': inscripcion.fecha_inscripcion_asignada.isoformat(),
            'fecha_fin': (inscripcion.fecha_inscripcion_asignada).isoformat(),
            'grupo': 'G1',
            'estado': inscripcion.estado
        }]

