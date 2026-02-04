# 🧪 GUÍA DE TESTING Y EJEMPLOS DE INTEGRACIÓN

## 🚀 Inicio Rápido para Testing

### 1. Iniciar el Backend

```powershell
.\start.ps1
```

O manualmente:

```powershell
docker-compose up --build
```

### 2. Verificar que está funcionando

Abre tu navegador en: <http://localhost:8000/graphql/>

Deberías ver el **GraphQL Playground** (interfaz interactiva).

---

## 📝 Ejemplos de Testing en GraphQL Playground

### Test 1: Verificar Carreras Disponibles

```graphql
query TestCarreras {
  todasCarreras(activa: true) {
    codigo
    nombre
    facultad
    duracionSemestres
  }
}
```

**Resultado Esperado:**

```json
{
  "data": {
    "todasCarreras": [
      {
        "codigo": "ING-SIS",
        "nombre": "Ingeniería de Sistemas",
        "facultad": "Facultad de Ciencias Exactas y Tecnología",
        "duracionSemestres": 10
      },
      {
        "codigo": "ING-IND",
        "nombre": "Ingeniería Industrial",
        "facultad": "Facultad de Ciencias Exactas y Tecnología",
        "duracionSemestres": 10
      },
      {
        "codigo": "MED",
        "nombre": "Medicina",
        "facultad": "Facultad de Medicina",
        "duracionSemestres": 12
      }
    ]
  }
}
```

---

### Test 2: Perfil de Estudiante

```graphql
query TestPerfilEstudiante {
  perfilEstudiante(registro: "218001234") {
    registro
    nombreCompleto
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
  }
}
```

**Resultado Esperado:**

```json
{
  "data": {
    "perfilEstudiante": {
      "registro": "218001234",
      "nombreCompleto": "Juan Carlos Pérez García",
      "carreraActual": {
        "codigo": "ING-SIS",
        "nombre": "Ingeniería de Sistemas"
      },
      "semestreActual": 3,
      "planEstudios": {
        "codigo": "PLAN-SIS-2020",
        "nombre": "Plan de Estudios Ingeniería de Sistemas 2020"
      },
      "modalidad": "PRESENCIAL",
      "lugarOrigen": "Santa Cruz de la Sierra",
      "email": "juan.perez@estudiante.uagrm.edu.bo"
    }
  }
}
```

---

### Test 3: Verificar Estado de Bloqueo

```graphql
query TestBloqueo {
  estudiante1: estadoBloqueoEstudiante(registro: "218001234")
  estudiante2: estadoBloqueoEstudiante(registro: "219005678")
  motivoEstudiante2: motivoBloqueoEstudiante(registro: "219005678")
}
```

**Resultado Esperado:**

```json
{
  "data": {
    "estudiante1": false,
    "estudiante2": true,
    "motivoEstudiante2": "Deuda pendiente en biblioteca"
  }
}
```

---

### Test 4: Materias Habilitadas

```graphql
query TestMateriasHabilitadas {
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
    habilitada
  }
}
```

**Resultado Esperado:**

```json
{
  "data": {
    "materiasHabilitadas": [
      {
        "materia": {
          "codigo": "BD-201",
          "nombre": "Base de Datos I",
          "creditos": 6,
          "horasTeorica": 4,
          "horasPracticas": 4
        },
        "semestre": 3,
        "obligatoria": true,
        "habilitada": true
      }
    ]
  }
}
```

---

### Test 5: Periodo Habilitado

```graphql
query TestPeriodoHabilitado {
  periodoHabilitado {
    codigo
    nombre
    tipo
    fechaInicio
    fechaFin
    activo
    inscripcionesHabilitadas
  }
}
```

**Resultado Esperado:**

```json
{
  "data": {
    "periodoHabilitado": {
      "codigo": "1/2026",
      "nombre": "Primer Semestre 2026",
      "tipo": "1/2026",
      "fechaInicio": "2026-03-01",
      "fechaFin": "2026-07-31",
      "activo": true,
      "inscripcionesHabilitadas": true
    }
  }
}
```

---

## 🌐 Integración con Frontend

### Ejemplo 1: React con Fetch API

```javascript
// services/graphql.js
const GRAPHQL_ENDPOINT = 'http://localhost:8000/graphql/';

export const fetchEstudianteProfile = async (registro) => {
  const query = `
    query {
      perfilEstudiante(registro: "${registro}") {
        registro
        nombreCompleto
        carreraActual {
          codigo
          nombre
        }
        semestreActual
        modalidad
        email
      }
    }
  `;

  try {
    const response = await fetch(GRAPHQL_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ query }),
    });

    const result = await response.json();
    return result.data.perfilEstudiante;
  } catch (error) {
    console.error('Error fetching student profile:', error);
    throw error;
  }
};

// Uso en componente
import React, { useEffect, useState } from 'react';
import { fetchEstudianteProfile } from './services/graphql';

function StudentProfile({ registro }) {
  const [student, setStudent] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchEstudianteProfile(registro)
      .then(data => {
        setStudent(data);
        setLoading(false);
      })
      .catch(error => {
        console.error(error);
        setLoading(false);
      });
  }, [registro]);

  if (loading) return <div>Cargando...</div>;
  if (!student) return <div>Estudiante no encontrado</div>;

  return (
    <div>
      <h2>{student.nombreCompleto}</h2>
      <p>Registro: {student.registro}</p>
      <p>Carrera: {student.carreraActual.nombre}</p>
      <p>Semestre: {student.semestreActual}</p>
      <p>Email: {student.email}</p>
    </div>
  );
}
```

---

### Ejemplo 2: React con Apollo Client

```javascript
// apollo-client.js
import { ApolloClient, InMemoryCache, gql } from '@apollo/client';

export const client = new ApolloClient({
  uri: 'http://localhost:8000/graphql/',
  cache: new InMemoryCache(),
});

// queries.js
import { gql } from '@apollo/client';

export const GET_STUDENT_PROFILE = gql`
  query GetStudentProfile($registro: String!) {
    perfilEstudiante(registro: $registro) {
      registro
      nombreCompleto
      carreraActual {
        codigo
        nombre
      }
      semestreActual
      modalidad
      email
    }
  }
`;

export const GET_MATERIAS_HABILITADAS = gql`
  query GetMateriasHabilitadas($registro: String!) {
    materiasHabilitadas(registro: $registro) {
      materia {
        codigo
        nombre
        creditos
      }
      semestre
      obligatoria
    }
  }
`;

// StudentProfile.jsx
import React from 'react';
import { useQuery } from '@apollo/client';
import { GET_STUDENT_PROFILE } from './queries';

function StudentProfile({ registro }) {
  const { loading, error, data } = useQuery(GET_STUDENT_PROFILE, {
    variables: { registro },
  });

  if (loading) return <p>Cargando...</p>;
  if (error) return <p>Error: {error.message}</p>;

  const student = data.perfilEstudiante;

  return (
    <div className="student-profile">
      <h2>{student.nombreCompleto}</h2>
      <div className="info">
        <p><strong>Registro:</strong> {student.registro}</p>
        <p><strong>Carrera:</strong> {student.carreraActual.nombre}</p>
        <p><strong>Semestre:</strong> {student.semestreActual}</p>
        <p><strong>Modalidad:</strong> {student.modalidad}</p>
        <p><strong>Email:</strong> {student.email}</p>
      </div>
    </div>
  );
}

export default StudentProfile;
```

---

### Ejemplo 3: Vue.js con Axios

```javascript
// services/api.js
import axios from 'axios';

const GRAPHQL_ENDPOINT = 'http://localhost:8000/graphql/';

export const graphqlClient = axios.create({
  baseURL: GRAPHQL_ENDPOINT,
  headers: {
    'Content-Type': 'application/json',
  },
});

export const getStudentProfile = async (registro) => {
  const query = `
    query {
      perfilEstudiante(registro: "${registro}") {
        registro
        nombreCompleto
        carreraActual {
          nombre
        }
        semestreActual
      }
    }
  `;

  const response = await graphqlClient.post('', { query });
  return response.data.data.perfilEstudiante;
};

export const getMateriasHabilitadas = async (registro) => {
  const query = `
    query {
      materiasHabilitadas(registro: "${registro}") {
        materia {
          codigo
          nombre
          creditos
        }
        semestre
      }
    }
  `;

  const response = await graphqlClient.post('', { query });
  return response.data.data.materiasHabilitadas;
};

// StudentProfile.vue
<template>
  <div v-if="loading">Cargando...</div>
  <div v-else-if="student" class="student-profile">
    <h2>{{ student.nombreCompleto }}</h2>
    <p>Registro: {{ student.registro }}</p>
    <p>Carrera: {{ student.carreraActual.nombre }}</p>
    <p>Semestre: {{ student.semestreActual }}</p>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue';
import { getStudentProfile } from '@/services/api';

export default {
  props: ['registro'],
  setup(props) {
    const student = ref(null);
    const loading = ref(true);

    onMounted(async () => {
      try {
        student.value = await getStudentProfile(props.registro);
      } catch (error) {
        console.error('Error:', error);
      } finally {
        loading.value = false;
      }
    });

    return { student, loading };
  }
};
</script>
```

---

### Ejemplo 4: Angular con HttpClient

```typescript
// services/graphql.service.ts
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable({
  providedIn: 'root'
})
export class GraphqlService {
  private endpoint = 'http://localhost:8000/graphql/';

  constructor(private http: HttpClient) {}

  getStudentProfile(registro: string): Observable<any> {
    const query = `
      query {
        perfilEstudiante(registro: "${registro}") {
          registro
          nombreCompleto
          carreraActual {
            nombre
          }
          semestreActual
          email
        }
      }
    `;

    return this.http.post(this.endpoint, { query }).pipe(
      map((result: any) => result.data.perfilEstudiante)
    );
  }

  getMateriasHabilitadas(registro: string): Observable<any> {
    const query = `
      query {
        materiasHabilitadas(registro: "${registro}") {
          materia {
            codigo
            nombre
            creditos
          }
          semestre
        }
      }
    `;

    return this.http.post(this.endpoint, { query }).pipe(
      map((result: any) => result.data.materiasHabilitadas)
    );
  }
}

// student-profile.component.ts
import { Component, OnInit } from '@angular/core';
import { GraphqlService } from './services/graphql.service';

@Component({
  selector: 'app-student-profile',
  templateUrl: './student-profile.component.html'
})
export class StudentProfileComponent implements OnInit {
  student: any;
  loading = true;

  constructor(private graphqlService: GraphqlService) {}

  ngOnInit() {
    this.graphqlService.getStudentProfile('218001234').subscribe(
      data => {
        this.student = data;
        this.loading = false;
      },
      error => {
        console.error('Error:', error);
        this.loading = false;
      }
    );
  }
}
```

---

## 🔍 Testing desde Postman

### Configuración

1. Abre Postman
2. Crea una nueva request POST
3. URL: `http://localhost:8000/graphql/`
4. Headers: `Content-Type: application/json`
5. Body (raw, JSON):

```json
{
  "query": "query { perfilEstudiante(registro: \"218001234\") { nombreCompleto carreraActual { nombre } } }"
}
```

---

## 🧪 Testing desde cURL

```bash
# Test 1: Perfil de estudiante
curl -X POST http://localhost:8000/graphql/ \
  -H "Content-Type: application/json" \
  -d '{"query": "{ perfilEstudiante(registro: \"218001234\") { nombreCompleto } }"}'

# Test 2: Carreras disponibles
curl -X POST http://localhost:8000/graphql/ \
  -H "Content-Type: application/json" \
  -d '{"query": "{ todasCarreras { codigo nombre } }"}'

# Test 3: Estado de bloqueo
curl -X POST http://localhost:8000/graphql/ \
  -H "Content-Type: application/json" \
  -d '{"query": "{ estadoBloqueoEstudiante(registro: \"219005678\") }"}'
```

---

## 📊 Casos de Prueba Completos

### Caso 1: Flujo de Inicio de Sesión

```graphql
# 1. Obtener carreras
query { todasCarreras { codigo nombre } }

# 2. Obtener semestres de una carrera
query { semestresPorCarrera(codigoCarrera: "ING-SIS") }

# 3. Verificar estudiante
query { perfilEstudiante(registro: "218001234") { nombreCompleto } }
```

### Caso 2: Dashboard del Estudiante

```graphql
query DashboardCompleto {
  perfil: perfilEstudiante(registro: "218001234") {
    nombreCompleto
    carreraActual { nombre }
    semestreActual
  }
  
  bloqueado: estadoBloqueoEstudiante(registro: "218001234")
  
  materias: materiasHabilitadas(registro: "218001234") {
    materia { codigo nombre creditos }
  }
  
  periodo: periodoHabilitado {
    nombre
    fechaInicio
    fechaFin
  }
}
```

### Caso 3: Proceso de Inscripción

```graphql
query ProcesoInscripcion {
  # Verificar bloqueo
  bloqueado: estadoBloqueoEstudiante(registro: "218001234")
  motivo: motivoBloqueoEstudiante(registro: "218001234")
  
  # Obtener fecha de inscripción
  fecha: fechaInscripcionEstudiante(registro: "218001234")
  
  # Materias disponibles
  materias: materiasHabilitadas(registro: "218001234") {
    materia { codigo nombre creditos }
  }
  
  # Periodo activo
  periodo: periodoHabilitado {
    nombre
    inscripcionesHabilitadas
  }
}
```

---

## ✅ Checklist de Testing

- [ ] Backend inicia correctamente con `docker-compose up`
- [ ] GraphQL Playground accesible en <http://localhost:8000/graphql/>
- [ ] Admin panel accesible en <http://localhost:8000/admin/>
- [ ] Query `todasCarreras` retorna 3 carreras
- [ ] Query `perfilEstudiante` con registro "218001234" retorna datos
- [ ] Query `estadoBloqueoEstudiante` con "219005678" retorna `true`
- [ ] Query `materiasHabilitadas` retorna materias del semestre 3
- [ ] Query `periodoHabilitado` retorna periodo 1/2026
- [ ] Conexión desde frontend externo funciona (CORS)
- [ ] Datos persisten después de reiniciar contenedores

---

## 🐛 Troubleshooting

### Error: "Cannot query field X on type Y"

**Solución**: Verifica que el nombre del campo esté en camelCase (ej: `nombreCompleto`, no `nombre_completo`)

### Error: CORS policy

**Solución**: Verifica que `CORS_ALLOW_ALL_ORIGINS = True` esté en `settings.py`

### Error: Connection refused

**Solución**: Verifica que el backend esté corriendo con `docker-compose ps`

### Error: Null response

**Solución**: Verifica que los datos de prueba estén cargados con `docker-compose logs web`

---

**🧪 Happy Testing!**
