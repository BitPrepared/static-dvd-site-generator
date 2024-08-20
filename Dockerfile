FROM node:18.2.0-bullseye

ARG USER_ID
ARG GROUP_ID

RUN adduser -u ${USER_ID} --group users -h /home/myuser -D myuser \
    && apt install ca-certificates bash

ENV USER_ID=${USER_ID}
ENV GROUP_ID=${GROUP_ID}
ENV USER_NAME=mysuer

RUN mkdir -p /usr/src/app

RUN apt update

RUN apt-get install -y unzip git libcurl4-gnutls-dev wget 

RUN apt-get install -y libmagick++-dev

RUN export PATH=/usr/lib/i386-linux-gnu/ImageMagick-6.8.9/bin-Q16:$PATH

ADD static-dvd-site-generator /usr/src/app

RUN chown -R ${USER_ID}:${GROUP_ID} /usr/src/app

USER ${USER_ID}:${GROUP_ID}

WORKDIR /usr/src/app

RUN npm install

ENTRYPOINT [ "npm" ]
CMD [ "run build" ]