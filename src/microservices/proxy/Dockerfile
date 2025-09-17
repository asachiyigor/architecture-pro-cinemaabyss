FROM golang:1.19 AS builder

# Set Go proxy and DNS to avoid network issues
ENV GOPROXY=https://goproxy.cn,direct
ENV GOSUMDB=off
ENV GODEBUG=netdns=go

WORKDIR /app
COPY go.mod go.sum* ./

# Only run go mod download if go.mod has dependencies
RUN if [ -f go.sum ]; then go mod download; fi

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

FROM gcr.io/distroless/static-debian11
WORKDIR /

COPY --from=builder /app/main .

EXPOSE 8000

CMD ["./main"]
