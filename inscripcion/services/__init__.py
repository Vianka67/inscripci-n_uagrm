"""
Servicios del módulo de inscripción
"""
from .estudiante_service import EstudianteService
from .carrera_service import CarreraService
from .inscripcion_service import InscripcionService
from .periodo_service import PeriodoAcademicoService
from .bloqueo_service import BloqueoService
from .panel_service import PanelService

__all__ = [
    'EstudianteService',
    'CarreraService',
    'InscripcionService',
    'PeriodoAcademicoService',
    'BloqueoService',
    'PanelService',
]
