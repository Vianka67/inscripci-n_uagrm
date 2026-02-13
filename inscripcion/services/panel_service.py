"""
Servicio para el panel principal del estudiante
Consolida toda la información necesaria en una sola llamada
"""
from typing import Dict, Any, Optional
from .estudiante_service import EstudianteService
from .inscripcion_service import InscripcionService
from .bloqueo_service import BloqueoService
from .periodo_service import PeriodoAcademicoService


class PanelService:
    """Servicio para obtener toda la información del panel del estudiante"""
    
    @staticmethod
    def get_panel_estudiante(registro: str, codigo_carrera: str = None) -> Dict[str, Any]:
        """
        Obtiene toda la información necesaria para el panel principal del estudiante
        
        Args:
            registro: Registro universitario del estudiante (login inicial)
            codigo_carrera: Opcional, código de la carrera a mostrar
        """
        # Obtener información personal del estudiante
        estudiante = EstudianteService.get_by_registro(registro)
        if not estudiante:
            return {
                'error': 'Estudiante no encontrado',
                'estudiante': None
            }
        
        # Obtener información académica de la carrera (específica o la primera disponible)
        carreras = EstudianteService.get_carreras_estudiante(registro)
        if not carreras.exists():
            return {
                'error': 'El estudiante no tiene carreras registradas',
                'estudiante': estudiante
            }

        est_carrera = None
        if codigo_carrera:
            est_carrera = EstudianteService.get_carrera_especifica(registro, codigo_carrera)
        
        if not est_carrera:
            est_carrera = carreras.first()

        # Obtener periodo actual
        periodo_actual = PeriodoAcademicoService.get_periodo_habilitado_inscripcion()
        
        # Obtener inscripción actual vinculada a ESTA carrera del estudiante
        inscripcion = None
        from ..models import Inscripcion
        try:
            inscripcion = Inscripcion.objects.get(
                estudiante_carrera=est_carrera,
                periodo_academico=periodo_actual
            ) if periodo_actual else None
        except Inscripcion.DoesNotExist:
            pass
        
        # Obtener información de bloqueos (vinculados a la carrera)
        tiene_bloqueos = est_carrera.bloqueos.filter(activo=True).exists()
        
        # Determinar estado del estudiante
        estado = "BLOQUEADO" if tiene_bloqueos else "ACTIVO"
        
        # Determinar opciones disponibles
        opciones_disponibles = PanelService._calcular_opciones_disponibles(
            inscripcion, 
            tiene_bloqueos, 
            periodo_actual
        )
        
        # Construir respuesta
        panel_data = {
            'estudiante': {
                'registro': estudiante.registro,
                'nombre_completo': estudiante.nombre_completo,
                'nombre': estudiante.nombre,
                'apellido_paterno': estudiante.apellido_paterno,
                'apellido_materno': estudiante.apellido_materno,
            },
            'carrera': {
                'codigo': est_carrera.carrera.codigo,
                'nombre': est_carrera.carrera.nombre,
                'tipo': 'Semestral',
                'facultad': est_carrera.carrera.facultad,
            },
            'modalidad': est_carrera.get_modalidad_display(),
            'semestre_actual': est_carrera.semestre_actual,
            'estado': estado,
            'periodo_actual': None,
            'opciones_disponibles': opciones_disponibles,
            'inscripcion_actual': None
        }
        
        # Agregar información del periodo si existe
        if periodo_actual:
            panel_data['periodo_actual'] = {
                'codigo': periodo_actual.codigo,
                'nombre': periodo_actual.nombre,
                'inscripciones_habilitadas': periodo_actual.inscripciones_habilitadas,
                'fecha_inicio': periodo_actual.fecha_inicio.isoformat(),
                'fecha_fin': periodo_actual.fecha_fin.isoformat(),
            }
        
        # Agregar información de inscripción si existe
        if inscripcion:
            panel_data['inscripcion_actual'] = {
                'fecha_asignada': inscripcion.fecha_inscripcion_asignada.isoformat(),
                'fecha_realizada': inscripcion.fecha_inscripcion_realizada.isoformat() if inscripcion.fecha_inscripcion_realizada else None,
                'estado': inscripcion.estado,
                'bloqueado': tiene_bloqueos,
                'boleta_generada': inscripcion.boleta_generada,
                'numero_boleta': inscripcion.numero_boleta if inscripcion.boleta_generada else None,
            }
        
        return panel_data
    
    @staticmethod
    def _calcular_opciones_disponibles(inscripcion, tiene_bloqueos: bool, periodo_actual) -> Dict[str, bool]:
        """
        Calcula qué opciones están disponibles para el estudiante
        
        Args:
            inscripcion: Inscripción actual del estudiante
            tiene_bloqueos: Si el estudiante tiene bloqueos activos
            periodo_actual: Periodo académico actual
            
        Returns:
            Diccionario con opciones disponibles
        """
        opciones = {
            'fechas_inscripcion': False,
            'boleta': False,
            'bloqueo': False,
            'inscripcion': False,
        }
        
        # Fechas de inscripción disponibles si hay periodo activo
        if periodo_actual and periodo_actual.inscripciones_habilitadas:
            opciones['fechas_inscripcion'] = True
        
        # Boleta disponible si existe inscripción y está generada
        if inscripcion and inscripcion.boleta_generada:
            opciones['boleta'] = True
        
        # Información de bloqueo disponible si tiene bloqueos
        if tiene_bloqueos:
            opciones['bloqueo'] = True
        
        # Inscripción disponible si no está bloqueado y hay periodo activo
        if not tiene_bloqueos and periodo_actual and periodo_actual.inscripciones_habilitadas:
            opciones['inscripcion'] = True
        
        return opciones
    
    @staticmethod
    def get_info_boleta(registro: str, codigo_carrera: str = None) -> Optional[Dict[str, Any]]:
        """
        Obtiene la información completa de la boleta de inscripción
        
        Args:
            registro: Registro del estudiante
            codigo_carrera: Código de la carrera (opcional)
            
        Returns:
            Diccionario con información de la boleta o None
        """
        estudiante = EstudianteService.get_by_registro(registro)
        if not estudiante:
            return None
        
        inscripcion = InscripcionService.get_boleta_estudiante(registro, codigo_carrera=codigo_carrera)
        if not inscripcion:
            return None
        
        # Calcular totales
        materias_inscritas = inscripcion.materias_inscritas.all()
        total_creditos = sum(m.materia.creditos for m in materias_inscritas)
        total_materias = materias_inscritas.count()
        
        # Construir lista de materias
        materias_data = []
        for mat_inscrita in materias_inscritas:
            materias_data.append({
                'codigo': mat_inscrita.materia.codigo,
                'nombre': mat_inscrita.materia.nombre,
                'creditos': mat_inscrita.materia.creditos,
                'grupo': mat_inscrita.grupo,
                'horas_teoricas': mat_inscrita.materia.horas_teoricas,
                'horas_practicas': mat_inscrita.materia.horas_practicas,
            })
        
        return {
            'estudiante': {
                'registro': estudiante.registro,
                'nombre_completo': estudiante.nombre_completo,
            },
            'carrera': {
                'codigo': inscripcion.estudiante_carrera.carrera.codigo,
                'nombre': inscripcion.estudiante_carrera.carrera.nombre,
            },
            'periodo': {
                'codigo': inscripcion.periodo_academico.codigo,
                'nombre': inscripcion.periodo_academico.nombre,
            },
            'numero_boleta': inscripcion.numero_boleta,
            'fecha_generacion': inscripcion.fecha_inscripcion_realizada.isoformat() if inscripcion.fecha_inscripcion_realizada else None,
            'estado': inscripcion.estado,
            'materias_inscritas': materias_data,
            'total_creditos': total_creditos,
            'total_materias': total_materias,
        }
