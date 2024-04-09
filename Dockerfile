ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8
ENV NPM_CONFIG_UNSAFE_PERM=true
RUN apk add --no-cache jq nodejs npm
# npm set unsafe-perm true

# Copy data for add-on
WORKDIR /usr/src/app
COPY . .
RUN chmod +x run.sh

CMD [ "./run.sh" ]
