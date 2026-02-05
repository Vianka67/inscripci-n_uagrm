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
    def get_inscripcion_actual(estudiante_registro: str, codigo_periodo: str = None) -> Optional[Inscripcion]:
        """
        Obtiene la inscripción actual de un estudiante
        
        Args:
            estudiante_registro: Registro del estudiante
            codigo_periodo: Código del periodo (opcional, usa el activo si no se especifica)
            
        Returns:
            Inscripcion o None
        """
        periodo = PeriodoAcademicoService.get_periodo(codigo_periodo)
        if not periodo:
            return None
            
        try:
            return Inscripcion.objects.select_related(
                'estudiante', 
                'periodo_academico'
            ).prefetch_related(
                'materias_inscritas__materia'
            ).get(
                estudiante__registro=estudiante_registro,
                periodo_academico=periodo
            )
        except Inscripcion.DoesNotExist:
            return None
    
    @staticmethod
    def get_materias_habilitadas(estudiante_registro: str) -> List[MateriaCarreraSemestre]:
        """
        Obtiene las materias habilitadas para un estudiante según su carrera y semestre
        
        Args:
            estudiante_registro: Registro del estudiante
            
        Returns:
            Lista de materias habilitadas
        """
        estudiante = EstudianteService.get_by_registro(estudiante_registro)
        if not estudiante:
            return []
            
        return list(MateriaCarreraSemestre.objects.filter(
            carrera=estudiante.carrera_actual,
            plan_estudios=estudiante.plan_estudios,
            semestre=estudiante.semestre_actual,
            habilitada=True
        ).select_related('materia', 'carrera', 'plan_estudios'))
    
    @staticmethod
    def get_boleta_estudiante(estudiante_registro: str, codigo_periodo: str = None):
        """
        Obtiene la boleta de inscripción de un estudiante
        
        Args:
            estudiante_registro: Registro del estudiante
            codigo_periodo: Código del periodo (opcional)
            
        Returns:
            Inscripcion si tiene boleta generada, None en caso contrario
        """
        inscripcion = InscripcionService.get_inscripcion_actual(estudiante_registro, codigo_periodo)
        
        if inscripcion and inscripcion.boleta_generada:
            return inscripcion
        
        return None
