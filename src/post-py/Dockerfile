FROM python:3.6.0-alpine

WORKDIR /app
COPY . /app

RUN apk update && apk add --no-cache build-base \
    && pip install -r /app/requirements.txt \
    && apk del build-base

ENV POST_DATABASE_HOST post_db
ENV POST_DATABASE posts

ENTRYPOINT ["python3", "post_app.py"]
