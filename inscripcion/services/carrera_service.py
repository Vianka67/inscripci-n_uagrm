"""
Servicio para gestión de carreras y semestres
"""
from typing import List, Dict, Any
from ..models import Carrera


class CarreraService:
    """Servicio para operaciones relacionadas con carreras"""
    
    @staticmethod
    def get_carreras_activas() -> List[Carrera]:
        """
        Obtiene todas las carreras activas
        
        Returns:
            Lista de carreras activas
        """
        return list(Carrera.objects.filter(activa=True).order_by('nombre'))
    
    @staticmethod
    def get_todas_carreras() -> List[Carrera]:
        """
        Obtiene todas las carreras
        
        Returns:
            Lista de todas las carreras
        """
        return list(Carrera.objects.all().order_by('nombre'))
    
    @staticmethod
    def get_carrera_por_codigo(codigo: str) -> Carrera:
        """
        Obtiene una carrera por su código
        
        Args:
            codigo: Código de la carrera
            
        Returns:
            Carrera o None si no existe
        """
        try:
            return Carrera.objects.get(codigo=codigo)
        except Carrera.DoesNotExist:
            return None
    
    @staticmethod
    def get_semestres_por_carrera(codigo_carrera: str) -> Dict[str, Any]:
        """
        Obtiene los semestres disponibles para una carrera
        
        Args:
            codigo_carrera: Código de la carrera
            
        Returns:
            Diccionario con información de la carrera y sus semestres
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
