FROM tiangolo/uvicorn-gunicorn-fastapi:python3.9
RUN pip install prometheus-fastapi-instrumentator pydantic  # Add this line
COPY ./main.py /app/main.py
