# Multi-stage build: backend, frontend, and nginx in one container

# Stage 1: Build backend
FROM python:3.11-slim AS backend-builder
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend/ ./backend/

# Stage 2: Build frontend
FROM node:20.19.0-bullseye AS frontend-builder
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
ARG VITE_API_BASE_URL=""
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}
RUN npm run build

# Stage 3: Final image with nginx + backend
FROM python:3.11-slim
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# Copy backend
WORKDIR /app
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY --from=backend-builder /app/backend ./backend/

# Copy frontend build to nginx
COPY --from=frontend-builder /app/dist /usr/share/nginx/html

# Copy nginx config
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Expose single port
EXPOSE 80

# Start both nginx and backend
CMD ["/bin/bash", "-c", "cd /app/backend && uvicorn main:app --host 127.0.0.1 --port 8005 &  && nginx -g 'daemon off;'"]
