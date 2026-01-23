FROM golang:1.23-alpine AS builder

WORKDIR /app

COPY apps/services/triage/qr-ingest/go.mod apps/services/triage/qr-ingest/go.sum ./
RUN go mod download

COPY apps/services/triage/qr-ingest/ .

RUN CGO_ENABLED=0 GOOS=linux go build -o qr-service main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/

COPY --from=builder /app/qr-service .

EXPOSE 8080

CMD ["./qr-service"]