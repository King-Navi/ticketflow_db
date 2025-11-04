FROM postgres:18-alpine

RUN apk add --no-cache tzdata \
    && cp /usr/share/zoneinfo/America/Mexico_City /etc/localtime \
    && echo "America/Mexico_City" > /etc/timezone \
    && mkdir -p /var/lib/postgresql/data \
    && chown -R postgres:postgres /var/lib/postgresql

# zona horaria
ENV TZ=America/Mexico_City

COPY init/ /docker-entrypoint-initdb.d/


# Config personalizada opcional

# docker run ... -c 'config_file=/etc/postgresql/postgresql.conf'
# COPY config/postgresql.conf /etc/postgresql/postgresql.conf
# ENV POSTGRES_INITDB_ARGS="--data-checksums"
