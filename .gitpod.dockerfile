FROM gitpod/workspace-full:latest

ENV PG_MAJOR 10
ENV POSTGIS_MAJOR 2.5
#ENV POSTGIS_VERSION 2.5.2+dfsg-1~exp1.pgdg90+1
ENV POSTGIS_VERSION 2.5.2+dfsg-1~exp1.pgdg18.10+1

RUN sudo lsb_release -a 
RUN sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt cosmic-pgdg main" >> /etc/apt/sources.list'
RUN wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -

# Install PostgreSQL and postgis
RUN sudo apt-get update \
 && sudo apt-get install -y postgresql postgresql-contrib \
 && apt-cache showpkg postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
 && sudo apt-get install -y --no-install-recommends \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
           postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts=$POSTGIS_VERSION \
           postgis=$POSTGIS_VERSION \
 && sudo apt-get clean \
 && sudo rm -rf /var/cache/apt/* /var/lib/apt/lists/* /tmp/*

RUN sudo mkdir -p /docker-entrypoint-initdb.d
COPY .gitpod/initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
COPY .gitpod/update-postgis.sh /usr/local/bin

# Setup PostgreSQL server for user gitpod
ENV PATH="$PATH:/usr/lib/postgresql/10/bin"
ENV PGDATA="/home/gitpod/.pg_ctl/data"
RUN mkdir -p ~/.pg_ctl/bin ~/.pg_ctl/data ~/.pg_ctl/sockets \
 && initdb -D ~/.pg_ctl/data/ \
 && printf "#!/bin/bash\npg_ctl -D ~/.pg_ctl/data/ -l ~/.pg_ctl/log -o \"-k ~/.pg_ctl/sockets\" start\n" > ~/.pg_ctl/bin/pg_start \
 && printf "#!/bin/bash\npg_ctl -D ~/.pg_ctl/data/ -l ~/.pg_ctl/log -o \"-k ~/.pg_ctl/sockets\" stop\n" > ~/.pg_ctl/bin/pg_stop \
 && chmod +x ~/.pg_ctl/bin/*
ENV PATH="$PATH:$HOME/.pg_ctl/bin"
ENV DATABASE_URL="postgresql://gitpod@localhost"
ENV PGHOSTADDR="127.0.0.1"
ENV PGDATABASE="postgres"

# This is a bit of a hack. At the moment we have no means of starting background
# tasks from a Dockerfile. This workaround checks, on each bashrc eval, if the
# PostgreSQL server is running, and if not starts it.
RUN printf "\n# Auto-start PostgreSQL server.\n[[ \$(pg_ctl status | grep PID) ]] || pg_start > /dev/null\n" >> ~/.bashrc

USER root
# Install custom tools, runtime, etc.
RUN apt-get update && apt-get install --no-install-recommends -y \
        build-essential \
        gettext \
        libffi-dev \
        libgdal-dev \
        libssl-dev \
    && apt-get clean && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/* \
    && pip install pipenv

ENV DJANGO_SETTINGS_MODULE woeip.settings
#ENV PIPENV_DONT_USE_PYENV 1
#ENV PIPENV_SYSTEM 1

ENV DEBUG true
ENV SECRET_KEY replace-me
ENV DATABASE_URL postgis://gitpod:gitpod@localhost:5432/postgres?connect_timeout=60
ENV DEFAULT_FILE_STORAGE django.core.files.storage.FileSystemStorage

RUN mkdir -p /logs \
    && chmod a+rwx /logs \
    && touch /logs/app.log \
    && touch /logs/gunicorn.log \
    && chmod a+rw /logs/*.log \
    && mkdir -p /public/static \
    && chmod a+rwx /public/static \
    && mkdir -p /app/woeip \
    && chmod a+rwx /app/woeip


ENV PUBLIC_ROOT /public
ENV LOG_FILE_PATH /logs
ENV ENABLE_LOGGING_TO_FILE true

USER gitpod
# Apply user-specific settings
# ENV ...
git config --global core.editor "vim"

# Give back control
USER root

