FROM postgres:9.6

COPY ./init-script.sh /docker-entrypoint-initdb.d/
COPY ./seeds.csv /