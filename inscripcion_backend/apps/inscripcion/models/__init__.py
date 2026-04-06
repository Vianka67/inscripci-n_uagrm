"""
Modelos de inscripción.
"""

# Carrera y Plan de Estudios
from .carrera import Carrera, PlanEstudios

# Materias
from .materia import Materia, MateriaCarreraSemestre

# Estudiantes
from .estudiante import Estudiante, EstudianteCarrera

# Periodo Académico
from .periodo import PeriodoAcademico

# Bloqueos
from .bloqueo import Bloqueo

# Inscripciones y Oferta de Materias
from .inscripcion import OfertaMateria, Inscripcion, InscripcionMateria

# Boletas y Pagos
from .boleta import ConceptoPago, Boleta, DetalleBoleta

__all__ = [
    # Carrera
    'Carrera',
    'PlanEstudios',
    # Materia
    'Materia',
    'MateriaCarreraSemestre',
    # Estudiante
    'Estudiante',
    'EstudianteCarrera',
    # Periodo
    'PeriodoAcademico',
    # Bloqueo
    'Bloqueo',
    # Inscripcion
    'OfertaMateria',
    'Inscripcion',
    'InscripcionMateria',
    # Boleta
    'ConceptoPago',
    'Boleta',
    'DetalleBoleta',
]
