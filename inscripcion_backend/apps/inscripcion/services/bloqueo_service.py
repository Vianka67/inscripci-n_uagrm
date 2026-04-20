"""
Gestión de bloqueos.
"""
from typing import List, Dict, Any, Optional
from datetime import date
from ..models import Bloqueo, Estudiante, EstudianteCarrera


class BloqueoService:
    """Operaciones de bloqueos."""
    
    @staticmethod
    def tiene_bloqueos_activos(estudiante_registro: str) -> bool:
        """
        Verificar bloqueos.
        """
        return Bloqueo.objects.filter(
            estudiante_carrera__estudiante__registro=estudiante_registro,
            activo=True,
            resuelto=False
        ).exists()
    
    @staticmethod
    def get_bloqueos_estudiante(estudiante_registro: str, solo_activos: bool = True) -> List[Bloqueo]:
        """
        Listar bloqueos.
        """
        queryset = Bloqueo.objects.filter(
            estudiante_carrera__estudiante__registro=estudiante_registro
        ).select_related('estudiante_carrera__estudiante')
        
        if solo_activos:
            queryset = queryset.filter(activo=True, resuelto=False)
        
        return list(queryset)
    
    @staticmethod
    def puede_inscribirse(estudiante_registro: str) -> bool:
        """
        Verificar inscripción.
        """
        return not BloqueoService.tiene_bloqueos_activos(estudiante_registro)
    
    @staticmethod
    def crear_bloqueo(
        estudiante_registro: str, 
        tipo: str, 
        motivo: str, 
        fecha_desbloqueo: Optional[date] = None
    ) -> Optional[Bloqueo]:
        """
        Crear bloqueo.
        """
        try:
            # Nota: Si se crea un bloqueo sin especificar carrera, se aplica a la primera activa
            # En un sistema real, debería pedirse la carrera.
            est_carrera = EstudianteCarrera.objects.filter(
                estudiante__registro=estudiante_registro,
                activa=True
            ).first()
            
            if not est_carrera:
                return None

            bloqueo = Bloqueo.objects.create(
                estudiante_carrera=est_carrera,
                tipo=tipo,
                motivo=motivo,
                fecha_desbloqueo_estimada=fecha_desbloqueo,
                activo=True,
                resuelto=False
            )
            return bloqueo
        except Exception:
            return None
    
    @staticmethod
    def resolver_bloqueo(bloqueo_id: int, observaciones: str = "") -> bool:
        """
        Resolver bloqueo.
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
        Info de bloqueos.
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
