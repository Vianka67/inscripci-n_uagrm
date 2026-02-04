# 🎯 INICIO RÁPIDO - 5 MINUTOS

## ⚡ Pasos para Ejecutar el Backend

### 1️⃣ Abrir PowerShell en esta carpeta

```powershell
cd "c:\Users\User-DTIC\backend_inscripción"
```

### 2️⃣ Ejecutar el script de inicio

```powershell
.\start.ps1
```

### 3️⃣ Esperar a que inicie (2-3 minutos la primera vez)

### 4️⃣ Abrir el navegador

- **GraphQL Playground**: <http://localhost:8000/graphql/>
- **Panel Admin**: <http://localhost:8000/admin/> (usuario: `admin`, password: `admin123`)

---

## 🧪 Prueba Rápida

### En GraphQL Playground, pega esto

```graphql
query {
  perfilEstudiante(registro: "218001234") {
    nombreCompleto
    carreraActual {
      nombre
    }
    semestreActual
  }
}
```

### Presiona el botón ▶️ (Play)

### Deberías ver

```json
{
  "data": {
    "perfilEstudiante": {
      "nombreCompleto": "Juan Carlos Pérez García",
      "carreraActual": {
        "nombre": "Ingeniería de Sistemas"
      },
      "semestreActual": 3
    }
  }
}
```

---

## ✅ Si ves esto, ¡FUNCIONA

---

## 📚 Documentación Completa

- **README.md** - Instrucciones detalladas
- **RESUMEN_TECNICO.md** - Especificaciones técnicas
- **ARQUITECTURA.md** - Diagramas y arquitectura
- **TESTING.md** - Ejemplos de integración con frontend
- **queries_examples.graphql** - Todas las queries disponibles

---

## 👥 Estudiantes de Prueba

| Registro | Nombre | Estado |
|----------|--------|--------|
| 218001234 | Juan Carlos Pérez García | ✅ Sin bloqueo |
| 219005678 | María Fernanda López Martínez | 🔒 Bloqueado |

---

## 🛑 Para Detener el Backend

```powershell
docker-compose down
```

---

## 🔄 Para Reiniciar

```powershell
docker-compose restart
```

---

## 📞 ¿Problemas?

1. Verifica que Docker Desktop esté corriendo
2. Revisa los logs: `docker-compose logs -f`
3. Reinicia desde cero: `docker-compose down -v && docker-compose up --build`

---

## 🌐 Conectar desde Frontend

### Endpoint GraphQL

```
http://localhost:8000/graphql/
```

### Ejemplo JavaScript

```javascript
fetch('http://localhost:8000/graphql/', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    query: `
      query {
        perfilEstudiante(registro: "218001234") {
          nombreCompleto
        }
      }
    `
  })
})
.then(res => res.json())
.then(data => console.log(data));
```

---

## 📋 Queries Más Usadas

### 1. Obtener Perfil del Estudiante

```graphql
query {
  perfilEstudiante(registro: "218001234") {
    nombreCompleto
    carreraActual { nombre }
    semestreActual
    email
  }
}
```

### 2. Verificar Bloqueo

```graphql
query {
  estadoBloqueoEstudiante(registro: "218001234")
  motivoBloqueoEstudiante(registro: "218001234")
}
```

### 3. Materias Habilitadas

```graphql
query {
  materiasHabilitadas(registro: "218001234") {
    materia {
      codigo
      nombre
      creditos
    }
  }
}
```

### 4. Todas las Carreras

```graphql
query {
  todasCarreras {
    codigo
    nombre
    facultad
  }
}
```

---

## 🎉 ¡Listo para Usar

El backend está completamente configurado y listo para conectar con tu frontend.

**Siguiente paso**: Conecta tu aplicación frontend al endpoint GraphQL.

---

**💡 Tip**: Abre `queries_examples.graphql` para ver TODAS las queries disponibles.
