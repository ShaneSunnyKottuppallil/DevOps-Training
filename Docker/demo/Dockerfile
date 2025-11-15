FROM python:3.8-slim

COPY requirements.txt /app/



WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      pkg-config \
      default-mysql-client \
      default-libmysqlclient-dev

RUN pip install --upgrade pip
RUN pip install -r /app/requirements.txt

COPY . .
COPY entrypoint.sh /app/entrypoint.sh
EXPOSE 8000

RUN chmod +x /app/entrypoint.sh


CMD sh -c "python /app/fundoo/manage.py migrate --noinput && \
           python /app/fundoo/manage.py runserver 0.0.0.0:8000"
