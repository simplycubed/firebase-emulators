FROM python:3.10-slim-buster

# The Firebase install scripts use sudo so we need to add it.
RUN apt update && apt install -y sudo

RUN adduser --disabled-password --gecos '' docker
RUN adduser docker sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER docker

RUN sudo apt update  && sudo apt install -y curl git xz-utils curl
RUN sudo mkdir /app
RUN sudo chown -R docker:docker /app
# Fix issue with JRE installation
RUN sudo mkdir -p /usr/share/man/man1
RUN sudo apt install -y openjdk-11-jre-headless

# Install NodeJS
RUN sudo apt-get install -y gcc g++ make node-gyp
RUN curl -sL https://deb.nodesource.com/setup_16.x 565 | sudo -E bash -
RUN sudo apt-get install -y nodejs
# Install base tools
RUN sudo npm install -g firebase-tools

# Install gcloud commmand utilities to use default login
RUN curl -sSL https://sdk.cloud.google.com > /tmp/gcl && bash /tmp/gcl --install-dir=~/gcloud --disable-prompts
ENV PATH $PATH:~/gcloud/google-cloud-sdk/bin

WORKDIR /app

# First run will download the current .jar files for firebase
# RUN firebase emulators:exec --project test ls >> /dev/null
# Download only required emulators
RUN firebase setup:emulators:firestore && firebase setup:emulators:storage && firebase setup:emulators:pubsub && firebase setup:emulators:ui

COPY ./firebase.json /app/firebase.json
COPY ./.firebaserc /app/.firebaserc

COPY ./firebase.json /app/firebase.json
COPY ./firestore.indexes.json /app/firestore.indexes.json
COPY ./firestore.rules /app/firestore.rules
COPY ./storage.rules /app/storage.rules

EXPOSE 4000 9090 8085 4400 4500 9000 5001 9099

CMD firebase emulators:start --only firestore,storage --project ${FIRESTORE_PROJECT_NAME:-test} 
