"""
Gestión de estudiantes.
"""
from typing import Optional
from ..models import Estudiante, EstudianteCarrera


class EstudianteService:
    """Operaciones de estudiantes."""
    
    @staticmethod
    def get_by_registro(registro: str) -> Optional[Estudiante]:
        """
        Buscar por registro.
        """
        try:
            return Estudiante.objects.get(registro=registro)
        except Estudiante.DoesNotExist:
            return None
    
    @staticmethod
    def authenticate(registro: str, contrasena: str) -> Optional[Estudiante]:
        """
        Autenticación simple por registro y contraseña.
        """
        try:
            estudiante = Estudiante.objects.get(registro=registro)
            if estudiante.contrasena == contrasena:
                return estudiante
            return None
        except Estudiante.DoesNotExist:
            return None
    
    @staticmethod
    def get_carreras_estudiante(registro: str):
        """
        Buscar carreras activas.
        """
        return EstudianteCarrera.objects.select_related('carrera', 'plan_estudios').filter(
            estudiante__registro=registro,
            activa=True
        )

    @staticmethod
    def get_carrera_especifica(registro: str, codigo_carrera: str):
        """
        Buscar carrera específica.
        """
        try:
            return EstudianteCarrera.objects.select_related('carrera', 'plan_estudios').get(
                estudiante__registro=registro,
                carrera__codigo=codigo_carrera,
                activa=True
            )
        except EstudianteCarrera.DoesNotExist:
            return None
    
    @staticmethod
    def get_all_by_documento(documento_identidad: str):
        """
        Buscar por documento.
        """
        return Estudiante.objects.filter(documento_identidad=documento_identidad)

    @staticmethod
    def get_nombre_completo(estudiante: Estudiante) -> str:
        """
        Nombre completo.
        """
        return estudiante.nombre_completo
