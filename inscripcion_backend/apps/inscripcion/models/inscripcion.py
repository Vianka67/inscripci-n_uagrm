from django.db import models

from .materia import Materia, MateriaCarreraSemestre
from .periodo import PeriodoAcademico
from .estudiante import EstudianteCarrera


class OfertaMateria(models.Model):
    """Ofertas de Materias"""
    materia_carrera = models.ForeignKey(MateriaCarreraSemestre, on_delete=models.CASCADE, related_name='ofertas')
    periodo = models.ForeignKey(PeriodoAcademico, on_delete=models.CASCADE, related_name='ofertas')
    grupo = models.CharField(max_length=5, verbose_name="Grupo")
    docente = models.CharField(max_length=100, verbose_name="Docente", default="Por designar")
    horario = models.CharField(max_length=100, verbose_name="Horario", default="HORARIO A CONFIRMAR")
    cupo_maximo = models.IntegerField(default=40, verbose_name="Cupo Máximo")
    cupo_actual = models.IntegerField(default=0, verbose_name="Cupo Actual")

    class Meta:
        verbose_name = "Oferta de Materia"
        verbose_name_plural = "Ofertas de Materias"
        unique_together = ['materia_carrera', 'periodo', 'grupo']
        ordering = ['materia_carrera__materia__codigo', 'grupo']

    def __str__(self):
        return f"{self.materia_carrera.materia.codigo} - Gr. {self.grupo} ({self.periodo.codigo})"


class Inscripcion(models.Model):
    """Inscripciones"""
    ESTADO_CHOICES = [
        ('PENDIENTE', 'Pendiente'),
        ('CONFIRMADA', 'Confirmada'),
        ('CANCELADA', 'Cancelada'),
    ]

    estudiante_carrera = models.ForeignKey(EstudianteCarrera, on_delete=models.CASCADE, related_name='inscripciones')
    periodo_academico = models.ForeignKey(PeriodoAcademico, on_delete=models.CASCADE, related_name='inscripciones')
    fecha_inscripcion_asignada = models.DateField(verbose_name="Fecha de Inscripción Asignada")
    fecha_inscripcion_realizada = models.DateTimeField(null=True, blank=True, verbose_name="Fecha de Inscripción Realizada")
    estado = models.CharField(max_length=20, choices=ESTADO_CHOICES, default='PENDIENTE')
    bloqueado = models.BooleanField(default=False, verbose_name="Estado de Bloqueo")
    motivo_bloqueo = models.TextField(blank=True, verbose_name="Motivo del Bloqueo")
    boleta_generada = models.BooleanField(default=False, verbose_name="Boleta Generada")
    numero_boleta = models.CharField(max_length=50, blank=True, verbose_name="Número de Boleta")

    class Meta:
        verbose_name = "Inscripción"
        verbose_name_plural = "Inscripciones"
        unique_together = ['estudiante_carrera', 'periodo_academico']
        ordering = ['-fecha_inscripcion_asignada']

    def __str__(self):
        return f"Inscripción {self.estudiante_carrera.estudiante.registro} - {self.estudiante_carrera.carrera.codigo} - {self.periodo_academico.codigo}"


class InscripcionMateria(models.Model):
    """Materias Inscritas"""
    inscripcion = models.ForeignKey(Inscripcion, on_delete=models.CASCADE, related_name='materias_inscritas')
    oferta = models.ForeignKey(OfertaMateria, on_delete=models.CASCADE, related_name='inscripciones', null=True)
    # Campo legacy mantenido por compatibilidad con datos existentes. No usar en código nuevo.
    materia = models.ForeignKey(Materia, on_delete=models.CASCADE, related_name='inscripciones_directas', null=True, blank=True)
    grupo = models.CharField(max_length=5, verbose_name="Grupo", default="A", blank=True)

    class Meta:
        verbose_name = "Materia Inscrita"
        verbose_name_plural = "Materias Inscritas"
        unique_together = ['inscripcion', 'oferta']

    def __str__(self):
        if self.oferta:
            return f"{self.inscripcion.estudiante_carrera.estudiante.registro} - {self.oferta.materia_carrera.materia.codigo}"
        return f"{self.inscripcion.estudiante_carrera.estudiante.registro} - {self.materia.codigo if self.materia else 'N/A'}"
