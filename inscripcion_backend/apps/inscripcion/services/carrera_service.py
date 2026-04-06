"""
Gestión de carreras.
"""
from typing import List, Dict, Any
from ..models import Carrera


class CarreraService:
    """Operaciones de carreras."""
    
    @staticmethod
    def get_carreras_activas() -> List[Carrera]:
        """
        Carreras activas.
        """
        return list(Carrera.objects.filter(activa=True).order_by('nombre'))
    
    @staticmethod
    def get_todas_carreras() -> List[Carrera]:
        """
        Todas las carreras.
        """
        return list(Carrera.objects.all().order_by('nombre'))

    @staticmethod
    def get_todas(activa=None) -> List[Carrera]:
        """
        Filtrar carreras.
        """
        queryset = Carrera.objects.all()
        if activa is not None:
            queryset = queryset.filter(activa=activa)
        return queryset
    
    @staticmethod
    def get_carrera_por_codigo(codigo: str) -> Carrera:
        """
        Buscar por código.
        """
        try:
            return Carrera.objects.get(codigo=codigo)
        except Carrera.DoesNotExist:
            return None
    
    @staticmethod
    def get_semestres_por_carrera(codigo_carrera: str) -> Dict[str, Any]:
        """
        Semestres de carrera.
        """
        try:
            carrera = Carrera.objects.get(codigo=codigo_carrera)
            semestres = []
            
            for num in range(1, carrera.duracion_semestres + 1):
                semestres.append({
                    'numero': num,
                    'nombre': f'Semestre {num}',
                    'habilitado': True
                })
            
            return {
                'carrera': {
                    'codigo': carrera.codigo,
                    'nombre': carrera.nombre
                },
                'semestres': semestres,
                'total_semestres': carrera.duracion_semestres
            }
        except Carrera.DoesNotExist:
            return {
                'carrera': None,
                'semestres': [],
                'total_semestres': 0
            }
