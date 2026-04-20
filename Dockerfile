FROM python:3.11-slim-bookworm

# Establecer variables de entorno
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    gcc \
    python3-dev \
    libpq-dev \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias de Python
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar el proyecto (esto crea /app/inscripcion_backend/...)
COPY . .

# Cambiar al directorio del backend
WORKDIR /app/inscripcion_backend

# Exponer el puerto
EXPOSE 8000

# Comando por defecto (ahora relativo a /app/inscripcion_backend)
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
