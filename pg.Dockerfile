FROM postgres:18

RUN apt-get update && apt-get install -y \
    postgresql-18-plpgsql-check \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY ./ms2pg/sqlscripts/pg_init/prerequsites.sql /docker-entrypoint-initdb.d/