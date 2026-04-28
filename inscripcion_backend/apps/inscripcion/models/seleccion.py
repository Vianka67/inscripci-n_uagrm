from django.db import models
from .estudiante import Estudiante
from .carrera import Carrera, PlanEstudios
from .materia import Materia
from .inscripcion import OfertaMateria

class MatSelec(models.Model):
    """
    Tabla temporal para almacenar las materias seleccionadas
    por el estudiante antes de confirmar la inscripción.
    """
    # Usamos nro_serie como string/varchar o bigint. Usaremos CharField por flexibilidad
    nro_serie = models.CharField(max_length=50, verbose_name="Número de Serie de Inscripción")
    
    # Podríamos enlazar al estudiante y carrera, pero a veces nro_serie es suficiente.
    # Por si acaso, guardamos registro para tener el link directo
    registro = models.CharField(max_length=20, null=True, blank=True)
    
    nivel = models.IntegerField(verbose_name="Nivel/Semestre", default=0)
    cod_mat = models.IntegerField(verbose_name="Código de Materia")
    plan = models.CharField(max_length=10, verbose_name="Plan de Estudios")
    sigla = models.CharField(max_length=10, verbose_name="Sigla")
    nombre_materia = models.CharField(max_length=200, verbose_name="Nombre Materia")
    grupo = models.CharField(max_length=10, verbose_name="Grupo")
    estado = models.CharField(max_length=5, verbose_name="Estado (Proceso)", default="I")
    ok = models.IntegerField(verbose_name="OK (Confirmado)", default=1)
    
    # Fechas de auditoría
    creado_en = models.DateTimeField(auto_now_add=True)
    actualizado_en = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Materia Seleccionada"
        verbose_name_plural = "Materias Seleccionadas"
        db_table = "mat_selec"
        
        # Evitar duplicados de la misma materia en el mismo nro_serie
        unique_together = ['nro_serie', 'cod_mat', 'grupo']

    def __str__(self):
        return f"{self.nro_serie} - {self.sigla} - Gr. {self.grupo}"
