FROM node:14.19.3-alpine

WORKDIR /usr/src/app

COPY ./src .

RUN npm install

EXPOSE 3000

ENTRYPOINT [ "node", "server.js" ]
