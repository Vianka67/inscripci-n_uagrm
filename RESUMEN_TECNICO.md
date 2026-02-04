# 📋 RESUMEN TÉCNICO - SISTEMA DE INSCRIPCIÓN UNIVERSITARIA

## ✅ ARCHIVOS GENERADOS

### 🐳 Configuración Docker

- ✅ `docker-compose.yml` - Orquestación de servicios (PostgreSQL + Django)
- ✅ `Dockerfile` - Imagen de Docker para Django
- ✅ `.gitignore` - Archivos a ignorar en Git

### ⚙️ Configuración Django

- ✅ `manage.py` - Script de gestión de Django
- ✅ `requirements.txt` - Dependencias de Python
- ✅ `inscripcion_backend/settings.py` - Configuración principal
- ✅ `inscripcion_backend/urls.py` - Rutas URL
- ✅ `inscripcion_backend/wsgi.py` - WSGI config
- ✅ `inscripcion_backend/asgi.py` - ASGI config

### 📊 Modelos y Schema

- ✅ `inscripcion/models.py` - 8 modelos de datos
- ✅ `inscripcion/schema.py` - Schema GraphQL completo
- ✅ `inscripcion/admin.py` - Configuración del admin
- ✅ `inscripcion/apps.py` - Configuración de la app

### 📝 Datos y Documentación

- ✅ `initial_data.json` - Datos de prueba (fixtures)
- ✅ `create_superuser.py` - Script para crear admin
- ✅ `README.md` - Documentación completa
- ✅ `queries_examples.graphql` - Ejemplos de queries
- ✅ `start.ps1` - Script de inicio rápido

---

## 📊 MODELOS DE DATOS

### 1. Carrera

```
- codigo (PK, único)
- nombre
- facultad
- duracion_semestres
- activa
```

### 2. PlanEstudios

```
- id (PK)
- carrera (FK)
- codigo (único)
- nombre
- anio_vigencia
- vigente
```

### 3. Materia

```
- id (PK)
- codigo (único)
- nombre
- creditos
- horas_teoricas
- horas_practicas
```

### 4. MateriaCarreraSemestre

```
- id (PK)
- carrera (FK)
- plan_estudios (FK)
- materia (FK)
- semestre
- obligatoria
- habilitada
```

### 5. Estudiante

```
- registro (PK, único)
- nombre
- apellido_paterno
- apellido_materno
- carrera_actual (FK)
- semestre_actual
- plan_estudios (FK)
- modalidad (PRESENCIAL/SEMIPRESENCIAL/VIRTUAL)
- lugar_origen
- email
- telefono
- activo
- fecha_ingreso
```

### 6. PeriodoAcademico

```
- id (PK)
- codigo (único)
- nombre
- tipo
- fecha_inicio
- fecha_fin
- activo
- inscripciones_habilitadas
```

### 7. Inscripcion

```
- id (PK)
- estudiante (FK)
- periodo_academico (FK)
- fecha_inscripcion_asignada
- fecha_inscripcion_realizada
- estado (PENDIENTE/CONFIRMADA/CANCELADA)
- bloqueado
- motivo_bloqueo
- boleta_generada
- numero_boleta
```

### 8. InscripcionMateria

```
- id (PK)
- inscripcion (FK)
- materia (FK)
- grupo
```

---

## 🔍 QUERIES GRAPHQL DISPONIBLES

### Queries para Inicio

1. `todasCarreras` - Lista de carreras
2. `carreraPorCodigo` - Carrera específica
3. `semestresPorCarrera` - Semestres de una carrera

### Queries de Perfil

4. `perfilEstudiante` - Datos completos del estudiante
2. `estudiantePorRegistro` - Estudiante por registro

### Queries de Módulos

6. `fechaInscripcionEstudiante` - Fecha asignada
2. `estadoBloqueoEstudiante` - Si está bloqueado
3. `motivoBloqueoEstudiante` - Motivo del bloqueo
4. `materiasHabilitadas` - Materias del semestre
5. `periodoHabilitado` - Periodo activo
6. `boletaEstudiante` - Boleta de inscripción

### Queries Completas

12. `inscripcionCompleta` - Toda la info de inscripción

### Queries Adicionales

13. `todosPeriodos` - Todos los periodos
2. `todasMaterias` - Todas las materias

---

## 🚀 INSTRUCCIONES DE USO

### Inicio Rápido (Opción 1 - Recomendada)

```powershell
.\start.ps1
```

### Inicio Manual (Opción 2)

```powershell
docker-compose up --build
```

### Accesos

- **GraphQL**: <http://localhost:8000/graphql/>
- **Admin**: <http://localhost:8000/admin/>
  - Usuario: `admin`
  - Password: `admin123`

### Estudiantes de Prueba

- **218001234** - Juan Carlos Pérez García (Sin bloqueo)
- **219005678** - María Fernanda López Martínez (Bloqueado)

---

## 🔧 COMANDOS ÚTILES

### Ver logs

```powershell
docker-compose logs -f
```

### Detener servicios

```powershell
docker-compose down
```

### Reiniciar desde cero

```powershell
docker-compose down -v
docker-compose up --build
```

### Ejecutar migraciones

```powershell
docker-compose exec web python manage.py migrate
```

### Crear superusuario manual

```powershell
docker-compose exec web python manage.py createsuperuser
```

### Cargar datos de prueba

```powershell
docker-compose exec web python manage.py loaddata initial_data.json
```

---

## 🌐 CONFIGURACIÓN CORS

El backend está configurado para aceptar conexiones desde cualquier origen:

```python
CORS_ALLOW_ALL_ORIGINS = True
```

Para producción, edita `settings.py` y especifica los orígenes:

```python
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://192.168.1.100:3000",
]
```

---

## 📡 CONEXIÓN DESDE FRONTEND

### Endpoint GraphQL

```
http://<IP_SERVIDOR>:8000/graphql/
```

### Ejemplo de Query desde Frontend

```javascript
const query = `
  query {
    perfilEstudiante(registro: "218001234") {
      nombreCompleto
      carreraActual {
        nombre
      }
      semestreActual
    }
  }
`;

fetch('http://localhost:8000/graphql/', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ query })
})
.then(res => res.json())
.then(data => console.log(data));
```

---

## 📦 DEPENDENCIAS INSTALADAS

- Django 4.2.9
- psycopg2-binary 2.9.9 (PostgreSQL adapter)
- graphene-django 3.2.0 (GraphQL)
- django-cors-headers 4.3.1 (CORS)
- django-filter 23.5 (Filtros)
- python-decouple 3.8 (Variables de entorno)

---

## 🎯 CARACTERÍSTICAS IMPLEMENTADAS

✅ API GraphQL completa con Graphene-Django
✅ Base de datos PostgreSQL con modelos relacionales
✅ Docker & Docker Compose configurado
✅ CORS habilitado para conexiones externas
✅ Datos de prueba incluidos
✅ Panel de administración de Django
✅ Sin autenticación (acceso por ID de estudiante)
✅ Servidor escuchando en 0.0.0.0:8000
✅ Healthcheck para PostgreSQL
✅ Auto-carga de datos al iniciar
✅ Creación automática de superusuario

---

## 📁 ESTRUCTURA DEL PROYECTO

```
backend_inscripción/
├── 📄 docker-compose.yml          # Orquestación de servicios
├── 📄 Dockerfile                  # Imagen de Docker
├── 📄 requirements.txt            # Dependencias
├── 📄 manage.py                   # Script de gestión
├── 📄 initial_data.json           # Datos de prueba
├── 📄 create_superuser.py         # Script superusuario
├── 📄 README.md                   # Documentación
├── 📄 queries_examples.graphql    # Ejemplos de queries
├── 📄 start.ps1                   # Script de inicio
├── 📄 .gitignore                  # Git ignore
│
├── 📁 inscripcion_backend/        # Configuración Django
│   ├── __init__.py
│   ├── settings.py               # Configuración principal
│   ├── urls.py                   # URLs
│   ├── wsgi.py                   # WSGI
│   └── asgi.py                   # ASGI
│
└── 📁 inscripcion/                # App principal
    ├── __init__.py
    ├── models.py                 # 8 modelos de datos
    ├── schema.py                 # Schema GraphQL
    ├── admin.py                  # Admin de Django
    └── apps.py                   # Config de la app
```

---

## ✅ CHECKLIST DE ENTREGA

- [x] Modelos de datos completos (8 modelos)
- [x] Schema GraphQL con todos los Types y Queries
- [x] Docker Compose con PostgreSQL y Django
- [x] CORS configurado para conexiones externas
- [x] Datos de prueba (2 estudiantes, 3 carreras, 6 materias)
- [x] Sin autenticación (acceso por ID)
- [x] Servidor en 0.0.0.0:8000
- [x] Documentación completa
- [x] Scripts de inicio rápido
- [x] Ejemplos de queries GraphQL

---

## 🎓 DATOS DE PRUEBA INCLUIDOS

### Carreras

- ING-SIS - Ingeniería de Sistemas (10 semestres)
- ING-IND - Ingeniería Industrial (10 semestres)
- MED - Medicina (12 semestres)

### Estudiantes

1. **218001234** - Juan Carlos Pérez García
   - Carrera: Ingeniería de Sistemas
   - Semestre: 3
   - Estado: Activo, sin bloqueo
   - Email: <juan.perez@estudiante.uagrm.edu.bo>

2. **219005678** - María Fernanda López Martínez
   - Carrera: Ingeniería de Sistemas
   - Semestre: 2
   - Estado: Bloqueado (Deuda en biblioteca)
   - Email: <maria.lopez@estudiante.uagrm.edu.bo>

### Periodo Académico Activo

- Código: 1/2026
- Nombre: Primer Semestre 2026
- Fechas: 01/03/2026 - 31/07/2026
- Inscripciones: Habilitadas

---

## 🔐 CREDENCIALES DE ACCESO

### Panel de Administración

- URL: <http://localhost:8000/admin/>
- Usuario: `admin`
- Password: `admin123`

---

## 📞 SOPORTE

Para problemas o consultas:

1. Revisar logs: `docker-compose logs -f web`
2. Verificar estado: `docker-compose ps`
3. Reiniciar servicios: `docker-compose restart`
4. Limpiar y reiniciar: `docker-compose down -v && docker-compose up --build`

---

**✨ Backend desarrollado con Django 4.2, Graphene-Django 3.2 y PostgreSQL 15**

**🚀 Listo para conectar con el Frontend**
