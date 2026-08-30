FROM golang:1.24-bookworm AS build

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/dataset-deal-webapp ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /out/dataset-deal-webapp /dataset-deal-webapp

ENV HTTP_ADDRESS=0.0.0.0:8080
ENV DEX_WORKER_BIND_ADDRESS=0.0.0.0:8803

EXPOSE 8080 8803

ENTRYPOINT ["/dataset-deal-webapp"]
