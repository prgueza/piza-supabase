FROM node:alpine3.16

RUN yarn global add serve

WORKDIR /usr/src/piza-frontend

COPY build/ .

CMD ["serve", "-l", "8080"]