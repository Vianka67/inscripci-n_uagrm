from django.db import models


class PeriodoAcademico(models.Model):
    """Periodos Académicos"""
    TIPO_PERIODO_CHOICES = [
        ('1/2026', 'Primer Semestre 2026'),
        ('2/2026', 'Segundo Semestre 2026'),
        ('1/2025', 'Primer Semestre 2025'),
        ('2/2025', 'Segundo Semestre 2025'),
    ]

    codigo = models.CharField(max_length=10, unique=True, verbose_name="Código del Periodo")
    nombre = models.CharField(max_length=100, verbose_name="Nombre del Periodo")
    tipo = models.CharField(max_length=10, choices=TIPO_PERIODO_CHOICES, verbose_name="Tipo de Periodo")
    fecha_inicio = models.DateField(verbose_name="Fecha de Inicio")
    fecha_fin = models.DateField(verbose_name="Fecha de Fin")
    activo = models.BooleanField(default=False, verbose_name="Periodo Activo")
    inscripciones_habilitadas = models.BooleanField(default=False, verbose_name="Inscripciones Habilitadas")

    class Meta:
        verbose_name = "Periodo Académico"
        verbose_name_plural = "Periodos Académicos"
        ordering = ['-fecha_inicio']

    def __str__(self):
        return f"{self.codigo} - {self.nombre}"
