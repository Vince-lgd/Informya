# Image Python allégée comme base
FROM python:3.13-slim

# Dossier de travail dans le container
WORKDIR /app

# gcc requis pour compiler certaines libs Python (asyncpg)
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copie requirements en premier → Docker met en cache le pip install
# Si ton code change mais pas requirements.txt, pas de réinstall
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copie le reste du code source
COPY . .

# Port d'écoute (mapping réel dans docker-compose.yml)
EXPOSE 8000

# Démarre FastAPI avec rechargement auto en dev
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]