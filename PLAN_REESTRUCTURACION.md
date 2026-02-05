# 📋 PLAN DE REESTRUCTURACIÓN DEL BACKEND

## 🎯 Objetivo

Reestructurar el backend para que se alinee 100% con el flujo de las pantallas del sistema UAGRM, entregando datos listos para consumir sin lógica adicional en el frontend.

---

## 📱 PANTALLAS Y FLUJO DEL SISTEMA

### 1️⃣ Pantalla: Selección de Carrera

**Objetivo**: Mostrar lista de carreras disponibles

**Endpoint REST propuesto**:

```http
GET /api/carreras/
```

**Respuesta**:

```json
[
  {
    "id": 1,
    "codigo": "DER",
    "nombre": "Derecho",
    "facultad": "Ciencias Jurídicas y Políticas",
    "activa": true
  },
  {
    "id": 2,
    "codigo": "MED",
    "nombre": "Medicina",
    "facultad": "Ciencias de la Salud",
    "activa": true
  }
]
```

**Query GraphQL existente**:

```graphql
query {
  todasCarreras(activa: true) {
    id
    codigo
    nombre
    facultad
    activa
  }
}
```

---

### 2️⃣ Pantalla: Selección de Semestre

**Objetivo**: Mostrar semestres disponibles según la carrera seleccionada

**Endpoint REST propuesto**:

```http
GET /api/carreras/{codigo}/semestres/
```

**Respuesta**:

```json
{
  "carrera": {
    "codigo": "DER",
    "nombre": "Derecho"
  },
  "semestres": [
    { "numero": 1, "nombre": "Semestre 1", "habilitado": true },
    { "numero": 2, "nombre": "Semestre 2", "habilitado": true },
    { "numero": 3, "nombre": "Semestre 3", "habilitado": true },
    { "numero": 4, "nombre": "Semestre 4", "habilitado": true },
    { "numero": 5, "nombre": "Semestre 5", "habilitado": true },
    { "numero": 6, "nombre": "Semestre 6", "habilitado": true },
    { "numero": 7, "nombre": "Semestre 7", "habilitado": true },
    { "numero": 8, "nombre": "Semestre 8", "habilitado": true },
    { "numero": 9, "nombre": "Semestre 9", "habilitado": true },
    { "numero": 10, "nombre": "Semestre 10", "habilitado": true }
  ],
  "total_semestres": 10
}
```

**Query GraphQL existente**:

```graphql
query {
  semestresPorCarrera(codigoCarrera: "DER")
}
```

---

### 3️⃣ Pantalla: Panel Principal del Estudiante

**Objetivo**: Mostrar toda la información del estudiante en una sola llamada

**Endpoint REST propuesto**:

```http
GET /api/estudiante/{registro}/panel/
```

**Respuesta**:

```json
{
  "estudiante": {
    "registro": "2150826",
    "nombre_completo": "Vianka Vaca Flores",
    "nombre": "Vianka",
    "apellido_paterno": "Vaca",
    "apellido_materno": "Flores"
  },
  "carrera": {
    "codigo": "DER",
    "nombre": "Derecho",
    "tipo": "Semestral"
  },
  "modalidad": "Presencial",
  "semestre_actual": 3,
  "estado": "BLOQUEADO",
  "periodo_actual": {
    "codigo": "1/2026",
    "nombre": "Primer Semestre 2026",
    "inscripciones_habilitadas": true
  },
  "opciones_disponibles": {
    "fechas_inscripcion": true,
    "boleta": false,
    "bloqueo": true,
    "inscripcion": false
  },
  "inscripcion_actual": {
    "fecha_asignada": "2026-02-15",
    "estado": "PENDIENTE",
    "bloqueado": true,
    "boleta_generada": false
  }
}
```

**Query GraphQL propuesta**:

```graphql
query {
  panelEstudiante(registro: "2150826") {
    estudiante {
      registro
      nombreCompleto
      nombre
      apellidoPaterno
      apellidoMaterno
    }
    carrera {
      codigo
      nombre
      tipo
    }
    modalidad
    semestreActual
    estado
    periodoActual {
      codigo
      nombre
      inscripcionesHabilitadas
    }
    opcionesDisponibles {
      fechasInscripcion
      boleta
      bloqueo
      inscripcion
    }
    inscripcionActual {
      fechaAsignada
      estado
      bloqueado
      boletaGenerada
    }
  }
}
```

---

### 4️⃣ Pantalla: Información de Bloqueo

**Objetivo**: Mostrar detalles del bloqueo del estudiante

**Endpoint REST propuesto**:

```http
GET /api/estudiante/{registro}/bloqueo/
```

**Respuesta**:

```json
{
  "bloqueado": true,
  "bloqueos": [
    {
      "motivo": "Deuda pendiente de matrícula",
      "fecha_bloqueo": "2026-01-15",
      "fecha_desbloqueo_estimada": "2026-07-20",
      "tipo": "FINANCIERO",
      "activo": true
    }
  ],
  "puede_inscribirse": false,
  "mensaje": "Tienes bloqueos activos que impiden tu inscripción. Por favor, regulariza tu situación."
}
```

**Query GraphQL propuesta**:

```graphql
query {
  bloqueoEstudiante(registro: "2150826") {
    bloqueado
    bloqueos {
      motivo
      fechaBloqueo
      fechaDesbloqueoEstimada
      tipo
      activo
    }
    puedeInscribirse
    mensaje
  }
}
```

---

### 5️⃣ Pantalla: Boleta de Inscripción

**Objetivo**: Mostrar la boleta generada con todas las materias inscritas

**Endpoint REST propuesto**:

```http
GET /api/estudiante/{registro}/boleta/
```

**Respuesta**:

```json
{
  "estudiante": {
    "registro": "2150826",
    "nombre_completo": "Vianka Vaca Flores"
  },
  "carrera": {
    "codigo": "DER",
    "nombre": "Derecho"
  },
  "periodo": {
    "codigo": "1/2026",
    "nombre": "Primer Semestre 2026"
  },
  "numero_boleta": "BOL-2026-1-2150826",
  "fecha_generacion": "2026-02-15T10:30:00",
  "estado": "CONFIRMADA",
  "materias_inscritas": [
    {
      "codigo": "DER301",
      "nombre": "Derecho Civil III",
      "creditos": 6,
      "grupo": "A",
      "semestre": 3
    },
    {
      "codigo": "DER302",
      "nombre": "Derecho Penal I",
      "creditos": 6,
      "grupo": "B",
      "semestre": 3
    }
  ],
  "total_creditos": 24,
  "total_materias": 4
}
```

---

## 🗂️ ESTRUCTURA DE MODELOS ACTUALIZADA

### Modelo: Bloqueo (NUEVO)

```python
class Bloqueo(models.Model):
    """Modelo para gestionar bloqueos de estudiantes"""
    TIPO_BLOQUEO_CHOICES = [
        ('FINANCIERO', 'Deuda Financiera'),
        ('ACADEMICO', 'Bloqueo Académico'),
        ('ADMINISTRATIVO', 'Bloqueo Administrativo'),
        ('DISCIPLINARIO', 'Bloqueo Disciplinario'),
    ]
    
    estudiante = models.ForeignKey(Estudiante, on_delete=models.CASCADE, related_name='bloqueos')
    tipo = models.CharField(max_length=20, choices=TIPO_BLOQUEO_CHOICES)
    motivo = models.TextField(verbose_name="Motivo del Bloqueo")
    fecha_bloqueo = models.DateField(auto_now_add=True)
    fecha_desbloqueo_estimada = models.DateField(null=True, blank=True)
    activo = models.BooleanField(default=True)
    resuelto = models.BooleanField(default=False)
    fecha_resolucion = models.DateField(null=True, blank=True)
    observaciones = models.TextField(blank=True)
```

### Modelo: Inscripcion (ACTUALIZADO)

- Eliminar campos `bloqueado` y `motivo_bloqueo` (ahora manejados por modelo Bloqueo)
- Mantener relación con Bloqueo a través del estudiante

---

## 📁 ESTRUCTURA DE SERVICIOS PROPUESTA

```text
inscripcion/
├── services/
│   ├── __init__.py
│   ├── carrera_service.py       # Gestión de carreras y semestres
│   ├── estudiante_service.py    # Gestión de estudiantes
│   ├── inscripcion_service.py   # Gestión de inscripciones
│   ├── bloqueo_service.py       # Gestión de bloqueos (NUEVO)
│   └── panel_service.py         # Servicio para panel principal (NUEVO)
```

### CarreraService

```python
class CarreraService:
    @staticmethod
    def get_carreras_activas() -> List[Carrera]
    
    @staticmethod
    def get_semestres_por_carrera(codigo_carrera: str) -> dict
```

### BloqueoService (NUEVO)

```python
class BloqueoService:
    @staticmethod
    def tiene_bloqueos_activos(estudiante_registro: str) -> bool
    
    @staticmethod
    def get_bloqueos_estudiante(estudiante_registro: str) -> List[Bloqueo]
    
    @staticmethod
    def puede_inscribirse(estudiante_registro: str) -> bool
    
    @staticmethod
    def crear_bloqueo(estudiante_registro: str, tipo: str, motivo: str, fecha_desbloqueo: date = None) -> Bloqueo
    
    @staticmethod
    def resolver_bloqueo(bloqueo_id: int, observaciones: str = "") -> bool
```

### PanelService (NUEVO)

```python
class PanelService:
    @staticmethod
    def get_panel_estudiante(registro: str) -> dict
    """
    Retorna toda la información necesaria para el panel principal
    en una sola llamada, incluyendo:
    - Datos del estudiante
    - Carrera y modalidad
    - Estado de inscripción
    - Bloqueos activos
    - Opciones disponibles
    """
```

---

## 🔌 ENDPOINTS REST (Django REST Framework)

### Estructura de URLs propuesta

```text
/api/
├── carreras/
│   ├── GET /                           # Lista de carreras
│   └── GET /{codigo}/semestres/        # Semestres por carrera
│
├── estudiante/{registro}/
│   ├── GET /panel/                     # Panel principal
│   ├── GET /bloqueo/                   # Info de bloqueos
│   ├── GET /boleta/                    # Boleta de inscripción
│   └── GET /inscripcion/               # Info de inscripción actual
│
└── periodos/
    ├── GET /                           # Lista de periodos
    └── GET /actual/                    # Periodo activo
```

---

## 🔄 QUERIES GRAPHQL ACTUALIZADAS

### Queries principales

```graphql
# Panel completo del estudiante
query PanelEstudiante($registro: String!) {
  panelEstudiante(registro: $registro) {
    estudiante { ... }
    carrera { ... }
    estado
    opcionesDisponibles { ... }
    inscripcionActual { ... }
  }
}

# Bloqueos del estudiante
query BloqueoEstudiante($registro: String!) {
  bloqueoEstudiante(registro: $registro) {
    bloqueado
    bloqueos { ... }
    puedeInscribirse
    mensaje
  }
}

# Carreras disponibles
query Carreras {
  todasCarreras(activa: true) {
    id
    codigo
    nombre
    facultad
  }
}

# Semestres por carrera
query SemestresPorCarrera($codigoCarrera: String!) {
  semestresPorCarrera(codigoCarrera: $codigoCarrera) {
    carrera { ... }
    semestres { ... }
    totalSemestres
  }
}
```

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Fase 1: Modelos

- [ ] Crear modelo `Bloqueo`
- [ ] Actualizar modelo `Inscripcion` (remover campos de bloqueo)
- [ ] Crear y ejecutar migraciones

### Fase 2: Servicios

- [ ] Crear `BloqueoService`
- [ ] Crear `PanelService`
- [ ] Actualizar `CarreraService`
- [ ] Actualizar `EstudianteService`
- [ ] Actualizar `InscripcionService`

### Fase 3: GraphQL

- [ ] Crear tipos GraphQL para respuestas compuestas
- [ ] Implementar query `panelEstudiante`
- [ ] Implementar query `bloqueoEstudiante`
- [ ] Actualizar query `semestresPorCarrera` para retornar objeto completo

### Fase 4: REST API (Opcional)

- [ ] Instalar Django REST Framework
- [ ] Crear serializers
- [ ] Crear viewsets
- [ ] Configurar URLs

### Fase 5: Testing

- [ ] Crear datos de prueba
- [ ] Probar queries GraphQL
- [ ] Probar endpoints REST
- [ ] Validar respuestas según especificación

---

## 🎯 RESULTADO ESPERADO

✅ Backend 100% alineado con las pantallas del sistema
✅ Respuestas completas y listas para consumir
✅ Mínima lógica en el frontend
✅ Código escalable y bien organizado
✅ Documentación clara de endpoints y queries
✅ Datos de prueba para desarrollo

---

## 📝 NOTAS IMPORTANTES

1. **Compatibilidad**: Mantener GraphQL como API principal, REST como alternativa
2. **Migración de datos**: Los bloqueos actuales en `Inscripcion` deben migrarse al nuevo modelo `Bloqueo`
3. **Validaciones**: Implementar validaciones de negocio en los servicios, no en las queries
4. **Permisos**: Considerar autenticación y autorización para endpoints sensibles
5. **Caché**: Implementar caché para queries frecuentes (lista de carreras, periodos)

---

**Fecha de creación**: 2026-02-05
**Versión**: 1.0
