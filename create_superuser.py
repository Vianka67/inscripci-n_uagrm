#!/usr/bin/env python
"""
Script para crear un superusuario automáticamente si no existe
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'inscripcion_backend.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser(
        username='admin',
        email='admin@inscripcion.edu.bo',
        password='admin123'
    )
    print('✅ Superusuario creado exitosamente')
    print('   Usuario: admin')
    print('   Password: admin123')
else:
    print('ℹ️  El superusuario ya existe')
