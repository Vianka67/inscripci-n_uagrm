from django.db import models

from .estudiante import EstudianteCarrera


class Bloqueo(models.Model):
    """Bloqueos"""
    TIPO_BLOQUEO_CHOICES = [
        ('FINANCIERO', 'Deuda Financiera'),
        ('ACADEMICO', 'Bloqueo Académico'),
        ('ADMINISTRATIVO', 'Bloqueo Administrativo'),
        ('DISCIPLINARIO', 'Bloqueo Disciplinario'),
    ]

    estudiante_carrera = models.ForeignKey(EstudianteCarrera, on_delete=models.CASCADE, related_name='bloqueos')
    tipo = models.CharField(max_length=20, choices=TIPO_BLOQUEO_CHOICES, verbose_name="Tipo de Bloqueo")
    motivo = models.TextField(verbose_name="Motivo del Bloqueo")
    fecha_bloqueo = models.DateField(auto_now_add=True, verbose_name="Fecha de Bloqueo")
    fecha_desbloqueo_estimada = models.DateField(null=True, blank=True, verbose_name="Fecha de Desbloqueo Estimada")
    activo = models.BooleanField(default=True, verbose_name="Bloqueo Activo")
    resuelto = models.BooleanField(default=False, verbose_name="Bloqueo Resuelto")
    fecha_resolucion = models.DateField(null=True, blank=True, verbose_name="Fecha de Resolución")
    observaciones = models.TextField(blank=True, verbose_name="Observaciones")

    class Meta:
        verbose_name = "Bloqueo"
        verbose_name_plural = "Bloqueos"
        ordering = ['-fecha_bloqueo']

    def __str__(self):
        return f"Bloqueo {self.tipo} - {self.estudiante_carrera.estudiante.registro} ({self.estudiante_carrera.carrera.codigo})"
