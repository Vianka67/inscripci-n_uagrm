from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class Carrera(models.Model):
    """Carreras"""
    codigo = models.CharField(max_length=10, unique=True, verbose_name="Código de Carrera")
    nombre = models.CharField(max_length=200, verbose_name="Nombre de la Carrera")
    facultad = models.CharField(max_length=200, verbose_name="Facultad")
    duracion_semestres = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(20)],
        verbose_name="Duración en Semestres"
    )
    activa = models.BooleanField(default=True, verbose_name="Carrera Activa")

    class Meta:
        verbose_name = "Carrera"
        verbose_name_plural = "Carreras"
        ordering = ['nombre']

    def __str__(self):
        return f"{self.codigo} - {self.nombre}"


class PlanEstudios(models.Model):
    """Planes de Estudio"""
    carrera = models.ForeignKey(Carrera, on_delete=models.CASCADE, related_name='planes')
    codigo = models.CharField(max_length=20, unique=True, verbose_name="Código del Plan")
    nombre = models.CharField(max_length=200, verbose_name="Nombre del Plan")
    anio_vigencia = models.IntegerField(verbose_name="Año de Vigencia")
    vigente = models.BooleanField(default=True, verbose_name="Plan Vigente")

    class Meta:
        verbose_name = "Plan de Estudios"
        verbose_name_plural = "Planes de Estudio"
        ordering = ['anio_vigencia']

    def __str__(self):
        return f"{self.codigo} - {self.nombre} ({self.anio_vigencia})"
