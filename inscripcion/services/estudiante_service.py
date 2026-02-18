"""
Servicio para gestión de estudiantes
"""
from typing import Optional
from inscripcion.models import Estudiante


class EstudianteService:
    """Servicio para operaciones relacionadas con estudiantes"""
    
    @staticmethod
    def get_by_registro(registro: str) -> Optional[Estudiante]:
        """
        Obtiene un estudiante (info personal) por su registro universitario
        """
        try:
            return Estudiante.objects.get(registro=registro)
        except Estudiante.DoesNotExist:
            return None
    
    @staticmethod
    def get_carreras_estudiante(registro: str):
        """
        Obtiene todas las carreras activas vinculadas a un registro
        """
        from inscripcion.models import EstudianteCarrera
        return EstudianteCarrera.objects.select_related('carrera', 'plan_estudios').filter(
            estudiante__registro=registro,
            activa=True
        )

    @staticmethod
    def get_carrera_especifica(registro: str, codigo_carrera: str):
        """
        Obtiene la información académica de una carrera específica para un estudiante
        """
        from inscripcion.models import EstudianteCarrera
        try:
            return EstudianteCarrera.objects.select_related('carrera', 'plan_estudios').get(
                estudiante__registro=registro,
                carrera__codigo=codigo_carrera,
                activa=True
            )
        except EstudianteCarrera.DoesNotExist:
            return None
    
    @staticmethod
    def get_nombre_completo(estudiante: Estudiante) -> str:
        """
        Obtiene el nombre completo del estudiante
        """
        return estudiante.nombre_completo
