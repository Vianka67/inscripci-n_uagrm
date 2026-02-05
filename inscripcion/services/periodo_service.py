"""
Servicio para gestión de periodos académicos
"""
from typing import Optional, List
from ..models import PeriodoAcademico


class PeriodoAcademicoService:
    """Servicio para operaciones relacionadas con periodos académicos"""
    
    @staticmethod
    def get_periodo(codigo: str = None) -> Optional[PeriodoAcademico]:
        """
        Obtiene un periodo académico por código o el periodo activo
        
        Args:
            codigo: Código del periodo (opcional)
            
        Returns:
            PeriodoAcademico o None
        """
        if codigo:
            try:
                return PeriodoAcademico.objects.get(codigo=codigo)
            except PeriodoAcademico.DoesNotExist:
                return None
        return PeriodoAcademico.objects.filter(activo=True).first()
    
    @staticmethod
    def get_periodo_habilitado_inscripcion() -> Optional[PeriodoAcademico]:
        """
        Obtiene el periodo con inscripciones habilitadas
        
        Returns:
            PeriodoAcademico o None
        """
        return PeriodoAcademico.objects.filter(
            activo=True,
            inscripciones_habilitadas=True
        ).first()
    
    @staticmethod
    def get_todos_periodos(activo: bool = None) -> List[PeriodoAcademico]:
        """
        Obtiene todos los periodos académicos
        
        Args:
            activo: Filtrar por estado activo (opcional)
            
        Returns:
            Lista de periodos académicos
        """
        if activo is not None:
            return list(PeriodoAcademico.objects.filter(activo=activo))
        return list(PeriodoAcademico.objects.all())
