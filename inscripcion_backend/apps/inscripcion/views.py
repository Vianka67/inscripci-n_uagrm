"""
Vistas web para inscripciones.
"""
from django.http import JsonResponse
from django.views import View
from django.shortcuts import get_object_or_404

from apps.inscripcion.models import Estudiante
from apps.inscripcion.services import (
    BloqueoService,
    InscripcionService,
    PeriodoAcademicoService,
    EstudianteService,
)


class StandardResponseMixin:
    """Agrega el encabezado a la respuesta."""

    def build_response(self, estudiante, data):
        est_carrera = EstudianteService.get_carreras_estudiante(
            estudiante.registro
        ).first()

        encabezado = {
            "encabezado": {
                "universidad": "UAGRM",
                "registro": estudiante.registro,
                "nombre": estudiante.nombre_completo,
                "carrera": est_carrera.carrera.nombre if est_carrera else "N/A",
                "modalidad": est_carrera.get_modalidad_display() if est_carrera else "N/A",
                "tipo_carrera": "Semestral",
            }
        }
        encabezado.update(data)
        return JsonResponse(encabezado)


class FechasInscripcionView(View, StandardResponseMixin):
    """Fechas de inscripción."""

    def get(self, request, registro):
        estudiante = get_object_or_404(Estudiante, registro=registro)
        periodo = PeriodoAcademicoService.get_periodo_habilitado_inscripcion()

        data = {
            "titulo": "FECHAS DE INSCRIPCIÓN",
            "periodo_habilitado": periodo.codigo if periodo else "NO DEFINIDO",
            "fechas": {
                "inicio": periodo.fecha_inicio.isoformat() if periodo else None,
                "fin": periodo.fecha_fin.isoformat() if periodo else None,
            },
            "estado": "HABILITADO" if periodo and periodo.inscripciones_habilitadas else "NO HABILITADO",
        }
        return self.build_response(estudiante, data)


class BloqueoView(View, StandardResponseMixin):
    """Estado de bloqueo."""

    def get(self, request, registro):
        estudiante = get_object_or_404(Estudiante, registro=registro)
        info_bloqueo = BloqueoService.get_info_bloqueo_estudiante(registro)

        primer_bloqueo = info_bloqueo["bloqueos"][0] if info_bloqueo["bloqueos"] else None

        data = {
            "titulo": "BLOQUEO",
            "bloqueado": info_bloqueo["bloqueado"],
            "detalle": {
                "motivo": primer_bloqueo["motivo"] if primer_bloqueo else None,
                "fecha_desbloqueo": (
                    primer_bloqueo["fecha_desbloqueo_estimada"].strftime("%Y-%m-%d")
                    if primer_bloqueo and primer_bloqueo.get("fecha_desbloqueo_estimada")
                    else None
                ),
            } if primer_bloqueo else None,
        }
        return self.build_response(estudiante, data)


class MateriasHabilitadasView(View, StandardResponseMixin):
    """Materias habilitadas."""

    def get(self, request, registro):
        estudiante = get_object_or_404(Estudiante, registro=registro)
        periodo = PeriodoAcademicoService.get_periodo_habilitado_inscripcion()
        materias = InscripcionService.get_materias_habilitadas(registro)

        materias_data = [
            {
                "codigo": m.materia.codigo,
                "nombre": m.materia.nombre,
                "semestre": m.semestre,
                "obligatoria": m.obligatoria,
            }
            for m in materias
        ]

        data = {
            "titulo": "MATERIAS HABILITADAS",
            "periodo": periodo.codigo if periodo else None,
            "materias": materias_data,
        }
        return self.build_response(estudiante, data)


class PeriodoHabilitadoView(View, StandardResponseMixin):
    """Periodo actual."""

    def get(self, request, registro):
        estudiante = get_object_or_404(Estudiante, registro=registro)
        periodo = PeriodoAcademicoService.get_periodo_habilitado_inscripcion()

        data = {
            "titulo": "PERIODO HABILITADO",
            "periodo_actual": periodo.codigo if periodo else "NINGUNO",
            "estado": "ABIERTO" if periodo and periodo.activo else "CERRADO",
        }
        return self.build_response(estudiante, data)


class BoletaView(View, StandardResponseMixin):
    """Datos de la boleta."""

    def get(self, request, registro):
        estudiante = get_object_or_404(Estudiante, registro=registro)
        inscripcion = InscripcionService.get_boleta_estudiante(registro)

        if not inscripcion:
            return self.build_response(estudiante, {
                "titulo": "BOLETA",
                "boleta": [],
                "total": 0,
                "estado_pago": "NO GENERADA",
            })

        boleta_data = []
        total = 0

        if hasattr(inscripcion, 'boleta_pago'):
            boleta = inscripcion.boleta_pago
            total = float(boleta.total)
            boleta_data = [
                {"concepto": d.concepto.nombre, "monto": float(d.monto)}
                for d in boleta.detalles.all()
            ]
            estado = boleta.get_estado_display().upper()
        else:
            estado = "PENDIENTE DE GENERAR"

        return self.build_response(estudiante, {
            "titulo": "BOLETA",
            "boleta": boleta_data,
            "total": total,
            "estado_pago": estado,
        })
