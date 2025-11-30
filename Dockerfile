# Берём официальный образ Python
FROM python:3.12-slim

# Делаем рабочую директорию внутри контейнера
WORKDIR /app

# Kопируем зависимости
COPY requirements.txt /app/requirements.txt

# Устанавливаем зависимости
RUN pip install --no-cache-dir -r /app/requirements.txt

# Kопируем сам код
COPY app /app/app

# По умолчанию хранение будет в памяти
ENV STORAGE=memory

# Docker-контейнер слушает 8000 порт
EXPOSE 8000

# Команда, которую контейнер запускает по умолчанию
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
