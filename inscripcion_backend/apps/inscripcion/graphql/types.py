import graphene
from graphene_django import DjangoObjectType
from ..models import (
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
    estudiante = graphene.Field('apps.inscripcion.graphql.types.EstudianteType')
    
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



class EstudianteInfoType(graphene.ObjectType):
    registro = graphene.String()
    nombre_completo = graphene.String()
    nombre = graphene.String()
    apellido_paterno = graphene.String()
    apellido_materno = graphene.String()


class CarreraInfoType(graphene.ObjectType):
    codigo = graphene.String()
    nombre = graphene.String()
    tipo = graphene.String()
    facultad = graphene.String()


class PeriodoInfoType(graphene.ObjectType):
    codigo = graphene.String()
    nombre = graphene.String()
    inscripciones_habilitadas = graphene.Boolean()
    fecha_inicio = graphene.String()
    fecha_fin = graphene.String()


class OpcionesDisponiblesType(graphene.ObjectType):
    fechas_inscripcion = graphene.Boolean()
    boleta = graphene.Boolean()
    bloqueo = graphene.Boolean()
    inscripcion = graphene.Boolean()


class InscripcionInfoType(graphene.ObjectType):
    fecha_asignada = graphene.String()
    fecha_realizada = graphene.String()
    estado = graphene.String()
    bloqueado = graphene.Boolean()
    boleta_generada = graphene.Boolean()
    numero_boleta = graphene.String()


class PanelEstudianteType(graphene.ObjectType):
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
    numero = graphene.Int()
    nombre = graphene.String()
    habilitado = graphene.Boolean()


class SemestresPorCarreraType(graphene.ObjectType):
    carrera = graphene.Field(CarreraInfoType)
    semestres = graphene.List(SemestreInfoType)
    total_semestres = graphene.Int()


class BloqueoInfoType(graphene.ObjectType):
    id = graphene.Int()
    tipo = graphene.String()
    motivo = graphene.String()
    fecha_bloqueo = graphene.String()
    fecha_desbloqueo_estimada = graphene.String()
    activo = graphene.Boolean()


class BloqueoEstudianteType(graphene.ObjectType):
    bloqueado = graphene.Boolean()
    bloqueos = graphene.List(BloqueoInfoType)
    puede_inscribirse = graphene.Boolean()
    mensaje = graphene.String()


class MateriaInscritaInfoType(graphene.ObjectType):
    codigo = graphene.String()
    nombre = graphene.String()
    creditos = graphene.Int()
    grupo = graphene.String()
    semestre = graphene.Int()
    horas_teoricas = graphene.Int()
    horas_practicas = graphene.Int()


class BoletaInscripcionType(graphene.ObjectType):
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
    fecha_inicio = graphene.String()
    fecha_fin = graphene.String()
    grupo = graphene.String()
    estado = graphene.String()

# --- NUEVOS TIPOS PARA EL NUEVO SISTEMA ---

class CalendarioType(graphene.ObjectType):
    fecIniIns = graphene.String()
    fecFinIns = graphene.String()
    fecIniRez = graphene.String()
    fecFinRez = graphene.String()
    fecIniAdi = graphene.String()
    fecFinAdi = graphene.String()
    fecIniRet = graphene.String()
    fecFinRet = graphene.String()

class ParametrosGestionType(graphene.ObjectType):
    carrera = graphene.Int()
    plan = graphene.String()
    nombreCarrera = graphene.String()
    lugar = graphene.Int()
    nroSerie = graphene.Int()
    matIns = graphene.String()
    matPendi = graphene.String()

class GestionHabilitadaType(graphene.ObjectType):
    estudiante = graphene.Field(EstudianteInfoType)
    parametros = graphene.Field(ParametrosGestionType)

class CarreraEstudianteListType(graphene.ObjectType):
    carrera = graphene.Int()
    plan = graphene.String()
    nombreCarrera = graphene.String()
    lugar = graphene.Int()
    descripcionLugar = graphene.String()
    nroSerie = graphene.Int()

class ModalidadCarreraType(graphene.ObjectType):
    codTit = graphene.Int()
    codMod = graphene.Int()
    descr = graphene.String()
    matVen = graphene.Int()
    nroMat = graphene.Int()

class CostoInscripcionType(graphene.ObjectType):
    insMontoPag = graphene.Float()
    insEstado = graphene.String()
    rezMontoPag = graphene.Float()
    rezEstado = graphene.String()
    adiMonto = graphene.Float()
    retMonto = graphene.Float()
    nota = graphene.String()

class MatInsType(graphene.ObjectType):
    diaIns = graphene.String()
    horaIns = graphene.String()

class MateriaCupoMinType(graphene.ObjectType):
    sw = graphene.Int()
    sigla = graphene.String()
    grupo = graphene.String()
    nombre = graphene.String()
    lugar = graphene.Int()
    cupoMin = graphene.Int()
    inscritos = graphene.Int()

class MensajeErrorType(graphene.ObjectType):
    codErr = graphene.Int()
    mensaje = graphene.String()

class PuntoPagoType(graphene.ObjectType):
    sucursal = graphene.String()

class TransaccionType(graphene.ObjectType):
    fechaHora = graphene.String()
    gestion = graphene.String()
    carrera = graphene.String()
    transaccion = graphene.String()
    via = graphene.String()

class ModalidadMateriaType(graphene.ObjectType):
    carr = graphene.Int()
    plan = graphene.String()
    sigla = graphene.String()
    grupo = graphene.String()
    modalidad = graphene.Int()

class TramiteAnulacionType(graphene.ObjectType):
    reg = graphene.Int()
    sem = graphene.String()
    ano = graphene.Int()
    carr = graphene.Int()
    plan = graphene.String()
    lugar = graphene.Int()
    modalidad = graphene.Int()
    codMotiv = graphene.Int()
    codProc = graphene.String()
    aB = graphene.String()

class BuscarEstudianteType(graphene.ObjectType):
    nombreCompleto = graphene.String()
    codigoCarrera = graphene.Int()
    planCarrera = graphene.String()

class NombreEstudianteType(graphene.ObjectType):
    type = graphene.String()
    nombre = graphene.String()
class BloqueoExternoType(graphene.ObjectType):
    cobBloq = graphene.String()
    desBloq = graphene.String()
    porroga = graphene.String()
    desbTemp = graphene.String()

class MateriaBoletaType(graphene.ObjectType):
    nsa = graphene.Int()
    cr = graphene.Int()
    sigla = graphene.String()
    grupo = graphene.String()
    materiaNombre = graphene.String(name="materiaNombre")
    horario = graphene.String(name="horario")
    nroReprobado = graphene.Int()
    modalidad = graphene.String()

    def resolve_materiaNombre(self, info):
        return self.get('nombreMateria') or self.get('materiaNombre')

    def resolve_horario(self, info):
        return self.get('horarios') or self.get('horario')

class BoletaInscripcionExternaType(graphene.ObjectType):
    periodo = graphene.String()
    estudiante = graphene.Field(EstudianteInfoType)
    facultad = graphene.Field(CarreraInfoType) # Reuse if similar or create new
    carrera = graphene.Field(CarreraEstudianteListType)
    materias = graphene.List(MateriaBoletaType)

class MateriaOfertaType(graphene.ObjectType):
    sigla = graphene.String()
    nsa = graphene.Int()
    materiaNombre = graphene.String(name="materiaNombre")
    materiaCodigo = graphene.String(name="materiaCodigo")
    semestre = graphene.Int()
    ok = graphene.Int()

    def resolve_materiaNombre(self, info):
        return self.get('nombreMateria') or self.get('materiaNombre')

    def resolve_materiaCodigo(self, info):
        return self.get('codMat') or self.get('materiaCodigo')

class MofertaGrupoType(graphene.ObjectType):
    grupo = graphene.String()
    docente = graphene.String()
    cupo = graphene.Int()
    cuposDisponibles = graphene.Int(name="cuposDisponibles")
    swHab = graphene.Int()
    horario = graphene.String(name="horario")

    def resolve_cuposDisponibles(self, info):
        return self.get('cupo') or self.get('cuposDisponibles')

    def resolve_horario(self, info):
        return self.get('horarios') or self.get('horario')

class MofertaType(graphene.ObjectType):
    materiaCodigo = graphene.String(name="materiaCodigo")
    codMat = graphene.String()
    grupo = graphene.String()
    docente = graphene.String()
    cupo = graphene.Int()
    cupoActual = graphene.Int(name="cupoActual")
    cuposDisponibles = graphene.Int(name="cuposDisponibles")
    swHab = graphene.Int()
    horario = graphene.String(name="horario")
    horarios = graphene.String()
    modalidad = graphene.String()
    materiaNombre = graphene.String(name="materiaNombre")
    nombreMateria = graphene.String()
    semestre = graphene.Int()

    def resolve_materiaCodigo(self, info):
        return self.get('codMat') or self.get('materiaCodigo')

    def resolve_cuposDisponibles(self, info):
        return self.get('cupo') or self.get('cuposDisponibles')

    def resolve_horario(self, info):
        return self.get('horarios') or self.get('horario')

    def resolve_materiaNombre(self, info):
        return self.get('nombreMateria') or self.get('materiaNombre')

class MateriaInscritaType(graphene.ObjectType):
    nsa = graphene.Int()
    materiaCodigo = graphene.Int(name="materiaCodigo")
    sigla = graphene.String()
    materiaNombre = graphene.String(name="materiaNombre")
    grupo = graphene.String()

    def resolve_materiaCodigo(self, info):
        return self.get('codMat') or self.get('materiaCodigo')

    def resolve_materiaNombre(self, info):
        return self.get('nombreMateria') or self.get('materiaNombre')

class TransaccionType(graphene.ObjectType):
    fechaHora = graphene.String()
    gestion = graphene.String()
    carrera = graphene.String()
    transaccion = graphene.String()
    via = graphene.String()

class ModalidadMateriaSeleccionadaType(graphene.ObjectType):
    carr = graphene.Int()
    plan = graphene.String()
    sigla = graphene.String()
    grupo = graphene.String()
    modalidad = graphene.String()

class MensajeErrorInscripcionType(graphene.ObjectType):
    codErr = graphene.Int()
    mensaje = graphene.String()
