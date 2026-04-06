from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator

from .carrera import Carrera, PlanEstudios


class Estudiante(models.Model):
    """Estudiantes"""
    registro = models.CharField(max_length=20, unique=True, primary_key=True, verbose_name="Registro Universitario")
    documento_identidad = models.CharField(max_length=20, verbose_name="Documento de Identidad", default="0")
    nombre = models.CharField(max_length=100, verbose_name="Nombre")
    apellido_paterno = models.CharField(max_length=100, verbose_name="Apellido Paterno")
    apellido_materno = models.CharField(max_length=100, blank=True, verbose_name="Apellido Materno")
    lugar_origen = models.CharField(max_length=200, verbose_name="Lugar de Origen")
    email = models.EmailField(blank=True, verbose_name="Correo Electrónico")
    telefono = models.CharField(max_length=20, blank=True, verbose_name="Teléfono")
    activo = models.BooleanField(default=True, verbose_name="Estudiante Activo")
    fecha_ingreso = models.DateField(verbose_name="Fecha de Ingreso")

    class Meta:
        verbose_name = "Estudiante"
        verbose_name_plural = "Estudiantes"
        ordering = ['apellido_paterno', 'apellido_materno', 'nombre']

    def __str__(self):
        return f"{self.registro} - {self.nombre} {self.apellido_paterno}"

    @property
    def nombre_completo(self):
        """Nombre completo."""
        if self.apellido_materno:
            return f"{self.nombre} {self.apellido_paterno} {self.apellido_materno}"
        return f"{self.nombre} {self.apellido_paterno}"


class EstudianteCarrera(models.Model):
    """Carrera de Estudiante"""
    MODALIDAD_CHOICES = [
        ('PRESENCIAL', 'Presencial'),
        ('SEMIPRESENCIAL', 'Semipresencial'),
        ('VIRTUAL', 'Virtual'),
    ]

    estudiante = models.ForeignKey(Estudiante, on_delete=models.CASCADE, related_name='carreras')
    carrera = models.ForeignKey(Carrera, on_delete=models.PROTECT, related_name='estudiantes_inscritos')
    plan_estudios = models.ForeignKey(PlanEstudios, on_delete=models.PROTECT)
    semestre_actual = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(20)],
        verbose_name="Semestre Actual"
    )
    modalidad = models.CharField(max_length=20, choices=MODALIDAD_CHOICES, default='PRESENCIAL')
    activa = models.BooleanField(default=True)

    class Meta:
        verbose_name = "Carrera de Estudiante"
        verbose_name_plural = "Carreras de Estudiante"

    def __str__(self):
        return f"{self.estudiante.registro} - {self.carrera.nombre}"
