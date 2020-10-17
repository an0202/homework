FROM nginx:stable

LABEL maintainer="jie.an"
# install zip and copy static files
RUN apt update && apt install -y zip
COPY static.zip /tmp/static.zip

# copy new default conf
RUN unzip -o /tmp/static.zip -d /usr/share/nginx/html/
COPY cicd_demo.conf /etc/nginx/conf.d/default.conf
