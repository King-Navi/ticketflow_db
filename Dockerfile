FROM postgres:18-alpine

# utilidades
# RUN apk add --no-cache bash tzdata

# zona horaria
ENV TZ=America/Mexico_City

COPY initdb/ /docker-entrypoint-initdb.d/

# postgresql.conf propio
# COPY config/postgresql.conf /etc/postgresql/postgresql.conf
# ENV POSTGRES_INITDB_ARGS="--data-checksums" 