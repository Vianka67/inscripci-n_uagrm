import json
from django.test import Client

c = Client()
endpoints = [
    '/api/estudiante/2150826/periodo-habilitado',
    '/api/estudiante/2150826/fechas-inscripcion',
    '/api/estudiante/2150826/bloqueo',
    '/api/estudiante/2150826/materias-habilitadas',
    '/api/estudiante/2150826/boleta',
]

print("="*60)
print("   VISUALIZANDO DATOS DEL BACKEND (Respuesta JSON)")
print("="*60)

for url in endpoints:
    print(f"\n📡 SOLICITUD: {url}")
    response = c.get(url)
    if response.status_code == 200:
        data = response.json()
        print(json.dumps(data, indent=2, ensure_ascii=False))
    else:
        print(f"❌ Error: {response.status_code}")
    print("-" * 60)
