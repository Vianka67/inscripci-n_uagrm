"""
Archivo de compatibilidad para importar servicios
Mantiene la compatibilidad con código existente
"""
from .services.estudiante_service import EstudianteService
from .services.carrera_service import CarreraService
from .services.inscripcion_service import InscripcionService
from .services.periodo_service import PeriodoAcademicoService
from .services.bloqueo_service import BloqueoService
from .services.panel_service import PanelService

__all__ = [
    'EstudianteService',
    'CarreraService',
    'InscripcionService',
    'PeriodoAcademicoService',
    'BloqueoService',
    'PanelService',
]

