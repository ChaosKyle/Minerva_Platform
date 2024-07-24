FROM python:3.9-slim

WORKDIR /apps/chore_tracker

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8081

CMD ["python", "app.py"]