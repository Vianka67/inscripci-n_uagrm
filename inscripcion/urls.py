from django.urls import path
from .views import (
    FechasInscripcionView,
    BloqueoView,
    MateriasHabilitadasView,
    PeriodoHabilitadoView,
    BoletaView
)

urlpatterns = [
    path('estudiante/<str:registro>/fechas-inscripcion', FechasInscripcionView.as_view(), name='fechas-inscripcion'),
    path('estudiante/<str:registro>/bloqueo', BloqueoView.as_view(), name='bloqueo'),
    path('estudiante/<str:registro>/materias-habilitadas', MateriasHabilitadasView.as_view(), name='materias-habilitadas'),
    path('estudiante/<str:registro>/periodo-habilitado', PeriodoHabilitadoView.as_view(), name='periodo-habilitado'),
    path('estudiante/<str:registro>/boleta', BoletaView.as_view(), name='boleta'),
]
