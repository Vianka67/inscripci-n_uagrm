from django.contrib import admin
from .models import (
    Carrera, PlanEstudios, Materia, MateriaCarreraSemestre,
    Estudiante, EstudianteCarrera, PeriodoAcademico, Inscripcion, InscripcionMateria, Bloqueo
)


@admin.register(Carrera)
class CarreraAdmin(admin.ModelAdmin):
    list_display = ['codigo', 'nombre', 'facultad', 'duracion_semestres', 'activa']
    list_filter = ['activa', 'facultad']
    search_fields = ['codigo', 'nombre', 'facultad']
    ordering = ['nombre']


@admin.register(PlanEstudios)
class PlanEstudiosAdmin(admin.ModelAdmin):
    list_display = ['codigo', 'nombre', 'carrera', 'anio_vigencia', 'vigente']
    list_filter = ['vigente', 'carrera', 'anio_vigencia']
    search_fields = ['codigo', 'nombre']
    ordering = ['-anio_vigencia']


@admin.register(Materia)
class MateriaAdmin(admin.ModelAdmin):
    list_display = ['codigo', 'nombre', 'creditos', 'horas_teoricas', 'horas_practicas']
    search_fields = ['codigo', 'nombre']
    ordering = ['codigo']


@admin.register(MateriaCarreraSemestre)
class MateriaCarreraSemestreAdmin(admin.ModelAdmin):
    list_display = ['materia', 'carrera', 'plan_estudios', 'semestre', 'obligatoria', 'habilitada']
    list_filter = ['carrera', 'semestre', 'obligatoria', 'habilitada']
    search_fields = ['materia__codigo', 'materia__nombre', 'carrera__nombre']
    ordering = ['carrera', 'semestre', 'materia__codigo']


@admin.register(Estudiante)
class EstudianteAdmin(admin.ModelAdmin):
    list_display = ['registro', 'nombre_completo', 'activo']
    list_filter = ['activo']
    search_fields = ['registro', 'nombre', 'apellido_paterno', 'apellido_materno', 'email']
    ordering = ['apellido_paterno', 'apellido_materno', 'nombre']
    
    fieldsets = (
        ('Información Personal', {
            'fields': ('registro', 'documento_identidad', 'nombre', 'apellido_paterno', 'apellido_materno')
        }),
        ('Información de Contacto', {
            'fields': ('email', 'telefono', 'lugar_origen')
        }),
        ('Estado', {
            'fields': ('activo', 'fecha_ingreso')
        }),
    )


@admin.register(EstudianteCarrera)
class EstudianteCarreraAdmin(admin.ModelAdmin):
    list_display = ['estudiante', 'carrera', 'semestre_actual', 'modalidad', 'activa']
    list_filter = ['carrera', 'semestre_actual', 'modalidad', 'activa']
    search_fields = ['estudiante__registro', 'estudiante__nombre', 'carrera__nombre']


@admin.register(PeriodoAcademico)
class PeriodoAcademicoAdmin(admin.ModelAdmin):
    list_display = ['codigo', 'nombre', 'tipo', 'fecha_inicio', 'fecha_fin', 'activo', 'inscripciones_habilitadas']
    list_filter = ['activo', 'inscripciones_habilitadas', 'tipo']
    search_fields = ['codigo', 'nombre']
    ordering = ['-fecha_inicio']


class InscripcionMateriaInline(admin.TabularInline):
    model = InscripcionMateria
    extra = 1


@admin.register(Inscripcion)
class InscripcionAdmin(admin.ModelAdmin):
    list_display = ['estudiante_carrera', 'periodo_academico', 'fecha_inscripcion_asignada', 
                    'estado', 'bloqueado', 'boleta_generada']
    list_filter = ['estado', 'bloqueado', 'boleta_generada', 'periodo_academico']
    search_fields = ['estudiante_carrera__estudiante__registro', 'numero_boleta']
    ordering = ['-fecha_inscripcion_asignada']
    inlines = [InscripcionMateriaInline]
    
    fieldsets = (
        ('Información General', {
            'fields': ('estudiante_carrera', 'periodo_academico')
        }),
        ('Fechas', {
            'fields': ('fecha_inscripcion_asignada', 'fecha_inscripcion_realizada')
        }),
        ('Estado', {
            'fields': ('estado', 'bloqueado', 'motivo_bloqueo')
        }),
        ('Boleta', {
            'fields': ('boleta_generada', 'numero_boleta')
        }),
    )


@admin.register(Bloqueo)
class BloqueoAdmin(admin.ModelAdmin):
    list_display = ['estudiante_carrera', 'tipo', 'motivo_corto', 'fecha_bloqueo', 'fecha_desbloqueo_estimada', 'activo', 'resuelto']
    list_filter = ['tipo', 'activo', 'resuelto', 'fecha_bloqueo']
    search_fields = ['estudiante_carrera__estudiante__registro', 'motivo']
    ordering = ['-fecha_bloqueo']
    
    fieldsets = (
        ('Información del Bloqueo', {
            'fields': ('estudiante_carrera', 'tipo', 'motivo')
        }),
        ('Fechas', {
            'fields': ('fecha_bloqueo', 'fecha_desbloqueo_estimada', 'fecha_resolucion')
        }),
        ('Estado', {
            'fields': ('activo', 'resuelto', 'observaciones')
        }),
    )
    
    readonly_fields = ['fecha_bloqueo']
    
    def motivo_corto(self, obj):
        """Muestra una versión corta del motivo"""
        return obj.motivo[:50] + '...' if len(obj.motivo) > 50 else obj.motivo
    motivo_corto.short_description = 'Motivo'

