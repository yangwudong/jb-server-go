# syntax=docker/dockerfile:1

# ---------- build stage ----------
FROM golang:1.27-alpine AS build
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY main.go plugin.go ./
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /out/jetbra-server .

# ---------- runtime stage ----------
FROM alpine:3.22

# ca-certificates: 启动时需要访问 https://plugins.jetbrains.com
RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S app && adduser -S app -G app

WORKDIR /app
COPY --from=build /out/jetbra-server ./
COPY jetbra.key jetbra.pem plugins.json ./
COPY static ./static
COPY templates ./templates

# plugins.json 会在启动时被重写，需要可写权限
RUN chown -R app:app /app
USER app

EXPOSE 46793
ENV PORT=46793
ENTRYPOINT ["./jetbra-server"]
