# Script de Inicio Rápido - Sistema de Inscripción

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SISTEMA DE INSCRIPCIÓN UNIVERSITARIA" -ForegroundColor Cyan
Write-Host "  Iniciando Backend..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si Docker está corriendo
Write-Host "Verificando Docker..." -ForegroundColor Yellow
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error: Docker no está corriendo" -ForegroundColor Red
    Write-Host "Por favor, inicia Docker Desktop y vuelve a ejecutar este script" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ Docker está corriendo" -ForegroundColor Green
Write-Host ""

# Detener contenedores previos si existen
Write-Host "Limpiando contenedores previos..." -ForegroundColor Yellow
docker-compose down 2>&1 | Out-Null
Write-Host "✅ Limpieza completada" -ForegroundColor Green
Write-Host ""

# Construir y ejecutar
Write-Host "Construyendo e iniciando servicios..." -ForegroundColor Yellow
Write-Host "Esto puede tomar unos minutos la primera vez..." -ForegroundColor Cyan
Write-Host ""

docker-compose up --build -d

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ BACKEND INICIADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📍 Accesos disponibles:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   🔹 GraphQL Playground:" -ForegroundColor White
    Write-Host "      http://localhost:8000/graphql/" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   🔹 Panel de Administración:" -ForegroundColor White
    Write-Host "      http://localhost:8000/admin/" -ForegroundColor Yellow
    Write-Host "      Usuario: admin" -ForegroundColor Gray
    Write-Host "      Password: admin123" -ForegroundColor Gray
    Write-Host ""
    Write-Host "👤 Estudiantes de prueba:" -ForegroundColor Cyan
    Write-Host "   • 218001234 (Juan Carlos Pérez - Sin bloqueo)" -ForegroundColor White
    Write-Host "   • 219005678 (María Fernanda López - Bloqueado)" -ForegroundColor White
    Write-Host ""
    Write-Host "📝 Ver logs en tiempo real:" -ForegroundColor Cyan
    Write-Host "   docker-compose logs -f" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🛑 Detener el backend:" -ForegroundColor Cyan
    Write-Host "   docker-compose down" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    
    # Esperar un momento y mostrar los logs
    Write-Host ""
    Write-Host "Mostrando logs del servidor (Ctrl+C para salir)..." -ForegroundColor Cyan
    Write-Host ""
    Start-Sleep -Seconds 3
    docker-compose logs -f
}
else {
    Write-Host ""
    Write-Host "❌ Error al iniciar los servicios" -ForegroundColor Red
    Write-Host "Revisa los logs con: docker-compose logs" -ForegroundColor Yellow
    exit 1
}
