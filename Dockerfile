ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:latest
FROM $BUILD_FROM

ENV LANG C.UTF-8
RUN apk add --no-cache nodejs npm

# Copy data for add-on
WORKDIR /usr/src/app
COPY . .
RUN npm ci --omit=dev \
    && chmod a+x run.sh

CMD [ "./run.sh" ]
