from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator

from .carrera import Carrera, PlanEstudios


class Materia(models.Model):
    """Materias"""
    codigo = models.CharField(max_length=15, unique=True, verbose_name="Código de Materia")
    nombre = models.CharField(max_length=200, verbose_name="Nombre de la Materia")
    creditos = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(10)],
        verbose_name="Créditos"
    )
    horas_teoricas = models.IntegerField(default=0, verbose_name="Horas Teóricas")
    horas_practicas = models.IntegerField(default=0, verbose_name="Horas Prácticas")

    class Meta:
        verbose_name = "Materia"
        verbose_name_plural = "Materias"
        ordering = ['codigo']

    def __str__(self):
        return f"{self.codigo} - {self.nombre}"


class MateriaCarreraSemestre(models.Model):
    """Materias por Carrera y Semestre"""
    carrera = models.ForeignKey(Carrera, on_delete=models.CASCADE, related_name='materias_semestre')
    plan_estudios = models.ForeignKey(PlanEstudios, on_delete=models.CASCADE, related_name='materias_semestre')
    materia = models.ForeignKey(Materia, on_delete=models.CASCADE, related_name='carreras_semestre')
    semestre = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(20)],
        verbose_name="Semestre"
    )
    obligatoria = models.BooleanField(default=True, verbose_name="Materia Obligatoria")
    habilitada = models.BooleanField(default=True, verbose_name="Materia Habilitada")

    class Meta:
        verbose_name = "Materia por Carrera y Semestre"
        verbose_name_plural = "Materias por Carrera y Semestre"
        unique_together = ['carrera', 'plan_estudios', 'materia', 'semestre']
        ordering = ['semestre', 'materia__codigo']

    def __str__(self):
        return f"{self.materia.codigo} - Sem {self.semestre} ({self.carrera.codigo})"
