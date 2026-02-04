from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator


class Carrera(models.Model):
    """Modelo para las carreras universitarias disponibles"""
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
    """Modelo para los planes de estudio de cada carrera"""
    carrera = models.ForeignKey(Carrera, on_delete=models.CASCADE, related_name='planes')
    codigo = models.CharField(max_length=20, unique=True, verbose_name="Código del Plan")
    nombre = models.CharField(max_length=200, verbose_name="Nombre del Plan")
    anio_vigencia = models.IntegerField(verbose_name="Año de Vigencia")
    vigente = models.BooleanField(default=True, verbose_name="Plan Vigente")
    
    class Meta:
        verbose_name = "Plan de Estudios"
        verbose_name_plural = "Planes de Estudio"
        ordering = ['-anio_vigencia']
    
    def __str__(self):
        return f"{self.codigo} - {self.nombre} ({self.anio_vigencia})"


class Materia(models.Model):
    """Modelo para las materias del plan de estudios"""
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
    """Modelo que relaciona materias con carreras y semestres específicos"""
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


class Estudiante(models.Model):
    """Modelo para los estudiantes"""
    MODALIDAD_CHOICES = [
        ('PRESENCIAL', 'Presencial'),
        ('SEMIPRESENCIAL', 'Semipresencial'),
        ('VIRTUAL', 'Virtual'),
    ]
    
    registro = models.CharField(max_length=20, unique=True, primary_key=True, verbose_name="Registro Universitario")
    nombre = models.CharField(max_length=100, verbose_name="Nombre")
    apellido_paterno = models.CharField(max_length=100, verbose_name="Apellido Paterno")
    apellido_materno = models.CharField(max_length=100, blank=True, verbose_name="Apellido Materno")
    carrera_actual = models.ForeignKey(Carrera, on_delete=models.PROTECT, related_name='estudiantes')
    semestre_actual = models.IntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(20)],
        verbose_name="Semestre Actual"
    )
    plan_estudios = models.ForeignKey(PlanEstudios, on_delete=models.PROTECT, related_name='estudiantes')
    modalidad = models.CharField(max_length=20, choices=MODALIDAD_CHOICES, default='PRESENCIAL')
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
        """Retorna el nombre completo del estudiante"""
        if self.apellido_materno:
            return f"{self.nombre} {self.apellido_paterno} {self.apellido_materno}"
        return f"{self.nombre} {self.apellido_paterno}"


class PeriodoAcademico(models.Model):
    """Modelo para los periodos académicos (gestiones)"""
    TIPO_PERIODO_CHOICES = [
        ('1/2024', 'Primer Semestre 2024'),
        ('2/2024', 'Segundo Semestre 2024'),
        ('1/2025', 'Primer Semestre 2025'),
        ('2/2025', 'Segundo Semestre 2025'),
        ('1/2026', 'Primer Semestre 2026'),
        ('2/2026', 'Segundo Semestre 2026'),
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


class Inscripcion(models.Model):
    """Modelo para las inscripciones de estudiantes"""
    ESTADO_CHOICES = [
        ('PENDIENTE', 'Pendiente'),
        ('CONFIRMADA', 'Confirmada'),
        ('CANCELADA', 'Cancelada'),
    ]
    
    estudiante = models.ForeignKey(Estudiante, on_delete=models.CASCADE, related_name='inscripciones')
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
        unique_together = ['estudiante', 'periodo_academico']
        ordering = ['-fecha_inscripcion_asignada']
    
    def __str__(self):
        return f"Inscripción {self.estudiante.registro} - {self.periodo_academico.codigo}"


class InscripcionMateria(models.Model):
    """Modelo para las materias inscritas en cada inscripción"""
    inscripcion = models.ForeignKey(Inscripcion, on_delete=models.CASCADE, related_name='materias_inscritas')
    materia = models.ForeignKey(Materia, on_delete=models.CASCADE, related_name='inscripciones')
    grupo = models.CharField(max_length=5, verbose_name="Grupo", default="A")
    
    class Meta:
        verbose_name = "Materia Inscrita"
        verbose_name_plural = "Materias Inscritas"
        unique_together = ['inscripcion', 'materia']
    
    def __str__(self):
        return f"{self.inscripcion.estudiante.registro} - {self.materia.codigo}"
