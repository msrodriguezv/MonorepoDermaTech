# STAGE 1: Build the binary
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy dependency files
COPY apps/services/qr-ingest/go.mod apps/services/qr-ingest/go.sum ./
RUN go mod download

# Copy source code
COPY apps/services/qr-ingest/ .

# Build a statically linked binary for production
RUN CGO_ENABLED=0 GOOS=linux go build -o qr-service main.go

# STAGE 2: Lightweight runner
FROM alpine:latest
RUN apk --no-cache add ca-certificates

WORKDIR /root/
# Copy the binary from the builder stage
COPY --from=builder /app/qr-service .

# Standard port for QR service (adjust if needed)
EXPOSE 8080

# Run the binary
CMD ["./qr-service"]