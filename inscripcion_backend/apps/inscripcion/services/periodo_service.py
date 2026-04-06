"""
Gestión de periodos.
"""
from typing import Optional, List
from ..models import PeriodoAcademico


class PeriodoAcademicoService:
    """Operaciones de periodos."""
    
    @staticmethod
    def get_periodo(codigo: str = None) -> Optional[PeriodoAcademico]:
        """
        Buscar periodo.
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
        Periodo de inscripción.
        """
        return PeriodoAcademico.objects.filter(
            activo=True,
            inscripciones_habilitadas=True
        ).first()
    
    @staticmethod
    def get_todos_periodos(activo: bool = None) -> List[PeriodoAcademico]:
        """
        Listar periodos.
        """
        if activo is not None:
            return list(PeriodoAcademico.objects.filter(activo=activo))
        return list(PeriodoAcademico.objects.all())
