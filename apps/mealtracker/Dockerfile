FROM python:3.9.7-slim

WORKDIR /app

COPY . .

RUN pip install --no-cache-dir Flask==2.0.1 Werkzeug==2.0.1

EXPOSE 8082

CMD ["python", "app.py"]