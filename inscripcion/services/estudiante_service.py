"""
Servicio para gestión de estudiantes
"""
from typing import Optional
from ..models import Estudiante


class EstudianteService:
    """Servicio para operaciones relacionadas con estudiantes"""
    
    @staticmethod
    def get_by_registro(registro: str) -> Optional[Estudiante]:
        """
        Obtiene un estudiante por su registro universitario
        
        Args:
            registro: Registro universitario del estudiante
            
        Returns:
            Estudiante o None si no existe
        """
        try:
            return Estudiante.objects.select_related(
                'carrera_actual', 
                'plan_estudios'
            ).get(registro=registro)
        except Estudiante.DoesNotExist:
            return None
    
    @staticmethod
    def get_nombre_completo(estudiante: Estudiante) -> str:
        """
        Obtiene el nombre completo del estudiante
        
        Args:
            estudiante: Instancia del estudiante
            
        Returns:
            Nombre completo formateado
        """
        return estudiante.nombre_completo
