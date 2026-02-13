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
    """Modelo para los estudiantes (Información Personal)"""
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
        """Retorna el nombre completo del estudiante"""
        if self.apellido_materno:
            return f"{self.nombre} {self.apellido_paterno} {self.apellido_materno}"
        return f"{self.nombre} {self.apellido_paterno}"


class EstudianteCarrera(models.Model):
    """Relación entre Estudiante y Carrera (Información Académica)"""
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


class PeriodoAcademico(models.Model):
    """Modelo para los periodos académicos (gestiones)"""
    TIPO_PERIODO_CHOICES = [
        ('1/2026', 'Primer Semestre 2026'),
        ('2/2026', 'Segundo Semestre 2026'),
        ('1/2025', 'Primer Semestre 2025'), # Backward compatibility
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


class Bloqueo(models.Model):
    """Modelo para gestionar bloqueos de estudiantes"""
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


class OfertaMateria(models.Model):
    """Modelo para la oferta de materias en un periodo específico (Grupos)"""
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
    """Modelo para las inscripciones de estudiantes"""
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
    """Modelo para las materias inscritas en cada inscripción"""
    inscripcion = models.ForeignKey(Inscripcion, on_delete=models.CASCADE, related_name='materias_inscritas')
    oferta = models.ForeignKey(OfertaMateria, on_delete=models.CASCADE, related_name='inscripciones', null=True)
    # Mantener campos antiguos por compatibilidad si es necesario, pero idealmente migrar a oferta
    materia = models.ForeignKey(Materia, on_delete=models.CASCADE, related_name='inscripciones_directas', null=True, blank=True)
    grupo = models.CharField(max_length=5, verbose_name="Grupo", default="A", blank=True)
    
    class Meta:
        verbose_name = "Materia Inscrita"
        verbose_name_plural = "Materias Inscritas"
        unique_together = ['inscripcion', 'oferta']
    
    def __str__(self):
        if self.oferta:
            return f"{self.inscripcion.estudiante.registro} - {self.oferta.materia_carrera.materia.codigo}"
        return f"{self.inscripcion.estudiante.registro} - {self.materia.codigo}"


class ConceptoPago(models.Model):
    """Modelo para los conceptos de pago de la boleta"""
    nombre = models.CharField(max_length=100, verbose_name="Concepto")
    monto = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Monto")
    obligatorio = models.BooleanField(default=True, verbose_name="Obligatorio")
    
    class Meta:
        verbose_name = "Concepto de Pago"
        verbose_name_plural = "Conceptos de Pago"

    def __str__(self):
        return f"{self.nombre} - {self.monto} Bs"


class Boleta(models.Model):
    """Modelo para la boleta de pago del estudiante"""
    ESTADO_PAGO_CHOICES = [
        ('PENDIENTE', 'Pendiente'),
        ('PAGADO', 'Pagado'),
        ('ANULADO', 'Anulado'),
    ]
    
    inscripcion = models.OneToOneField(Inscripcion, on_delete=models.CASCADE, related_name='boleta_pago')
    fecha_emision = models.DateField(auto_now_add=True, verbose_name="Fecha de Emisión")
    total = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Total")
    estado = models.CharField(max_length=20, choices=ESTADO_PAGO_CHOICES, default='PENDIENTE')
    
    class Meta:
        verbose_name = "Boleta"
        verbose_name_plural = "Boletas"
        
    def __str__(self):
        return f"Boleta {self.inscripcion.numero_boleta} - {self.inscripcion.estudiante.registro}"


class DetalleBoleta(models.Model):
    """Detalle de los conceptos en una boleta específica"""
    boleta = models.ForeignKey(Boleta, on_delete=models.CASCADE, related_name='detalles')
    concepto = models.ForeignKey(ConceptoPago, on_delete=models.PROTECT, related_name='boletas')
    monto = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Monto Aplicado")
    
    class Meta:
        verbose_name = "Detalle de Boleta"
        verbose_name_plural = "Detalles de Boleta"
        
    def __str__(self):
        return f"{self.concepto.nombre} en Boleta {self.boleta.id}"
