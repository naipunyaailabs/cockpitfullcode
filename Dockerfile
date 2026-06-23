# Multi-stage: backend Python, frontend Node, final Nginx+backend

FROM python:3.11-slim AS backend
WORKDIR /app/backend
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY backend .

FROM node:20.19.0-bullseye AS frontend
WORKDIR /app/frontend
COPY frontend/package*.json .
RUN npm ci
COPY frontend .
RUN npm run build

FROM python:3.11-slim
RUN apt-get update && apt-get install -y nginx curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy backend
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY --from=backend /app/backend ./backend
COPY frontend ./frontend
COPY --from=frontend /app/frontend/dist ./frontend/dist
COPY nginx/nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["sh", "-c", "cd /app/backend && uvicorn main:app --host 127.0.0.1 --port 8005 > /tmp/backend.log 2>&1 & sleep 2 && nginx -g 'daemon off;'"]
