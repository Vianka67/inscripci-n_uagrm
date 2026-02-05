"""
Servicio para gestión de bloqueos de estudiantes
"""
from typing import List, Dict, Any
from datetime import date
from ..models import Bloqueo, Estudiante


class BloqueoService:
    """Servicio para operaciones relacionadas con bloqueos de estudiantes"""
    
    @staticmethod
    def tiene_bloqueos_activos(estudiante_registro: str) -> bool:
        """
        Verifica si un estudiante tiene bloqueos activos
        
        Args:
            estudiante_registro: Registro del estudiante
            
        Returns:
            True si tiene bloqueos activos, False en caso contrario
        """
        return Bloqueo.objects.filter(
            estudiante__registro=estudiante_registro,
            activo=True,
            resuelto=False
        ).exists()
    
    @staticmethod
    def get_bloqueos_estudiante(estudiante_registro: str, solo_activos: bool = True) -> List[Bloqueo]:
        """
        Obtiene los bloqueos de un estudiante
        
        Args:
            estudiante_registro: Registro del estudiante
            solo_activos: Si True, solo retorna bloqueos activos
            
        Returns:
            Lista de bloqueos
        """
        queryset = Bloqueo.objects.filter(
            estudiante__registro=estudiante_registro
        ).select_related('estudiante')
        
        if solo_activos:
            queryset = queryset.filter(activo=True, resuelto=False)
        
        return list(queryset)
    
    @staticmethod
    def puede_inscribirse(estudiante_registro: str) -> bool:
        """
        Verifica si un estudiante puede inscribirse (no tiene bloqueos activos)
        
        Args:
            estudiante_registro: Registro del estudiante
            
        Returns:
            True si puede inscribirse, False si está bloqueado
        """
        return not BloqueoService.tiene_bloqueos_activos(estudiante_registro)
    
    @staticmethod
    def crear_bloqueo(
        estudiante_registro: str, 
        tipo: str, 
        motivo: str, 
        fecha_desbloqueo: date = None
    ) -> Bloqueo:
        """
        Crea un nuevo bloqueo para un estudiante
        
        Args:
            estudiante_registro: Registro del estudiante
            tipo: Tipo de bloqueo (FINANCIERO, ACADEMICO, ADMINISTRATIVO, DISCIPLINARIO)
            motivo: Motivo del bloqueo
            fecha_desbloqueo: Fecha estimada de desbloqueo (opcional)
            
        Returns:
            Bloqueo creado
        """
        try:
            estudiante = Estudiante.objects.get(registro=estudiante_registro)
            bloqueo = Bloqueo.objects.create(
                estudiante=estudiante,
                tipo=tipo,
                motivo=motivo,
                fecha_desbloqueo_estimada=fecha_desbloqueo,
                activo=True,
                resuelto=False
            )
            return bloqueo
        except Estudiante.DoesNotExist:
            return None
    
    @staticmethod
    def resolver_bloqueo(bloqueo_id: int, observaciones: str = "") -> bool:
        """
        Resuelve un bloqueo
        
        Args:
            bloqueo_id: ID del bloqueo
            observaciones: Observaciones sobre la resolución
            
        Returns:
            True si se resolvió correctamente, False en caso contrario
        """
        try:
            bloqueo = Bloqueo.objects.get(id=bloqueo_id)
            bloqueo.activo = False
            bloqueo.resuelto = True
            bloqueo.fecha_resolucion = date.today()
            bloqueo.observaciones = observaciones
            bloqueo.save()
            return True
        except Bloqueo.DoesNotExist:
            return False
    
    @staticmethod
    def get_info_bloqueo_estudiante(estudiante_registro: str) -> Dict[str, Any]:
        """
        Obtiene información completa de bloqueos de un estudiante
        
        Args:
            estudiante_registro: Registro del estudiante
            
        Returns:
            Diccionario con información de bloqueos
        """
        bloqueos = BloqueoService.get_bloqueos_estudiante(estudiante_registro, solo_activos=True)
        bloqueado = len(bloqueos) > 0
        
        bloqueos_data = []
        for bloqueo in bloqueos:
            bloqueos_data.append({
                'id': bloqueo.id,
                'tipo': bloqueo.tipo,
                'motivo': bloqueo.motivo,
                'fecha_bloqueo': bloqueo.fecha_bloqueo,
                'fecha_desbloqueo_estimada': bloqueo.fecha_desbloqueo_estimada,
                'activo': bloqueo.activo
            })
        
        return {
            'bloqueado': bloqueado,
            'bloqueos': bloqueos_data,
            'puede_inscribirse': not bloqueado,
            'mensaje': 'Tienes bloqueos activos que impiden tu inscripción. Por favor, regulariza tu situación.' if bloqueado else 'No tienes bloqueos activos.'
        }
