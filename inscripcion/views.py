from django.http import JsonResponse
from django.views import View
from django.shortcuts import get_object_or_404
from django.db.models import F
from .models import Estudiante, PeriodoAcademico, Inscripcion, Bloqueo, OfertaMateria, Boleta

class StandardResponseMixin:
    """Mixin para estandarizar la respuesta JSON según requerimientos"""
    
    def get_encabezado(self, estudiante):
        return {
            "encabezado": {
                "universidad": "UAGRM",
                "registro": estudiante.registro,
                "nombre": estudiante.nombre_completo,
                "carrera": estudiante.carrera_actual.nombre,
                "modalidad": estudiante.get_modalidad_display(),
                "tipo_carrera": "Semestral"  # Podría ser dinámico si el PlanEstudios tiene ese dato
            }
        }

    def build_response(self, estudiante, data):
        response = self.get_encabezado(estudiante)
        response.update(data)
        return JsonResponse(response)


class FechasInscripcionView(View, StandardResponseMixin):
    def get(self, request, registro):
        estudiante = get_object_or_404(Estudiante, registro=registro)
        periodo = PeriodoAcademico.objects.filter(activo=True).first()
        
        # Lógica simplificada, idealmente vendría de una tabla de cronograma
        data = {
            "titulo": "FECHAS DE INSCRIPCIÓN",
            "periodo_habilitado": periodo.codigo if periodo else "NO DEFINIDO",
            "fechas": {
                "inicio": "2026-02-01",  # Mock, reemplazar con fechas reales del periodo o grupo
                "fin": "2026-02-10"
            },
            "estado": "HABILITADO" if periodo and periodo.inscripciones_habilitadas else "NO HABILITADO"
        }
        return self.build_response(estudiante, data)


class BloqueoView(View, StandardResponseMixin):
    def get(self, request, registro):
        estudiante = get_object_or_404(Estudiante, registro=registro)
        bloqueo_activo = estudiante.bloqueos.filter(activo=True).first()
        
        data = {
            "titulo": "BLOQUEO",
            "bloqueado": bloqueo_activo is not None,
            "detalle": {
                "motivo": bloqueo_activo.motivo if bloqueo_activo else None,
                "fecha_desbloqueo": bloqueo_activo.fecha_desbloqueo_estimada.strftime("%Y-%m-%d") if bloqueo_activo and bloqueo_activo.fecha_desbloqueo_estimada else None
            } if bloqueo_activo else None
        }
        return self.build_response(estudiante, data)


class MateriasHabilitadasView(View, StandardResponseMixin):
    def get(self, request, registro):
        estudiante = get_object_or_404(Estudiante, registro=registro)
        periodo = PeriodoAcademico.objects.filter(activo=True).first()
        
        materias_data = []
        if periodo:
            # Obtener ofertas para la carrera del estudiante, filtrando por semestre actual o lógica de pre-requisitos
            # Por simplicidad, mostramos ofertas del semestre actual del estudiante
            ofertas = OfertaMateria.objects.filter(
                periodo=periodo,
                materia_carrera__carrera=estudiante.carrera_actual,
                materia_carrera__semestre=estudiante.semestre_actual
            )
            
            for oferta in ofertas:
                materias_data.append({
                    "codigo": oferta.materia_carrera.materia.codigo,
                    "nombre": oferta.materia_carrera.materia.nombre,
                    "grupo": oferta.grupo,
                    "horario": oferta.horario,
                    "docente": oferta.docente
                })
        
        data = {
            "titulo": "MATERIAS HABILITADAS",
            "periodo": periodo.codigo if periodo else None,
            "materias": materias_data
        }
        return self.build_response(estudiante, data)


class PeriodoHabilitadoView(View, StandardResponseMixin):
    def get(self, request, registro):
        estudiante = get_object_or_404(Estudiante, registro=registro)
        periodo = PeriodoAcademico.objects.filter(activo=True).first()
        
        data = {
            "titulo": "PERIODO HABILITADO",
            "periodo_actual": periodo.codigo if periodo else "NINGUNO",
            "estado": "ABIERTO" if periodo and periodo.activo else "CERRADO"
        }
        return self.build_response(estudiante, data)


class BoletaView(View, StandardResponseMixin):
    def get(self, request, registro):
        estudiante = get_object_or_404(Estudiante, registro=registro)
        periodo = PeriodoAcademico.objects.filter(activo=True).first()
        
        boleta_data = []
        total = 0
        estado = "NO GENERADA"
        
        if periodo:
            inscripcion = Inscripcion.objects.filter(estudiante=estudiante, periodo_academico=periodo).first()
            if inscripcion and hasattr(inscripcion, 'boleta_pago'):
                boleta = inscripcion.boleta_pago
                estado = boleta.get_estado_display().upper()
                total = float(boleta.total)
                
                for detalle in boleta.detalles.all():
                    boleta_data.append({
                        "concepto": detalle.concepto.nombre,
                        "monto": float(detalle.monto)
                    })
            elif inscripcion:
                 estado = "PENDIENTE DE GENERAR"
            else:
                 estado = "SIN INSCRIPCIÓN"

        data = {
            "titulo": "BOLETA",
            "boleta": boleta_data,
            "total": total,
            "estado_pago": estado
        }
        return self.build_response(estudiante, data)
