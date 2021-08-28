# builder
FROM golang:1.16 as build

WORKDIR /src

COPY go.mod .
COPY go.sum .
COPY ./cmd .

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o server

# app
FROM scratch

COPY --from=build /src/server .

ENTRYPOINT ["/server"]
