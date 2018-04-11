# build backend
FROM golang:1.9-alpine AS gobuild
RUN apk add --update g++ git && \
    go get github.com/grafana/grafana || \
    cd /go/src/github.com/grafana/grafana && \
    go run build.go setup && \
    go run build.go build

# build frontend
FROM node:9.11-alpine AS nodebuild
WORKDIR /grafana
COPY --from=gobuild /go/src/github.com/grafana/grafana .
RUN apk add --update python3 && \
    PYTHON=`which python3` && \
    yarn install --pure-lockfile && \
    npm run build

FROM alpine:3.6
WORKDIR /grafana
COPY --from=nodebuild /grafana/bin/grafana-server ./bin/
COPY --from=nodebuild /grafana/conf/ ./conf/
COPY --from=nodebuild /grafana/public ./public/

EXPOSE 3000
VOLUME /grafana/data
ENTRYPOINT /grafana/bin/grafana-server
