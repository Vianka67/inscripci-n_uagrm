# Sistema de Inscripción Universitaria - Backend

Backend desarrollado con Django, GraphQL (Graphene) y PostgreSQL para un sistema de inscripción universitaria.

## 🚀 Características

- **API GraphQL** completa con Graphene-Django
- **Base de datos PostgreSQL** con modelos relacionales
- **Docker & Docker Compose** para fácil despliegue
- **CORS habilitado** para conexiones desde frontend externo
- **Datos de prueba** incluidos para testing inmediato
- **Panel de administración** de Django configurado

## 📋 Requisitos Previos

- Docker Desktop instalado
- Docker Compose instalado
- Puerto 8000 y 5432 disponibles

## 🛠️ Instalación y Ejecución

### 1. Clonar o descargar el proyecto

```bash
cd backend_inscripción
```

### 2. Construir y ejecutar con Docker

```bash
docker-compose up --build
```

Este comando:
- Creará la base de datos PostgreSQL
- Ejecutará las migraciones
- Cargará los datos de prueba
- Iniciará el servidor en `http://0.0.0.0:8000`

### 3. Acceder a la aplicación

- **GraphQL Playground**: http://localhost:8000/graphql/
- **Panel Admin**: http://localhost:8000/admin/

## 👤 Datos de Prueba

### Estudiantes de Prueba

**Estudiante 1:**
- Registro: `218001234`
- Nombre: Juan Carlos Pérez García
- Carrera: Ingeniería de Sistemas
- Semestre: 3
- Estado: Sin bloqueo

**Estudiante 2:**
- Registro: `219005678`
- Nombre: María Fernanda López Martínez
- Carrera: Ingeniería de Sistemas
- Semestre: 2
- Estado: Bloqueado (Deuda en biblioteca)

## 🔍 Queries GraphQL Disponibles

### 1. Query para Inicio - Obtener Carreras

```graphql
query {
  todasCarreras(activa: true) {
    codigo
    nombre
    facultad
    duracionSemestres
  }
}
```

### 2. Query para Inicio - Obtener Semestres por Carrera

```graphql
query {
  semestresPorCarrera(codigoCarrera: "ING-SIS")
}
```

### 3. Query de Perfil - Datos del Estudiante

```graphql
query {
  perfilEstudiante(registro: "218001234") {
    registro
    nombreCompleto
    nombre
    apellidoPaterno
    apellidoMaterno
    carreraActual {
      codigo
      nombre
    }
    semestreActual
    planEstudios {
      codigo
      nombre
    }
    modalidad
    lugarOrigen
    email
    telefono
  }
}
```

### 4. Query - Fecha de Inscripción

```graphql
query {
  fechaInscripcionEstudiante(registro: "218001234")
}
```

### 5. Query - Estado de Bloqueo

```graphql
query {
  estadoBloqueoEstudiante(registro: "218001234")
  motivoBloqueoEstudiante(registro: "218001234")
}
```

### 6. Query - Materias Habilitadas

```graphql
query {
  materiasHabilitadas(registro: "218001234") {
    materia {
      codigo
      nombre
      creditos
      horasTeorica
      horasPracticas
    }
    semestre
    obligatoria
  }
}
```

### 7. Query - Periodo Habilitado

```graphql
query {
  periodoHabilitado {
    codigo
    nombre
    tipo
    fechaInicio
    fechaFin
    inscripcionesHabilitadas
  }
}
```

### 8. Query - Boleta del Estudiante

```graphql
query {
  boletaEstudiante(registro: "218001234") {
    numeroBoleta
    estado
    fechaInscripcionAsignada
    fechaInscripcionRealizada
    materiasInscritas {
      materia {
        codigo
        nombre
        creditos
      }
      grupo
    }
  }
}
```

### 9. Query Completa - Toda la Información de Inscripción

```graphql
query {
  inscripcionCompleta(registro: "218001234") {
    estudiante {
      registro
      nombreCompleto
      carreraActual {
        nombre
      }
    }
    periodoAcademico {
      codigo
      nombre
    }
    fechaInscripcionAsignada
    estado
    bloqueado
    motivoBloqueo
    boletaGenerada
    numeroBoleta
    materiasInscritas {
      materia {
        codigo
        nombre
        creditos
      }
      grupo
    }
  }
}
```

## 📊 Modelos de Datos

### Principales Entidades

1. **Carrera**: Carreras universitarias disponibles
2. **PlanEstudios**: Planes de estudio por carrera
3. **Materia**: Materias del plan de estudios
4. **MateriaCarreraSemestre**: Relación materia-carrera-semestre
5. **Estudiante**: Datos de los estudiantes
6. **PeriodoAcademico**: Periodos académicos (gestiones)
7. **Inscripcion**: Inscripciones de estudiantes
8. **InscripcionMateria**: Materias inscritas por estudiante

## 🔧 Comandos Útiles

### Detener los contenedores

```bash
docker-compose down
```

### Ver logs

```bash
docker-compose logs -f
```

### Ejecutar migraciones manualmente

```bash
docker-compose exec web python manage.py migrate
```

### Crear superusuario para el admin

```bash
docker-compose exec web python manage.py createsuperuser
```

### Cargar datos de prueba manualmente

```bash
docker-compose exec web python manage.py loaddata initial_data.json
```

## 🌐 Configuración CORS

El backend está configurado para aceptar peticiones desde cualquier origen (`CORS_ALLOW_ALL_ORIGINS = True`).

**Para producción**, edita `inscripcion_backend/settings.py` y especifica los orígenes permitidos:

```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://192.168.1.100:3000",
    # Agrega aquí las IPs/dominios de tu frontend
]
```

## 📁 Estructura del Proyecto

```
backend_inscripción/
├── docker-compose.yml          # Configuración de Docker Compose
├── Dockerfile                  # Imagen de Docker
├── requirements.txt            # Dependencias de Python
├── manage.py                   # Script de gestión de Django
├── initial_data.json           # Datos de prueba
├── inscripcion_backend/        # Configuración del proyecto
│   ├── settings.py            # Configuración de Django
│   ├── urls.py                # URLs principales
│   └── ...
└── inscripcion/                # App principal
    ├── models.py              # Modelos de datos
    ├── schema.py              # Schema GraphQL
    ├── admin.py               # Configuración del admin
    └── ...
```

## 🐛 Troubleshooting

### Error: Puerto 8000 ya en uso

```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
```

### Error: Puerto 5432 ya en uso (PostgreSQL)

Detén cualquier instancia de PostgreSQL local o cambia el puerto en `docker-compose.yml`.

### Reiniciar la base de datos

```bash
docker-compose down -v
docker-compose up --build
```

## 📝 Notas Importantes

- El sistema **NO requiere autenticación** (acceso por ID de estudiante)
- El servidor escucha en `0.0.0.0:8000` para permitir conexiones externas
- Los datos de prueba se cargan automáticamente al iniciar
- El periodo académico `1/2026` está activo por defecto

## 🚀 Próximos Pasos

1. Conectar el frontend a `http://<IP_SERVIDOR>:8000/graphql/`
2. Usar los queries de ejemplo para obtener datos
3. Crear más estudiantes y datos de prueba según necesites
4. Configurar CORS específico para producción

## 📧 Soporte

Para problemas o consultas, revisa los logs con:

```bash
docker-compose logs -f web
```

---

**Desarrollado con Django 4.2, Graphene-Django 3.2 y PostgreSQL 15**
