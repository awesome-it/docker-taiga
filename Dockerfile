FROM python:3.5
MAINTAINER Benjamin Hutchins <ben@hutchins.co>
ARG VERSION

ENV DEBIAN_FRONTEND noninteractive

RUN set -x; \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        locales \
        gettext \
        ca-certificates \
        nginx \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && dpkg-reconfigure locales

# Get taiga-back and taige-front directly from Git
RUN VERSION_BACK=${VERSION:-stable} && \
    wget https://github.com/taigaio/taiga-back/archive/$VERSION_BACK.tar.gz -O /taiga-back.tar.gz && \
    tar -xzf /taiga-back.tar.gz && \
    ln -s /taiga-back-$VERSION_BACK /usr/src/taiga-back && \
    rm /taiga-back.tar.gz

RUN VERSION_FRONT=${VERSION:-stable} && \
    if [ $VERSION_FRONT != "stable" ] ; then VERSION_FRONT=${VERSION_FRONT}-stable ; fi && \
    wget https://github.com/taigaio/taiga-front-dist/archive/$VERSION_FRONT.tar.gz -O /taiga-front-dist.tar.gz && \
    tar -xzf /taiga-front-dist.tar.gz && \
    ln -s /taiga-front-dist-$VERSION_FRONT /usr/src/taiga-front-dist && \
    rm /taiga-front-dist.tar.gz

COPY docker-settings.py /usr/src/taiga-back/settings/docker.py
COPY conf/locale.gen /etc/locale.gen
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx/taiga.conf /etc/nginx/conf.d/default.conf
COPY conf/nginx/ssl.conf /etc/nginx/ssl.conf
COPY conf/nginx/taiga-events.conf /etc/nginx/taiga-events.conf

# Setup symbolic links for configuration files
RUN mkdir -p /taiga
COPY conf/taiga/local.py /taiga/local.py
COPY conf/taiga/conf.json /taiga/conf.json
RUN ln -s /taiga/local.py /usr/src/taiga-back/settings/local.py
RUN ln -s /taiga/conf.json /usr/src/taiga-front-dist/dist/conf.json

# Backwards compatibility
RUN mkdir -p /usr/src/taiga-front-dist/dist/js/
RUN ln -s /taiga/conf.json /usr/src/taiga-front-dist/dist/js/conf.json

WORKDIR /usr/src/taiga-back

# specify LANG to ensure python installs locals properly
# fixes benhutchins/docker-taiga-example#4
# ref benhutchins/docker-taiga#15
ENV LANG C

RUN pip install --no-cache-dir -r requirements.txt

RUN echo "LANG=en_US.UTF-8" > /etc/default/locale
RUN echo "LC_TYPE=en_US.UTF-8" > /etc/default/locale
RUN echo "LC_MESSAGES=POSIX" >> /etc/default/locale
RUN echo "LANGUAGE=en" >> /etc/default/locale

ENV LANG en_US.UTF-8
ENV LC_TYPE en_US.UTF-8

ENV TAIGA_SSL False
ENV TAIGA_ENABLE_EMAIL False
ENV TAIGA_HOSTNAME localhost
ENV TAIGA_SECRET_KEY "!!!REPLACE-ME-j1598u1J^U*(y251u98u51u5981urf98u2o5uvoiiuzhlit3)!!!"

RUN python manage.py collectstatic --noinput

RUN locale -a

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443

VOLUME /usr/src/taiga-back/media

COPY checkdb.py /checkdb.py
COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
