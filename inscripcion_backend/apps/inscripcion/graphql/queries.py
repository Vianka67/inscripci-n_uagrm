import graphene
from .types import (
    CarreraType, EstudianteType, EstudianteCarreraType, MateriaCarreraSemestreType, 
    PeriodoAcademicoType, InscripcionType, MateriaType, PlanEstudiosType,
    BloqueoType, PanelEstudianteType, SemestresPorCarreraType, 
    BloqueoEstudianteType, BoletaInscripcionType, FechasInscripcionType,
    OfertaMateriaType, BuscarEstudianteType, NombreEstudianteType,
    BloqueoExternoType, BoletaInscripcionExternaType, MateriaOfertaType,
    MofertaGrupoType, MofertaType, MateriaInscritaType, TransaccionType,
    ModalidadMateriaSeleccionadaType, MensajeErrorInscripcionType
)
from ..services import (
    EstudianteService, InscripcionService, PeriodoAcademicoService,
    CarreraService, BloqueoService, PanelService, ExternalApiService
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
        registro=graphene.String(),
        proceso=graphene.String(),
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
        # 1. Obtener bloqueos locales
        bloqueos_locales = BloqueoService.get_bloqueos_estudiante(registro, solo_activos=True)
        
        # 2. Obtener bloqueos de Informix
        query = """
        query($registro: Int!) {
          bloqueo(registro: $registro) {
            cobBloq desBloq porroga desbTemp
          }
        }
        """
        variables = {"registro": int(registro)}
        data = ExternalApiService.query(query, variables)
        bloqueos_ext = data.get("bloqueo", []) if data else []
        
        # 3. Mapear y combinar
        bloqueos_mapeados = []
        for b in bloqueos_locales:
            bloqueos_mapeados.append({
                'motivo': f"[LOCAL] {b.motivo}",
                'tipo': b.tipo,
                'fecha_bloqueo': b.fecha_bloqueo.isoformat()
            })
            
        for b in bloqueos_ext:
            bloqueos_mapeados.append({
                'motivo': f"[{b.get('cobBloq')}] {b.get('desBloq')}",
                'tipo': b.get('cobBloq'),
                'fecha_bloqueo': b.get('porroga') or 'Pendiente'
            })
            
        return {
            'bloqueado': len(bloqueos_mapeados) > 0,
            'bloqueos': bloqueos_mapeados,
            'puede_inscribirse': len(bloqueos_mapeados) == 0,
            'mensaje': "Su cuenta presenta trámites pendientes." if bloqueos_mapeados else "Cuenta habilitada"
        }
    
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
        # Consulta directa
        query = "query($r: Int!) { bloqueo(registro: $r) { cobBloq } }"
        data = ExternalApiService.query(query, {"r": int(registro)})
        bloqueos = data.get("bloqueo", []) if data else []
        return len(bloqueos) > 0

    def resolve_motivo_bloqueo_estudiante(self, info, registro, codigo_periodo=None):
        query = "query($r: Int!) { bloqueo(registro: $r) { cobBloq desBloq } }"
        data = ExternalApiService.query(query, {"r": int(registro)})
        bloqueos = data.get("bloqueo", []) if data else []
        if bloqueos:
            b = bloqueos[0]
            return f"[{b.get('cobBloq')}] {b.get('desBloq')}"
        return ""

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

    # --- NUEVAS QUERIES DEL NUEVO SISTEMA ---

    calendario = graphene.Field(
        'apps.inscripcion.graphql.types.CalendarioType',
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True)
    )

    gestion_habilitada = graphene.Field(
        'apps.inscripcion.graphql.types.GestionHabilitadaType',
        registro=graphene.Int(required=True),
        proceso=graphene.String(required=True)
    )

    listar_carreras = graphene.List(
        'apps.inscripcion.graphql.types.CarreraEstudianteListType',
        registro=graphene.Int(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True)
    )

    listar_carreras2 = graphene.List(
        'apps.inscripcion.graphql.types.CarreraEstudianteListType',
        registro=graphene.Int(required=True)
    )

    modalidad_carrera = graphene.Field(
        'apps.inscripcion.graphql.types.ModalidadCarreraType',
        registro=graphene.Int(required=True),
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True),
        lugar=graphene.Int(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True)
    )

    costo_inscripcion = graphene.Field(
        'apps.inscripcion.graphql.types.CostoInscripcionType',
        nroSerie=graphene.Int(required=True)
    )

    mat_ins = graphene.Field(
        'apps.inscripcion.graphql.types.MatInsType',
        nroSerie=graphene.Int(required=True)
    )

    buscar_estudiante = graphene.Field(
        BuscarEstudianteType,
        registro=graphene.Int(required=True)
    )

    nombre_estudiante = graphene.Field(
        NombreEstudianteType,
        registro=graphene.Int(required=True)
    )

    materias_cupo_min = graphene.List(
        'apps.inscripcion.graphql.types.MateriaCupoMinType',
        registro=graphene.Int(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True),
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True)
    )

    all_moferta = graphene.List(
        MofertaType,
        registro=graphene.Int(required=True),
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True),
        lugar=graphene.Int(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True)
    )

    materia_oferta = graphene.List(
        MateriaOfertaType,
        registro=graphene.Int(required=True),
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True),
        lugar=graphene.Int(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True),
        nroSerie=graphene.Int(required=True),
        proceso=graphene.String(required=True)
    )

    moferta_grupo = graphene.List(
        MofertaGrupoType,
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True),
        lugar=graphene.Int(required=True),
        sigla=graphene.String(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True)
    )

    bloqueo = graphene.List(
        BloqueoExternoType,
        registro=graphene.Int(required=True)
    )

    boleta_inscripcion_externa = graphene.Field(
        BoletaInscripcionExternaType,
        registro=graphene.Int(required=True),
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True)
    )

    validar_fase_1 = graphene.Field(
        graphene.Boolean,
        registro=graphene.Int(required=True),
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True),
        lugar=graphene.Int(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True),
        proceso=graphene.String(required=True),
        titulo=graphene.Int(required=True),
        modalidad=graphene.Int(required=True)
    )

    validar_procesado = graphene.Field(
        graphene.Boolean,
        registro=graphene.Int(required=True),
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True),
        lugar=graphene.Int(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True),
        proceso=graphene.String(required=True)
    )

    materia_inscrita = graphene.List(
        'apps.inscripcion.graphql.types.MateriaInscritaType',
        registro=graphene.Int(required=True),
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True),
        lugar=graphene.Int(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True)
    )

    recalcular = graphene.Field(
        graphene.Boolean,
        registro=graphene.Int(required=True),
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True),
        lugar=graphene.Int(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True)
    )

    transacciones = graphene.List(
        'apps.inscripcion.graphql.types.TransaccionType',
        registro=graphene.Int(),
        carr=graphene.Int(),
        plan=graphene.String(),
        sem=graphene.String(),
        ano=graphene.Int(),
        nroSerie=graphene.Int() # Agregar nroSerie para compatibilidad con el frontend
    )

    modalidad_materia_seleccionada = graphene.List(
        'apps.inscripcion.graphql.types.ModalidadMateriaSeleccionadaType',
        reg=graphene.Int(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True),
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True)
    )

    mensaje_error_inscripcion = graphene.Field(
        'apps.inscripcion.graphql.types.MensajeErrorInscripcionType',
        registro=graphene.Int(required=True),
        carr=graphene.Int(required=True),
        plan=graphene.String(required=True),
        sem=graphene.String(required=True),
        ano=graphene.Int(required=True)
    )

    def resolve_calendario(self, info, carr, plan, sem, ano):
        # Datos ficticios de calendario
        return {
            'fecIniIns': '2026-05-01',
            'fecFinIns': '2026-05-15',
            'fecIniRez': '2026-05-16',
            'fecFinRez': '2026-05-20',
            'fecIniAdi': '2026-05-21',
            'fecFinAdi': '2026-05-25',
            'fecIniRet': '2026-05-26',
            'fecFinRet': '2026-05-30',
        }

    def resolve_gestion_habilitada(self, info, registro, proceso):
        query = """
        query($registro: Int!, $proceso: String!) {
          gestionHabilitada(registro: $registro, proceso: $proceso) {
            estudiante { nombre nroCi lugCi }
            parametros { carrera plan nombreCarrera lugar nroSerie matIns matPendi }
          }
        }
        """
        variables = {"registro": registro, "proceso": proceso}
        data = ExternalApiService.query(query, variables)
        return data.get("gestionHabilitada") if data else None

    def resolve_listar_carreras(self, info, registro, sem, ano):
        query = """
        query($registro: Int!, $sem: String!, $ano: Int!) {
          listarCarreras(registro: $registro, sem: $sem, ano: $ano) {
            carrera plan nombreCarrera lugar descripcionLugar nroSerie
          }
        }
        """
        variables = {"registro": registro, "sem": sem, "ano": ano}
        data = ExternalApiService.query(query, variables)
        return data.get("listarCarreras") if data else []
        
    def resolve_listar_carreras2(self, info, registro):
        query = """
        query($registro: Int!) {
          listarCarreras2(registro: $registro) {
            carrera plan nombreCarrera lugar descripcionLugar
          }
        }
        """
        variables = {"registro": registro}
        data = ExternalApiService.query(query, variables)
        return data.get("listarCarreras2") if data else []

    def resolve_modalidad_carrera(self, info, registro, carr, plan, lugar, sem, ano):
        query = """
        query($registro: Int!, $carr: Int!, $plan: String!, $lugar: Int!, $sem: String!, $ano: Int!) {
          modalidadCarrera(registro: $registro, carr: $carr, plan: $plan, lugar: $lugar, sem: $sem, ano: $ano) {
            codTit codMod descr matVen nroMat
          }
        }
        """
        variables = {"registro": registro, "carr": carr, "plan": plan, "lugar": lugar, "sem": sem, "ano": ano}
        data = ExternalApiService.query(query, variables)
        return data.get("modalidadCarrera") if data else None

    def resolve_costo_inscripcion(self, info, nroSerie):
        query = """
        query($nroSerie: Int!) {
          costoInscripcion(nroSerie: $nroSerie) {
            insMontoPag insEstado rezMontoPag rezEstado adiMonto retMonto nota
          }
        }
        """
        variables = {"nroSerie": nroSerie}
        data = ExternalApiService.query(query, variables)
        return data.get("costoInscripcion") if data else None

    def resolve_mat_ins(self, info, nroSerie):
        query = """
        query($nroSerie: Int!) {
          matIns(nroSerie: $nroSerie) {
            diaIns horaIns
          }
        }
        """
        variables = {"nroSerie": nroSerie}
        data = ExternalApiService.query(query, variables)
        return data.get("matIns") if data else None

    def resolve_materias_cupo_min(self, info, registro, sem, ano, carr, plan):
        query = """
        query($registro: Int!, $sem: String!, $ano: Int!, $carr: Int!, $plan: String!) {
          materiasCupoMin(registro: $registro, sem: $sem, ano: $ano, carr: $carr, plan: $plan) {
            sw sigla grupo nombre lugar cupoMin inscritos
          }
        }
        """
        variables = {"registro": registro, "sem": sem, "ano": ano, "carr": carr, "plan": plan}
        data = ExternalApiService.query(query, variables)
        return data.get("materiasCupoMin") if data else []

    def resolve_buscar_estudiante(self, info, registro):
        query = """
        query($registro: Int!) {
          buscarEstudiante(registro: $registro) {
            nombreCompleto codigoCarrera planCarrera
          }
        }
        """
        variables = {"registro": registro}
        data = ExternalApiService.query(query, variables)
        return data.get("buscarEstudiante") if data else None

    def resolve_nombre_estudiante(self, info, registro):
        query = """
        query($registro: Int!) {
          nombreEstudiante(registro: $registro) {
            type nombre
          }
        }
        """
        variables = {"registro": registro}
        data = ExternalApiService.query(query, variables)
        return data.get("nombreEstudiante") if data else None

    def resolve_all_moferta(self, info, registro, carr, plan, lugar, sem, ano):
        query = """
        query($registro: Int!, $carr: Int!, $plan: String!, $lugar: Int!, $sem: String!, $ano: Int!) {
          allMoferta(registro: $registro, carr: $carr, plan: $plan, lugar: $lugar, sem: $sem, ano: $ano) {
            codMat grupo docente cupo swHab horarios modalidad
          }
        }
        """
        variables = {"registro": registro, "carr": carr, "plan": plan, "lugar": lugar, "sem": sem, "ano": ano}
        try:
            data = ExternalApiService.query(query, variables)
            result = data.get("allMoferta") if data else None
            if result: # Si hay datos reales, los usamos
                return result
        except Exception:
            pass
        
        # --- Datos ficticios (mock) para pruebas ---
        return [
            {'codMat': 'INF-110', 'nombreMateria': 'INTRODUCCION A LA INFORMATICA', 'semestre': 1, 'grupo': 'A', 'docente': 'Ing. Carlos Mendoza', 'cupo': 30, 'cupoActual': 15, 'swHab': '1', 'horarios': 'LU-MI 07:00-09:15', 'modalidad': 'PRESENCIAL'},
            {'codMat': 'INF-110', 'nombreMateria': 'INTRODUCCION A LA INFORMATICA', 'semestre': 1, 'grupo': 'B', 'docente': 'Ing. Laura Perez', 'cupo': 25, 'cupoActual': 25, 'swHab': '1', 'horarios': 'MA-JU 09:15-11:30', 'modalidad': 'PRESENCIAL'},
            {'codMat': 'MAT-101', 'nombreMateria': 'CALCULO I', 'semestre': 1, 'grupo': 'A', 'docente': 'Lic. Roberto Suarez', 'cupo': 35, 'cupoActual': 10, 'swHab': '1', 'horarios': 'LU-MI 11:30-13:45', 'modalidad': 'PRESENCIAL'},
            {'codMat': 'MAT-101', 'nombreMateria': 'CALCULO I', 'semestre': 1, 'grupo': 'B', 'docente': 'Ing. Maria Torres', 'cupo': 0,  'cupoActual': 0, 'swHab': '1', 'horarios': 'MA-JU 14:00-16:15', 'modalidad': 'VIRTUAL'},
            {'codMat': 'FIS-101', 'nombreMateria': 'FISICA I', 'semestre': 2, 'grupo': 'A', 'docente': 'Dr. Pedro Vaca', 'cupo': 20, 'cupoActual': 5, 'swHab': '1', 'horarios': 'VI 07:00-11:00', 'modalidad': 'PRESENCIAL'},
            {'codMat': 'FIS-101', 'nombreMateria': 'FISICA I', 'semestre': 2, 'grupo': 'B', 'docente': 'Por designar', 'cupo': 15, 'cupoActual': 0, 'swHab': '1', 'horarios': 'SA 07:00-11:00', 'modalidad': 'PRESENCIAL'},
            {'codMat': 'LIN-100', 'nombreMateria': 'LENGUAJE Y COMUNICACION', 'semestre': 2, 'grupo': 'A', 'docente': 'Lic. Ana Gutierrez', 'cupo': 28, 'cupoActual': 14, 'swHab': '1', 'horarios': 'LU 14:00-17:00', 'modalidad': 'PRESENCIAL'},
            {'codMat': 'COM-200', 'nombreMateria': 'COMUNICACION DE DATOS I', 'semestre': 3, 'grupo': 'A', 'docente': 'Ing. Jose Flores', 'cupo': 22, 'cupoActual': 20, 'swHab': '1', 'horarios': 'MI-VI 07:00-09:15', 'modalidad': 'PRESENCIAL'},
        ]

    def resolve_materia_oferta(self, info, registro, carr, plan, lugar, sem, ano, nroSerie, proceso):
        query = """
        query($registro: Int!, $carr: Int!, $plan: String!, $lugar: Int!, $sem: String!, $ano: Int!, $nroSerie: Int!, $proceso: String!) {
          materiaOferta(registro: $registro, carr: $carr, plan: $plan, lugar: $lugar, sem: $sem, ano: $ano, nroSerie: $nroSerie, proceso: $proceso) {
            sigla nsa nombreMateria codMat ok
          }
        }
        """
        variables = {"registro": registro, "carr": carr, "plan": plan, "lugar": lugar, "sem": sem, "ano": ano, "nroSerie": nroSerie, "proceso": proceso}
        try:
            data = ExternalApiService.query(query, variables)
            result = data.get("materiaOferta") if data else None
            if result: # Si hay datos reales, los usamos
                return result
        except Exception:
            pass
        
        # --- Datos ficticios (mock) para Materias Habilitadas ---
        return [
            {'sigla': 'INF-110', 'nsa': 1, 'nombreMateria': 'INTRODUCCION A LA INFORMATICA', 'codMat': 'INF-110', 'semestre': 1, 'ok': True},
            {'sigla': 'MAT-101', 'nsa': 2, 'nombreMateria': 'CALCULO I',                      'codMat': 'MAT-101', 'semestre': 1, 'ok': True},
            {'sigla': 'FIS-101', 'nsa': 3, 'nombreMateria': 'FISICA I',                        'codMat': 'FIS-101', 'semestre': 2, 'ok': True},
            {'sigla': 'LIN-100', 'nsa': 4, 'nombreMateria': 'LENGUAJE Y COMUNICACION',         'codMat': 'LIN-100', 'semestre': 2, 'ok': True},
            {'sigla': 'COM-200', 'nsa': 5, 'nombreMateria': 'COMUNICACION DE DATOS I',         'codMat': 'COM-200', 'semestre': 3, 'ok': True},
            {'sigla': 'ALG-101', 'nsa': 6, 'nombreMateria': 'ALGEBRA LINEAL',                  'codMat': 'ALG-101', 'semestre': 3, 'ok': True},
            {'sigla': 'PRO-101', 'nsa': 7, 'nombreMateria': 'PROGRAMACION I',                  'codMat': 'PRO-101', 'semestre': 4, 'ok': True},
        ]

    def resolve_moferta_grupo(self, info, carr, plan, lugar, sigla, sem, ano):
        query = """
        query($carr: Int!, $plan: String!, $lugar: Int!, $sigla: String!, $sem: String!, $ano: Int!) {
          mofertaGrupo(carr: $carr, plan: $plan, lugar: $lugar, sigla: $sigla, sem: $sem, ano: $ano) {
            grupo docente cupo swHab horarios
          }
        }
        """
        variables = {"carr": carr, "plan": plan, "lugar": lugar, "sigla": sigla, "sem": sem, "ano": ano}
        try:
            data = ExternalApiService.query(query, variables)
            result = data.get("mofertaGrupo") if data else None
            if result is not None:
                return result
        except Exception:
            pass
        # --- Datos ficticios por sigla ---
        mock_grupos = {
            'INF-110': [{'grupo': 'A', 'docente': 'Ing. Carlos Mendoza', 'cupo': 30, 'swHab': '1', 'horarios': 'LU-MI 07:00-09:15'}, {'grupo': 'B', 'docente': 'Ing. Laura Perez', 'cupo': 25, 'swHab': '1', 'horarios': 'MA-JU 09:15-11:30'}],
            'MAT-101': [{'grupo': 'A', 'docente': 'Lic. Roberto Suarez', 'cupo': 35, 'swHab': '1', 'horarios': 'LU-MI 11:30-13:45'}, {'grupo': 'B', 'docente': 'Ing. Maria Torres', 'cupo': 0, 'swHab': '1', 'horarios': 'MA-JU 14:00-16:15'}],
            'FIS-101': [{'grupo': 'A', 'docente': 'Dr. Pedro Vaca', 'cupo': 20, 'swHab': '1', 'horarios': 'VI 07:00-11:00'}],
        }
        return mock_grupos.get(sigla, [{'grupo': 'A', 'docente': 'Por designar', 'cupo': 15, 'swHab': '1', 'horarios': 'LU 07:00-09:15'}])

    def resolve_bloqueo(self, info, registro):
        # 1. Locales
        locales = BloqueoService.get_bloqueos_estudiante(str(registro), solo_activos=True)
        resp_locales = [{
            'cobBloq': b.tipo,
            'desBloq': b.motivo,
            'porroga': b.fecha_bloqueo.isoformat(),
            'desbTemp': ''
        } for b in locales]

        # 2. Externos
        query = "query($r: Int!) { bloqueo(registro: $r) { cobBloq desBloq porroga desbTemp } }"
        data = ExternalApiService.query(query, {"r": int(registro)})
        externos = data.get("bloqueo", []) if data else []
        
        return resp_locales + externos

    def resolve_boleta_inscripcion_externa(self, info, registro, carr, plan, sem, ano):
        # Datos ficticios de la boleta de inscripción
        return {
            'periodo': f'{sem}-{ano}',
            'estudiante': { 'registro': str(registro), 'nombre': 'JUAN PEREZ LOPEZ' },
            'facultad': { 'nombre': 'CIENCIAS EXACTAS', 'codigo': 'FAC-10' },
            'carrera': { 'codigo': carr, 'plan': plan, 'nombre': 'INGENIERÍA DE SISTEMAS', 'lugar': 1 },
            'materias': [
                { 'nsa': 1, 'cr': 4, 'sigla': 'INF-110', 'grupo': 'SA', 'nombreMateria': 'INTRODUCCION A LA INFORMATICA', 'horarios': 'LU 07:00-09:15', 'nroReprobado': 0, 'modalidad': 'PRESENCIAL' },
                { 'nsa': 2, 'cr': 5, 'sigla': 'MAT-101', 'grupo': 'Z1', 'nombreMateria': 'CALCULO I', 'horarios': 'MA 09:15-11:30', 'nroReprobado': 1, 'modalidad': 'VIRTUAL' }
            ]
        }

    def resolve_validar_fase_1(self, info, registro, carr, plan, lugar, sem, ano, proceso, titulo, modalidad):
        query = """
        query($registro: Int!, $carr: Int!, $plan: String!, $lugar: Int!, $sem: String!, $ano: Int!, $proceso: String!, $titulo: Int!, $modalidad: Int!) {
          validarFase1(registro: $registro, carr: $carr, plan: $plan, lugar: $lugar, sem: $sem, ano: $ano, proceso: $proceso, titulo: $titulo, modalidad: $modalidad)
        }
        """
        variables = {
            "registro": registro, "carr": carr, "plan": plan, "lugar": lugar, 
            "sem": sem, "ano": ano, "proceso": proceso, "titulo": titulo, "modalidad": modalidad
        }
        data = ExternalApiService.query(query, variables)
        return data.get("validarFase1") if data else False

    def resolve_validar_procesado(self, info, registro, carr, plan, lugar, sem, ano, proceso):
        query = """
        query($registro: Int!, $carr: Int!, $plan: String!, $lugar: Int!, $sem: String!, $ano: Int!, $proceso: String!) {
          validarProcesado(registro: $registro, carr: $carr, plan: $plan, lugar: $lugar, sem: $sem, ano: $ano, proceso: $proceso)
        }
        """
        variables = {
            "registro": registro, "carr": carr, "plan": plan, "lugar": lugar, 
            "sem": sem, "ano": ano, "proceso": proceso
        }
        data = ExternalApiService.query(query, variables)
        return data.get("validarProcesado") if data else False

    def resolve_materia_inscrita(self, info, registro, carr, plan, lugar, sem, ano):
        query = """
        query($registro: Int!, $carr: Int!, $plan: String!, $lugar: Int!, $sem: String!, $ano: Int!) {
          materiaInscrita(registro: $registro, carr: $carr, plan: $plan, lugar: $lugar, sem: $sem, ano: $ano) {
            nsa codMat sigla nombreMateria grupo
          }
        }
        """
        variables = {"registro": registro, "carr": carr, "plan": plan, "lugar": lugar, "sem": sem, "ano": ano}
        data = ExternalApiService.query(query, variables)
        return data.get("materiaInscrita") if data else []

    def resolve_recalcular(self, info, registro, carr, plan, lugar, sem, ano):
        query = """
        query($registro: Int!, $carr: Int!, $plan: String!, $lugar: Int!, $sem: String!, $ano: Int!) {
          recalcular(registro: $registro, carr: $carr, plan: $plan, lugar: $lugar, sem: $sem, ano: $ano)
        }
        """
        variables = {"registro": registro, "carr": carr, "plan": plan, "lugar": lugar, "sem": sem, "ano": ano}
        data = ExternalApiService.query(query, variables)
        return data.get("recalcular") if data else False

    def resolve_transacciones(self, info, registro, carr, plan, sem, ano):
        # Historial ficticio de transacciones
        return [
            {
                'fechaHora': '2026-04-25 10:30',
                'gestion': '1-2026',
                'carrera': 'ING. SISTEMAS',
                'transaccion': 'INSCRIPCIÓN',
                'via': 'WEB'
            },
            {
                'fechaHora': '2026-04-20 15:45',
                'gestion': '1-2026',
                'carrera': 'ING. SISTEMAS',
                'transaccion': 'PAGO MATRÍCULA',
                'via': 'BANCO'
            }
        ]

    def resolve_modalidad_materia_seleccionada(self, info, reg, sem, ano, carr, plan):
        query = """
        query($reg: Int!, $sem: String!, $ano: Int!, $carr: Int!, $plan: String!) {
          modalidadMateriaSeleccionada(reg: $reg, sem: $sem, ano: $ano, carr: $carr, plan: $plan) {
            carr plan sigla grupo modalidad
          }
        }
        """
        variables = {"reg": reg, "sem": sem, "ano": ano, "carr": carr, "plan": plan}
        data = ExternalApiService.query(query, variables)
        return data.get("modalidadMateriaSeleccionada") if data else []

    def resolve_mensaje_error_inscripcion(self, info, registro, carr, plan, sem, ano):
        query = """
        query($registro: Int!, $carr: Int!, $plan: String!, $sem: String!, $ano: Int!) {
          mensajeErrorInscripcion(registro: $registro, carr: $carr, plan: $plan, sem: $sem, ano: $ano) {
            codErr mensaje
          }
        }
        """
        variables = {"registro": registro, "carr": carr, "plan": plan, "sem": sem, "ano": ano}
        data = ExternalApiService.query(query, variables)
        return data.get("mensajeErrorInscripcion") if data else []

    def resolve_costos_inscripcion(self, info, registro, carr, plan, sem, ano):
        # Datos ficticios de costos/pagos
        return {
            'insMontoPag': 150.0,
            'insEstado': 'PAGADO',
            'rezMontoPag': 50.0,
            'rezEstado': 'PENDIENTE',
            'adiMonto': 25.0,
            'retMonto': 0.0,
            'nota': 'Cuenta con beca alimentaria activa'
        }


    obtener_tramites_anulacion = graphene.List(
        'apps.inscripcion.graphql.types.TramiteAnulacionType',
        reg=graphene.Int(required=True)
    )

    def resolve_obtener_tramites_anulacion(self, info, reg):
        # Datos ficticios para pruebas de interfaz
        mock_tramites = [
            {
                'reg': reg,
                'sem': '1',
                'ano': 2026,
                'carr': 187,
                'plan': '2020',
                'lugar': 1,
                'modalidad': 1,
                'codMotiv': 5,
                'codProc': 'ANULACION SEMESTRE',
                'aB': 'A'
            },
            {
                'reg': reg,
                'sem': '1',
                'ano': 2026,
                'carr': 187,
                'plan': '2020',
                'lugar': 1,
                'modalidad': 2,
                'codMotiv': 3,
                'codProc': 'ANULACION MATERIA',
                'aB': 'B'
            },
            {
                'reg': reg,
                'sem': '2',
                'ano': 2025,
                'carr': 187,
                'plan': '2020',
                'lugar': 1,
                'modalidad': 1,
                'codMotiv': 1,
                'codProc': 'RETIRO EXTRAORDINARIO',
                'aB': 'A'
            }
        ]
        return mock_tramites

