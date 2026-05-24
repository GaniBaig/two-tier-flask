# Use Alpine Linux for much smaller image size
# python:3.9-slim = ~120MB, python:3.9-alpine = ~45MB (60% smaller!)
FROM python:3.9-alpine

WORKDIR /app

# Install only essential build dependencies for mysqlclient
# Alpine uses apk instead of apt-get
RUN apk add --no-cache \
    gcc \
    musl-dev \
    mariadb-dev \
    && rm -rf /var/cache/apk/*

# Copy and install Python dependencies
COPY requirement.txt .
RUN pip install --no-cache-dir -r requirement.txt

# Copy application code
COPY . .

# Expose application port
EXPOSE 5001

# Run as non-root user for security
RUN adduser -D appuser && chown -R appuser:appuser /app
USER appuser

# Start application
CMD ["python", "app.py"]