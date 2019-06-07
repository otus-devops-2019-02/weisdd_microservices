FROM golang:1.12.5 AS builder

ENV APPPATH $GOPATH/src/github.com/percona/mongodb_exporter

WORKDIR $APPPATH

RUN git clone -b v0.7.0 "https://github.com/percona/mongodb_exporter" "$APPPATH" \
    && go get -d && CGO_ENABLED=0 GOOS=linux go build -o /bin/mongodb_exporter \
    && rm -rf "$GOPATH"

FROM alpine:3.9.4
ENV MONGODB_URI mongodb://post_db:27017
#EXPOSE 9216
COPY --from=builder /bin/mongodb_exporter /bin/mongodb_exporter

ENTRYPOINT [ "/bin/mongodb_exporter" ]
