from django.db import models

from .inscripcion import Inscripcion


class ConceptoPago(models.Model):
    """Conceptos de Pago"""
    nombre = models.CharField(max_length=100, verbose_name="Concepto")
    monto = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Monto")
    obligatorio = models.BooleanField(default=True, verbose_name="Obligatorio")

    class Meta:
        verbose_name = "Concepto de Pago"
        verbose_name_plural = "Conceptos de Pago"

    def __str__(self):
        return f"{self.nombre} - {self.monto} Bs"


class Boleta(models.Model):
    """Boletas"""
    ESTADO_PAGO_CHOICES = [
        ('PENDIENTE', 'Pendiente'),
        ('PAGADO', 'Pagado'),
        ('ANULADO', 'Anulado'),
    ]

    inscripcion = models.OneToOneField(Inscripcion, on_delete=models.CASCADE, related_name='boleta_pago')
    fecha_emision = models.DateField(auto_now_add=True, verbose_name="Fecha de Emisión")
    total = models.DecimalField(max_digits=10, decimal_places=2, default=0, verbose_name="Total")
    estado = models.CharField(max_length=20, choices=ESTADO_PAGO_CHOICES, default='PENDIENTE')
    transaccion_id = models.CharField(max_length=100, null=True, blank=True, verbose_name="ID de Transacción Externo")

    class Meta:
        verbose_name = "Boleta"
        verbose_name_plural = "Boletas"

    def __str__(self):
        return f"Boleta {self.inscripcion.numero_boleta} - {self.inscripcion.estudiante_carrera.estudiante.registro}"


class DetalleBoleta(models.Model):
    """Detalles de Boleta"""
    boleta = models.ForeignKey(Boleta, on_delete=models.CASCADE, related_name='detalles')
    concepto = models.ForeignKey(ConceptoPago, on_delete=models.PROTECT, related_name='boletas')
    monto = models.DecimalField(max_digits=10, decimal_places=2, verbose_name="Monto Aplicado")

    class Meta:
        verbose_name = "Detalle de Boleta"
        verbose_name_plural = "Detalles de Boleta"

    def __str__(self):
        return f"{self.concepto.nombre} en Boleta {self.boleta.id}"
