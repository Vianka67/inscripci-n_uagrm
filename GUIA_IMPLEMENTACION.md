# 🚀 GUÍA DE IMPLEMENTACIÓN - BACKEND REESTRUCTURADO

Esta guía te ayudará a completar la implementación de la reestructuración del backend.

---

## 📋 PREREQUISITOS

- Docker y Docker Compose instalados
- Python 3.9+ (si ejecutas sin Docker)
- PostgreSQL (si ejecutas sin Docker)

---

## 🔧 PASO 1: CREAR Y APLICAR MIGRACIONES

### Opción A: Con Docker (Recomendado)

```powershell
# 1. Iniciar los contenedores
docker-compose up -d

# 2. Crear migraciones
docker-compose exec web python manage.py makemigrations inscripcion

# 3. Aplicar migraciones
docker-compose exec web python manage.py migrate

# 4. Verificar que se aplicaron correctamente
docker-compose exec web python manage.py showmigrations inscripcion
```

### Opción B: Sin Docker

```powershell
# 1. Activar entorno virtual (si usas uno)
.\venv\Scripts\Activate.ps1

# 2. Crear migraciones
python manage.py makemigrations inscripcion

# 3. Aplicar migraciones
python manage.py migrate

# 4. Verificar
python manage.py showmigrations inscripcion
```

---

## 📊 PASO 2: CARGAR DATOS DE PRUEBA

### 2.1 Cargar datos iniciales (si no lo has hecho)

```powershell
# Con Docker
docker-compose exec web python manage.py loaddata initial_data.json

# Sin Docker
python manage.py loaddata initial_data.json
```

### 2.2 Crear bloqueos de prueba

```powershell
# Con Docker
docker-compose exec web python manage.py shell < crear_datos_bloqueos.py

# Sin Docker
python manage.py shell < crear_datos_bloqueos.py
```

---

## 🧪 PASO 3: PROBAR LAS NUEVAS QUERIES

### 3.1 Iniciar el servidor

```powershell
# Con Docker (ya está corriendo si hiciste docker-compose up)
docker-compose up

# Sin Docker
python manage.py runserver
```

### 3.2 Acceder a GraphiQL

Abre tu navegador en: **<http://localhost:8000/graphql>**

### 3.3 Probar Query: Panel del Estudiante

```graphql
query {
  panelEstudiante(registro: "2150826") {
    estudiante {
      registro
      nombreCompleto
    }
    carrera {
      codigo
      nombre
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

**Resultado esperado**: Toda la información del estudiante en una sola respuesta.

### 3.4 Probar Query: Bloqueos del Estudiante

```graphql
query {
  bloqueoEstudiante(registro: "2150826") {
    bloqueado
    bloqueos {
      id
      tipo
      motivo
      fechaBloqueo
      fechaDesbloqueoEstimada
      activo
    }
    puedeInscribirse
    mensaje
  }
}
```

**Resultado esperado**:

- `bloqueado: true`
- Lista de bloqueos con el bloqueo FINANCIERO activo
- `puedeInscribirse: false`
- Mensaje indicando que tiene bloqueos activos

### 3.5 Probar Query: Semestres por Carrera

```graphql
query {
  semestresCarrera(codigoCarrera: "DER") {
    carrera {
      codigo
      nombre
    }
    semestres {
      numero
      nombre
      habilitado
    }
    totalSemestres
  }
}
```

**Resultado esperado**: Lista estructurada de semestres para la carrera de Derecho.

### 3.6 Probar Query: Carreras Activas

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

**Resultado esperado**: Lista de todas las carreras activas.

---

## 🔍 PASO 4: VERIFICAR EN EL ADMIN DE DJANGO

### 4.1 Crear superusuario (si no existe)

```powershell
# Con Docker
docker-compose exec web python manage.py createsuperuser

# Sin Docker
python manage.py createsuperuser
```

### 4.2 Acceder al admin

Abre: **<http://localhost:8000/admin>**

### 4.3 Verificar modelo Bloqueo

1. Inicia sesión con tu superusuario
2. Ve a la sección **Inscripcion**
3. Deberías ver el modelo **Bloqueos**
4. Haz clic y verifica que puedes:
   - Ver la lista de bloqueos
   - Filtrar por tipo, activo, resuelto
   - Crear nuevos bloqueos
   - Editar bloqueos existentes

---

## 📝 PASO 5: CREAR BLOQUEOS MANUALMENTE (OPCIONAL)

### Desde el Admin de Django

1. Ve a **Bloqueos** → **Agregar bloqueo**
2. Selecciona un estudiante
3. Elige un tipo de bloqueo
4. Escribe el motivo
5. (Opcional) Establece fecha de desbloqueo estimada
6. Marca como **Activo**
7. Guarda

### Desde GraphiQL (si implementas mutations)

```graphql
mutation {
  crearBloqueo(
    registro: "2150826"
    tipo: "ADMINISTRATIVO"
    motivo: "Documentación pendiente"
    fechaDesbloqueo: "2026-03-15"
  ) {
    id
    tipo
    motivo
    activo
  }
}
```

---

## 🧹 PASO 6: MIGRAR DATOS EXISTENTES (SI APLICA)

Si tienes datos de bloqueos en el modelo `Inscripcion`, necesitas migrarlos:

### Opción A: Script manual

```python
# Ejecutar en Django shell
from inscripcion.models import Inscripcion, Bloqueo

# Migrar bloqueos
for inscripcion in Inscripcion.objects.filter(bloqueado=True):
    if inscripcion.motivo_bloqueo:
        Bloqueo.objects.get_or_create(
            estudiante=inscripcion.estudiante,
            defaults={
                'tipo': 'ADMINISTRATIVO',
                'motivo': inscripcion.motivo_bloqueo,
                'activo': True,
                'resuelto': False
            }
        )
        print(f"Migrado bloqueo para {inscripcion.estudiante.registro}")
```

### Opción B: Management command (recomendado)

Crear archivo: `inscripcion/management/commands/migrar_bloqueos.py`

```python
from django.core.management.base import BaseCommand
from inscripcion.models import Inscripcion, Bloqueo

class Command(BaseCommand):
    help = 'Migra bloqueos de Inscripcion a modelo Bloqueo'

    def handle(self, *args, **options):
        count = 0
        for inscripcion in Inscripcion.objects.filter(bloqueado=True):
            if inscripcion.motivo_bloqueo:
                Bloqueo.objects.get_or_create(
                    estudiante=inscripcion.estudiante,
                    defaults={
                        'tipo': 'ADMINISTRATIVO',
                        'motivo': inscripcion.motivo_bloqueo,
                        'activo': True,
                        'resuelto': False
                    }
                )
                count += 1
        self.stdout.write(
            self.style.SUCCESS(f'Migrados {count} bloqueos')
        )
```

Ejecutar:

```powershell
python manage.py migrar_bloqueos
```

---

## 🎨 PASO 7: ACTUALIZAR EL FRONTEND

### Antes (múltiples llamadas)

```javascript
// Múltiples queries
const estudiante = await fetchGraphQL(`
  query {
    estudiantePorRegistro(registro: "${registro}") { ... }
  }
`);

const bloqueado = await fetchGraphQL(`
  query {
    estadoBloqueoEstudiante(registro: "${registro}")
  }
`);

const inscripcion = await fetchGraphQL(`
  query {
    inscripcionCompleta(registro: "${registro}") { ... }
  }
`);

// Combinar datos manualmente
const panel = {
  estudiante: estudiante.data.estudiantePorRegistro,
  bloqueado: bloqueado.data.estadoBloqueoEstudiante,
  inscripcion: inscripcion.data.inscripcionCompleta,
  // ... más lógica
};
```

### Después (una sola llamada)

```javascript
// Una sola query obtiene todo
const panel = await fetchGraphQL(`
  query {
    panelEstudiante(registro: "${registro}") {
      estudiante { nombreCompleto }
      carrera { nombre }
      estado
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
      }
    }
  }
`);

// Datos listos para usar
const data = panel.data.panelEstudiante;
```

---

## ✅ CHECKLIST DE VERIFICACIÓN

Marca cada item cuando lo completes:

### Configuración

- [ ] Migraciones creadas
- [ ] Migraciones aplicadas
- [ ] Datos iniciales cargados
- [ ] Bloqueos de prueba creados
- [ ] Superusuario creado

### Pruebas GraphQL

- [ ] Query `panelEstudiante` funciona
- [ ] Query `bloqueoEstudiante` funciona
- [ ] Query `semestresCarrera` funciona
- [ ] Query `todasCarreras` funciona
- [ ] Queries de compatibilidad funcionan

### Admin de Django

- [ ] Modelo Bloqueo visible
- [ ] Puede crear bloqueos
- [ ] Puede editar bloqueos
- [ ] Puede filtrar bloqueos
- [ ] Puede buscar bloqueos

### Datos

- [ ] Datos existentes migrados (si aplica)
- [ ] Bloqueos de prueba verificados
- [ ] Relaciones correctas entre modelos

### Frontend (si aplica)

- [ ] Actualizado para usar nuevas queries
- [ ] Menos lógica de negocio
- [ ] Mejor rendimiento

---

## 🐛 SOLUCIÓN DE PROBLEMAS

### Error: "No module named 'inscripcion.services'"

**Solución**: Asegúrate de que existe el archivo `inscripcion/services/__init__.py`

### Error: "Bloqueo matching query does not exist"

**Solución**: Ejecuta el script de creación de datos de prueba:

```powershell
python manage.py shell < crear_datos_bloqueos.py
```

### Error: "Cannot query field 'panelEstudiante'"

**Solución**: Reinicia el servidor Django para que cargue las nuevas queries:

```powershell
# Con Docker
docker-compose restart web

# Sin Docker
# Ctrl+C y luego
python manage.py runserver
```

### Error en migraciones

**Solución**:

```powershell
# Ver estado de migraciones
python manage.py showmigrations

# Si hay conflictos, hacer merge
python manage.py makemigrations --merge
```

---

## 📚 RECURSOS ADICIONALES

- **Plan completo**: Ver `PLAN_REESTRUCTURACION.md`
- **Resumen**: Ver `RESUMEN_REESTRUCTURACION.md`
- **Ejemplos de queries**: Ver `queries_examples_nuevas.graphql`
- **Documentación Django**: <https://docs.djangoproject.com/>
- **Documentación Graphene**: <https://docs.graphene-python.org/>

---

## 🎯 PRÓXIMOS PASOS RECOMENDADOS

1. **Testing**: Crear tests unitarios para los nuevos servicios
2. **Documentación**: Documentar las nuevas APIs para el equipo
3. **Optimización**: Agregar caché para queries frecuentes
4. **Seguridad**: Implementar autenticación y autorización
5. **Monitoring**: Agregar logging y métricas

---

## 💡 CONSEJOS

- **Usa GraphiQL** para explorar el schema y probar queries
- **Revisa los logs** si algo no funciona como esperas
- **Mantén compatibilidad** con queries antiguas durante la transición
- **Documenta cambios** para el equipo de frontend
- **Haz backups** antes de migrar datos en producción

---

## ¡Éxito con la implementación! 🚀

Si tienes problemas, revisa los archivos de documentación o consulta los logs del servidor.
