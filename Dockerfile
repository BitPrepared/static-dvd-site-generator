FROM node:18.2.0-bullseye

ARG USER_ID
ARG GROUP_ID

# uid/gid 1000 esistono già nell'immagine node (utente `node`): se coincidono
# con chi builda si riusano, altrimenti si creano (es. podman keep-id, uid alti)
RUN if ! getent group "${GROUP_ID}" >/dev/null; then groupadd -g ${GROUP_ID} scout; fi \
    && if ! getent passwd "${USER_ID}" >/dev/null; then useradd --uid ${USER_ID} --gid ${GROUP_ID} --home-dir /home/myuser --create-home myuser; fi \
    && apt install ca-certificates bash

ENV USER_ID=${USER_ID}
ENV GROUP_ID=${GROUP_ID}
ENV USER_NAME=mysuer
ENV DEBUG=""

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

#ENTRYPOINT [ "npm" ]
CMD [ "npm", "run", "build" ]
