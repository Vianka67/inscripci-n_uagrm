"""
Servicio para gestión de inscripciones
"""
from typing import Optional, List
from django.db import models
from inscripcion.models import Inscripcion, PeriodoAcademico, MateriaCarreraSemestre
from .periodo_service import PeriodoAcademicoService
from .estudiante_service import EstudianteService


class InscripcionService:
    """Servicio para operaciones relacionadas con inscripciones"""
    
    @staticmethod
    def get_inscripcion_actual(estudiante_registro: str, codigo_periodo: Optional[str] = None, codigo_carrera: Optional[str] = None) -> Optional[Inscripcion]:
        """
        Obtiene la inscripción actual de un estudiante para una carrera específica
        
        Args:
            estudiante_registro: Registro del estudiante
            codigo_periodo: Código del periodo (opcional, usa el activo si no se especifica)
            codigo_carrera: Código de la carrera (opcional)
            
        Returns:
            Inscripcion o None
        """
        periodo = PeriodoAcademicoService.get_periodo(codigo_periodo)
        if not periodo:
            return None
            
        try:
            query = Inscripcion.objects.select_related(
                'estudiante_carrera__estudiante', 
                'estudiante_carrera__carrera',
                'periodo_academico'
            ).prefetch_related(
                'materias_inscritas__materia'
            ).filter(
                estudiante_carrera__estudiante__registro=estudiante_registro,
                periodo_academico=periodo
            )

            if codigo_carrera:
                query = query.filter(estudiante_carrera__carrera__codigo=codigo_carrera)
            
            return query.first()
        except Inscripcion.DoesNotExist:
            return None
    
    @staticmethod
    def get_materias_habilitadas(estudiante_registro: str, codigo_carrera: Optional[str] = None) -> List[MateriaCarreraSemestre]:
        """
        Obtiene las materias habilitadas para un estudiante según su carrera y semestre
        
        Args:
            estudiante_registro: Registro del estudiante
            codigo_carrera: Código de la carrera específica (opcional, usa la primera si no se provee)
            
        Returns:
            Lista de materias habilitadas
        """
        # Buscar la información académica de la carrera
        try:
            from inscripcion.models import EstudianteCarrera
            est_carrera_query = EstudianteCarrera.objects.select_related('carrera', 'plan_estudios').filter(
                estudiante__registro=estudiante_registro,
                activa=True
            )
            
            if codigo_carrera:
                est_carrera = est_carrera_query.filter(carrera__codigo=codigo_carrera).first()
            else:
                est_carrera = est_carrera_query.first()

            if not est_carrera:
                return []
                
            return list(MateriaCarreraSemestre.objects.filter(
                carrera=est_carrera.carrera,
                plan_estudios=est_carrera.plan_estudios,
                semestre=est_carrera.semestre_actual,
                habilitada=True
            ).select_related('materia', 'carrera', 'plan_estudios'))
        except Exception:
            return []
    
    @staticmethod
    def get_boleta_estudiante(estudiante_registro: str, codigo_periodo: Optional[str] = None, codigo_carrera: Optional[str] = None):
        """
        Obtiene la boleta de inscripción de un estudiante
        
        Args:
            estudiante_registro: Registro del estudiante
            codigo_periodo: Código del periodo (opcional)
            codigo_carrera: Código de la carrera (opcional)
            
        Returns:
            Inscripcion si tiene boleta generada, None en caso contrario
        """
        inscripcion = InscripcionService.get_inscripcion_actual(estudiante_registro, codigo_periodo, codigo_carrera)
        
        if inscripcion and inscripcion.boleta_generada:
            return inscripcion
        
        return None

    @staticmethod
    def get_ofertas_filtered(
        codigo_materia: Optional[str] = None,
        codigo_carrera: Optional[str] = None,
        codigo_periodo: Optional[str] = None,
        turno: Optional[str] = None,
        tiene_cupo: Optional[bool] = None,
        docente: Optional[str] = None,
        grupo: Optional[str] = None
    ) -> List:
        """
        Obtiene ofertas de materias filtradas según múltiples criterios
        """
        from inscripcion.models import OfertaMateria, PeriodoAcademico
        
        # Obtener periodo activo si no se provee
        if not codigo_periodo:
            periodo = PeriodoAcademico.objects.filter(activo=True).first()
        else:
            periodo = PeriodoAcademico.objects.filter(codigo=codigo_periodo).first()
            
        if not periodo:
            return []
            
        queryset = OfertaMateria.objects.filter(periodo=periodo).select_related(
            'materia_carrera__materia',
            'materia_carrera__carrera'
        )
        
        if codigo_materia:
            queryset = queryset.filter(materia_carrera__materia__codigo=codigo_materia)
            
        if codigo_carrera:
            queryset = queryset.filter(materia_carrera__carrera__codigo=codigo_carrera)
            
        if grupo:
            queryset = queryset.filter(grupo=grupo)
            
        if docente:
            if docente.upper() == "POR DESIGNAR":
                queryset = queryset.filter(models.Q(docente__isnull=True) | models.Q(docente="") | models.Q(docente__iexact="Por designar"))
            else:
                queryset = queryset.filter(docente__icontains=docente)
                
        if tiene_cupo is not None:
            if tiene_cupo:
                queryset = queryset.filter(cupo_actual__lt=models.F('cupo_maximo'))
            else:
                queryset = queryset.filter(cupo_actual__gte=models.F('cupo_maximo'))
                
        # Filtrado por Turno (lógica basada en horario)
        # Mañana: 07:00 - 12:00
        # Tarde: 12:00 - 18:00
        # Noche: 18:00 - 22:00
        if turno:
            turno = turno.upper()
            if turno == "MAÑANA":
                # Buscamos patrones típicos de mañana en el string de horario
                queryset = queryset.filter(horario__icontains="07:") | queryset.filter(horario__icontains="08:") | \
                           queryset.filter(horario__icontains="09:") | queryset.filter(horario__icontains="10:") | \
                           queryset.filter(horario__icontains="11:")
            elif turno == "TARDE":
                queryset = queryset.filter(horario__icontains="12:") | queryset.filter(horario__icontains="13:") | \
                           queryset.filter(horario__icontains="14:") | queryset.filter(horario__icontains="15:") | \
                           queryset.filter(horario__icontains="16:") | queryset.filter(horario__icontains="17:")
            elif turno == "NOCHE":
                queryset = queryset.filter(horario__icontains="18:") | queryset.filter(horario__icontains="19:") | \
                           queryset.filter(horario__icontains="20:") | queryset.filter(horario__icontains="21:") | \
                           queryset.filter(horario__icontains="22:")

        return list(queryset)
