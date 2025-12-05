FROM python:3.11-slim

LABEL maintainer="CloudEdu Services Team"
LABEL description="Aplicación web cloud-native para mensajería educativa"
LABEL version="1.0.0"

# Variables de entorno
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    ENVIRONMENT=production

# Crear usuario no privilegiado
RUN useradd -m -u 1000 appuser && \
    mkdir -p /app /app/data && \
    chown -R appuser:appuser /app

WORKDIR /app

# Copiar archivos de dependencias
COPY --chown=appuser:appuser app/requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copiar código de la aplicación
COPY --chown=appuser:appuser app/ .

# Cambiar a usuario no privilegiado
USER appuser

# Exponer puerto
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

# Comando de inicio
CMD ["python", "app.py"]
