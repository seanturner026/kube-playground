# builder
FROM golang:1.18-alpine as build

RUN addgroup -S appuser && \
    adduser -S -u 10001 -g appuser appuser

WORKDIR /src

COPY go.mod .
COPY go.sum .
COPY ./cmd .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server

# app
FROM scratch

COPY --from=build /src/server .
COPY --from=build /etc/passwd /etc/passwd
USER appuser

ENTRYPOINT ["/server"]
