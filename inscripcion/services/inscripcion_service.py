"""
Servicio para gestión de inscripciones
"""
from typing import Optional, List
from ..models import Inscripcion, PeriodoAcademico, MateriaCarreraSemestre
from .periodo_service import PeriodoAcademicoService
from .estudiante_service import EstudianteService


class InscripcionService:
    """Servicio para operaciones relacionadas con inscripciones"""
    
    @staticmethod
    def get_inscripcion_actual(estudiante_registro: str, codigo_periodo: str = None, codigo_carrera: str = None) -> Optional[Inscripcion]:
        """
        Obtiene la inscripción actual de un estudiante para una carrera específica
        
        Args:
            estudiante_registro: Registro del estudiante
            codigo_periodo: Código del periodo (opcional, usa el activo si no se especifica)
            codigo_carrera: Código de la carrera (opcional)
            
        Returns:
            Inscripcion o None
        """
        periodo = PeriodoAcademicoService.get_periodo(codigo_periodo)
        if not periodo:
            return None
            
        try:
            query = Inscripcion.objects.select_related(
                'estudiante_carrera__estudiante', 
                'estudiante_carrera__carrera',
                'periodo_academico'
            ).prefetch_related(
                'materias_inscritas__materia'
            ).filter(
                estudiante_carrera__estudiante__registro=estudiante_registro,
                periodo_academico=periodo
            )

            if codigo_carrera:
                query = query.filter(estudiante_carrera__carrera__codigo=codigo_carrera)
            
            return query.first()
        except Inscripcion.DoesNotExist:
            return None
    
    @staticmethod
    def get_materias_habilitadas(estudiante_registro: str, codigo_carrera: str = None) -> List[MateriaCarreraSemestre]:
        """
        Obtiene las materias habilitadas para un estudiante según su carrera y semestre
        
        Args:
            estudiante_registro: Registro del estudiante
            codigo_carrera: Código de la carrera específica (opcional, usa la primera si no se provee)
            
        Returns:
            Lista de materias habilitadas
        """
        # Buscar la información académica de la carrera
        try:
            from ..models import EstudianteCarrera
            est_carrera_query = EstudianteCarrera.objects.select_related('carrera', 'plan_estudios').filter(
                estudiante__registro=estudiante_registro,
                activa=True
            )
            
            if codigo_carrera:
                est_carrera = est_carrera_query.filter(carrera__codigo=codigo_carrera).first()
            else:
                est_carrera = est_carrera_query.first()

            if not est_carrera:
                return []
                
            return list(MateriaCarreraSemestre.objects.filter(
                carrera=est_carrera.carrera,
                plan_estudios=est_carrera.plan_estudios,
                semestre=est_carrera.semestre_actual,
                habilitada=True
            ).select_related('materia', 'carrera', 'plan_estudios'))
        except Exception:
            return []
    
    @staticmethod
    def get_boleta_estudiante(estudiante_registro: str, codigo_periodo: str = None, codigo_carrera: str = None):
        """
        Obtiene la boleta de inscripción de un estudiante
        
        Args:
            estudiante_registro: Registro del estudiante
            codigo_periodo: Código del periodo (opcional)
            codigo_carrera: Código de la carrera (opcional)
            
        Returns:
            Inscripcion si tiene boleta generada, None en caso contrario
        """
        inscripcion = InscripcionService.get_inscripcion_actual(estudiante_registro, codigo_periodo, codigo_carrera)
        
        if inscripcion and inscripcion.boleta_generada:
            return inscripcion
        
        return None
