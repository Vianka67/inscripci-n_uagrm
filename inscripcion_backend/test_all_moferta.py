import os
import django
import json

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')
django.setup()

from apps.inscripcion.schema import schema

query = """
    query GetOfertasMaster($registro: Int!, $carr: Int!, $plan: String!, $lugar: Int!, $sem: String!, $ano: Int!) {
      allMoferta(registro: $registro, carr: $carr, plan: $plan, lugar: $lugar, sem: $sem, ano: $ano) {
        materiaCodigo
        materiaNombre
        semestre
        grupo
        horario
        docente
        cuposDisponibles
        cupoActual
      }
    }
"""
variables = {
    "registro": 218001234,
    "carr": 0,
    "plan": "1",
    "lugar": 4271,
    "sem": "1",
    "ano": 2026
}
result = schema.execute(query, variables=variables)
print(json.dumps({
    "errors": [str(e) for e in result.errors] if result.errors else None,
    "data": result.data
}, indent=2))
