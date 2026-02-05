# Script de Inicio Rapido - Sistema de Inscripcion

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SISTEMA DE INSCRIPCION UNIVERSITARIA" -ForegroundColor Cyan
Write-Host "  Iniciando Backend..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar si Docker esta corriendo
Write-Host "Verificando Docker..." -ForegroundColor Yellow
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Docker no esta corriendo" -ForegroundColor Red
    Write-Host "Por favor, inicia Docker Desktop y vuelve a ejecutar este script" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Docker esta corriendo" -ForegroundColor Green
Write-Host ""

# Detener contenedores previos si existen
Write-Host "Limpiando contenedores previos..." -ForegroundColor Yellow
docker-compose down 2>&1 | Out-Null
Write-Host "[OK] Limpieza completada" -ForegroundColor Green
Write-Host ""

# Construir y ejecutar
Write-Host "Construyendo e iniciando servicios..." -ForegroundColor Yellow
Write-Host "Esto puede tomar unos minutos la primera vez..." -ForegroundColor Cyan
Write-Host ""

docker-compose up --build -d

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  [OK] BACKEND INICIADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "ACCESOS DISPONIBLES:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   > GraphQL Playground:" -ForegroundColor White
    Write-Host "      http://localhost:8000/graphql/" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   > Panel de Administracion:" -ForegroundColor White
    Write-Host "      http://localhost:8000/admin/" -ForegroundColor Yellow
    Write-Host "      Usuario: admin" -ForegroundColor Gray
    Write-Host "      Password: admin123" -ForegroundColor Gray
    Write-Host ""
    Write-Host "ESTUDIANTES DE PRUEBA:" -ForegroundColor Cyan
    Write-Host "   - 218001234 (Juan Carlos Perez - Sin bloqueo)" -ForegroundColor White
    Write-Host "   - 219005678 (Maria Fernanda Lopez - Bloqueado)" -ForegroundColor White
    Write-Host ""
    Write-Host "COMANDOS UTILES:" -ForegroundColor Cyan
    Write-Host "   Ver logs:    docker-compose logs -f" -ForegroundColor Yellow
    Write-Host "   Detener:     docker-compose down" -ForegroundColor Yellow
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
    Write-Host "[ERROR] Error al iniciar los servicios" -ForegroundColor Red
    Write-Host "Revisa los logs con: docker-compose logs" -ForegroundColor Yellow
    exit 1
}
