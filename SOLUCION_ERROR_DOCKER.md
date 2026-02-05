# SOLUCION AL ERROR DE DOCKER

## Problema Detectado

El error "exec format error" indica que Docker está intentando ejecutar contenedores en una arquitectura incompatible con tu sistema.

## Soluciones Disponibles

### OPCION 1: Configurar Docker Desktop (RECOMENDADA)

1. Abre Docker Desktop
2. Ve a Settings (Configuración)
3. En la sección "General", busca "Use the WSL 2 based engine"
4. Si está activado, desactívalo temporalmente
5. Reinicia Docker Desktop
6. Intenta nuevamente: `docker-compose up --build`

### OPCION 2: Limpiar Cache de Docker

```powershell
# Detener todos los contenedores
docker-compose down

# Limpiar cache de Docker
docker system prune -a --volumes

# Intentar nuevamente
docker-compose up --build
```

### OPCION 3: Ejecutar SIN Docker (Instalación Local)

Si Docker sigue dando problemas, puedes ejecutar el proyecto localmente:

#### Requisitos

- Python 3.11
- PostgreSQL 15

#### Pasos

1. **Instalar PostgreSQL**
   - Descarga desde: <https://www.postgresql.org/download/windows/>
   - Instala con usuario: `admin` y password: `admin123`
   - Crea una base de datos llamada: `inscripcion_db`

2. **Crear entorno virtual de Python**

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

1. **Instalar dependencias**

```powershell
pip install -r requirements.txt
```

1. **Configurar la base de datos**
Edita `inscripcion_backend/settings.py` y cambia:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'inscripcion_db',
        'USER': 'admin',
        'PASSWORD': 'admin123',
        'HOST': 'localhost',  # Cambiar de 'db' a 'localhost'
        'PORT': '5432',
    }
}
```

1. **Ejecutar migraciones**

```powershell
python manage.py migrate
```

1. **Cargar datos de prueba**

```powershell
python manage.py loaddata initial_data.json
```

1. **Crear superusuario**

```powershell
python create_superuser.py
```

1. **Iniciar el servidor**

```powershell
python manage.py runserver 0.0.0.0:8000
```

1. **Acceder**

- GraphQL: <http://localhost:8000/graphql/>
- Admin: <http://localhost:8000/admin/>

### OPCION 4: Usar Docker con Plataforma Específica

Edita `docker-compose.yml` y agrega la plataforma:

```yaml
services:
  web:
    platform: linux/amd64
    build: .
    # ... resto de la configuración
```

Luego ejecuta:

```powershell
docker-compose build --no-cache
docker-compose up
```

## Verificar Arquitectura de Docker

```powershell
docker version
docker info | findstr "Architecture"
```

## Contacto

Si ninguna solución funciona, por favor comparte:

1. La salida de: `docker version`
2. La salida de: `docker info`
3. Tu versión de Windows

---

**Recomendación**: Prueba primero la OPCION 1 (configurar Docker Desktop).
