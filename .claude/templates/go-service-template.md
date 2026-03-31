# Go Service Template

Template for bootstrapping a new Go microservice with PostgreSQL, chi router, and testcontainers.

## Directory Structure

```
<service-name>/
├── cmd/
│   ├── <service-name>/
│   │   └── main.go                # Service entry point
│   └── migrate/
│       └── main.go                # Migration CLI (up/down/version)
├── config/
│   └── config.yaml                # YAML configuration (Viper)
├── db/
│   ├── embed.go                   # Embeds migration/*.sql via go:embed
│   └── migration/
│       ├── 000001_create_<table>.up.sql
│       └── 000001_create_<table>.down.sql
├── internal/
│   ├── domain/<context>/          # One package per bounded context
│   │   ├── <aggregate>.go         # Aggregate root, child entities, related types
│   │   ├── repository.go          # Concrete PostgreSQL repository (imports pgx)
│   │   ├── service.go             # Use-case orchestration (commands/queries)
│   │   └── errors.go              # Sentinel errors
│   ├── domain/shared/             # Shared types across contexts
│   │   ├── id.go                  # UUID identifiers
│   ├── transport/http/
│   │   ├── router.go              # NewRouter() — chi router, middleware, routes
│   │   └── <context>/             # One sub-package per bounded context
│   │       ├── handler.go         # HTTP handlers (maps DTOs ↔ service calls)
│   │       ├── request.go         # Request DTOs
│   │       └── response.go        # Response DTOs
│   └── platform/
│       ├── config/
│       │   └── config.go          # Viper config struct + Load()
│       ├── httpserver/
│       │   └── server.go          # HTTP server wrapper with graceful shutdown
│       ├── logger/
│       │   └── logger.go          # zerolog factory
│       ├── middleware/
│       │   └── requestlogger.go   # chi request logger middleware
│       └── migrate/
│           └── migrate.go         # golang-migrate helpers for embedded FS
├── testinfra/
│   └── postgres.go                # Testcontainers PostgreSQL wrapper (build tag: integration)
├── .gitignore
├── .golangci.yml
├── Dockerfile
├── go.mod
├── go.sum
└── Makefile
```

---

## Makefile

```makefile
SHELL := /bin/sh
.DEFAULT_GOAL := help

APP_NAME ?= <service-name>
BIN_DIR ?= bin
TMP_DIR ?= tmp
GO ?= go

GOTESTSUM_VERSION ?= v1.13.0
GOLANGCI_LINT_VERSION ?= v2.11.3
DOCKER_IMAGE ?= $(APP_NAME)
DOCKER_TAG ?= latest
DOCKER_PLATFORMS ?= linux/amd64
DOCKER_PUSH ?= false

.PHONY: help install-tools test test-race test-integration lint lint-fix build docker clean

help: ## Show available targets
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_.-]+:.*## / {printf "  make %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install-tools: ## Install gotestsum and golangci-lint into ./$(BIN_DIR)
	mkdir -p $(BIN_DIR)
	GOBIN=$(PWD)/$(BIN_DIR) $(GO) install gotest.tools/gotestsum@$(GOTESTSUM_VERSION)
	GOBIN=$(PWD)/$(BIN_DIR) $(GO) install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)

test: ## Run unit tests with gotestsum
	$(BIN_DIR)/gotestsum -- ./...

test-race: ## Run unit tests with race detector
	$(GO) test -race ./...

test-integration: ## Run integration tests (requires Docker)
	$(GO) test -tags=integration -count=1 ./...

lint: ## Run golangci-lint
	$(BIN_DIR)/golangci-lint run ./...

lint-fix: ## Run golangci-lint with auto-fix
	$(BIN_DIR)/golangci-lint run --fix ./...

build: ## Build binary to ./$(TMP_DIR)/$(APP_NAME)
	mkdir -p $(TMP_DIR)
	$(GO) build -o $(TMP_DIR)/$(APP_NAME) ./cmd/$(APP_NAME)

docker: ## Build Docker image locally (set DOCKER_PUSH=true for multi-platform push)
	@case "$(DOCKER_PLATFORMS)" in \
		*,*) if [ "$(DOCKER_PUSH)" != "true" ]; then \
			echo "Multi-platform build requires DOCKER_PUSH=true (example: make docker DOCKER_PUSH=true)"; \
			exit 1; \
		fi ;; \
	esac
	@if [ "$(DOCKER_PUSH)" = "true" ]; then \
		docker buildx build --platform $(DOCKER_PLATFORMS) -t $(DOCKER_IMAGE):$(DOCKER_TAG) --push .; \
	else \
		docker buildx build --platform $(DOCKER_PLATFORMS) -t $(DOCKER_IMAGE):$(DOCKER_TAG) --load .; \
	fi

clean: ## Remove local build artifacts
	rm -rf $(TMP_DIR)
```

---

## .golangci.yml

```yaml
version: "2"

run:
  build-tags:
    - integration

formatters:
  enable:
    - gofmt
    - goimports

linters:
  enable:
    # bugs & correctness
    - errcheck
    - govet
    - staticcheck
    - bodyclose
    - noctx
    - nilerr
    - nilnesserr
    - errorlint
    - durationcheck
    - exhaustive
    - musttag
    - copyloopvar

    # code quality
    - ineffassign
    - unused
    - unconvert
    - goconst
    - gocritic
    - revive
    - misspell
    - dupword
    - prealloc
    - nakedret
    - errname

    # security
    - gosec

    # style & modernization
    - modernize
    - intrange
    - fatcontext
    - containedctx
    - nestif

  settings:
    revive:
      rules:
        - name: exported
          arguments:
            - disableStutteringCheck
        - name: unused-parameter
        - name: blank-imports
        - name: context-as-argument
        - name: error-return
        - name: error-strings
        - name: increment-decrement
        - name: var-naming
    goconst:
      min-len: 3
      min-occurrences: 3
    gocritic:
      enabled-tags:
        - diagnostic
        - performance
        - style
      disabled-checks:
        - hugeParam
        - rangeValCopy
        - exitAfterDefer
    nestif:
      min-complexity: 5
    nakedret:
      max-func-lines: 30
    exhaustive:
      default-signifies-exhaustive: true
    gosec:
      excludes:
        - G104  # unhandled errors on deferred Close — covered by errcheck
        - G304  # file path from variable — needed for migrations

  exclusions:
    paths:
      - vendor
    rules:
      - path: _test\.go
        linters:
          - gosec
          - errcheck
          - goconst
          - dupword
          - noctx
```

---

## .gitignore

```gitignore
# Build artifacts
/tmp/
/bin/

# Test outputs
*.test
*.out
coverage.out

# Local environment files
.env
.env.*

# OS/editor files
.DS_Store
```

---

## Dockerfile

Multi-stage build: Go builder + minimal Alpine runtime.

```dockerfile
FROM golang:1.25-alpine AS builder

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /bin/<service-name> ./cmd/<service-name>

FROM gcr.io/distroless/base
COPY --from=builder /bin/<service-name> /bin/<service-name>
EXPOSE 8080
ENTRYPOINT ["/bin/<service-name>"]
```

---

## go.mod

```go
module <service-name>

go 1.25.8

require (
    github.com/google/uuid v1.6.0
    github.com/go-chi/chi/v5 v5.2.5
    github.com/golang-migrate/migrate/v4 v4.19.1
    github.com/jackc/pgx/v5 v5.8.0
    github.com/rotisserie/eris v0.5.4
    github.com/rs/zerolog v1.34.0
    github.com/spf13/viper v1.20.1
    github.com/stretchr/testify v1.11.1
    github.com/testcontainers/testcontainers-go v0.41.0
    github.com/testcontainers/testcontainers-go/modules/postgres v0.41.0
    go.uber.org/automaxprocs v1.6.0
)
```

> After creating go.mod, run `go mod tidy` to resolve the full dependency tree and generate go.sum.

---

## Source Files

### config/config.yaml

```yaml
server:
  port: 8080
  read_timeout_s: 5
  write_timeout_s: 10
  shutdown_timeout_s: 10

postgres:
  dsn: "postgres://app:app_local@localhost:5432/<service_name>"

log:
  level: "info"

jwt:
  secret: ""               # override přes env: JWT_SECRET
  access_token_ttl: "15m"  # platnost access tokenu
  refresh_token_ttl: "168h" # platnost refresh tokenu (7 dní)
  issuer: "edumeal"        # JWT issuer claim
```

### internal/platform/config/config.go

```go
package config

import (
    "strings"
    "time"
)

// App holds the complete application configuration.
type App struct {
    Server   Server   `mapstructure:"server"`
    Postgres Postgres `mapstructure:"postgres"`
    Log      Log      `mapstructure:"log"`
    JWT      JWT      `mapstructure:"jwt"`
}

// Server holds HTTP server configuration with raw integer timeouts matching YAML.
type Server struct {
    Port             int `mapstructure:"port"`
    ReadTimeoutS     int `mapstructure:"read_timeout_s"`
    WriteTimeoutS    int `mapstructure:"write_timeout_s"`
    ShutdownTimeoutS int `mapstructure:"shutdown_timeout_s"`
}

// HTTPServerConfig converts to durations for the HTTP server.
func (s Server) HTTPServerConfig() (port int, readTimeout, writeTimeout, shutdownTimeout time.Duration) {
    return s.Port,
        time.Duration(s.ReadTimeoutS) * time.Second,
        time.Duration(s.WriteTimeoutS) * time.Second,
        time.Duration(s.ShutdownTimeoutS) * time.Second
}

// Postgres holds the PostgreSQL connection settings.
type Postgres struct {
    DSN string `mapstructure:"dsn"`
}

// Log holds the logging configuration.
type Log struct {
    Level string `mapstructure:"level"`
}

// JWT holds the JWT authentication configuration.
type JWT struct {
    Secret          string `mapstructure:"secret"`
    AccessTokenTTL  string `mapstructure:"access_token_ttl"`
    RefreshTokenTTL string `mapstructure:"refresh_token_ttl"`
    Issuer          string `mapstructure:"issuer"`
}

// Load reads configuration from config/config.yaml, with environment variable overrides.
// Precedence: env vars > YAML file.
func Load(configPaths ...string) App {
    v := viper.New()

    v.SetConfigName("config")
    v.SetConfigType("yaml")

    if len(configPaths) > 0 {
        for _, p := range configPaths {
            v.AddConfigPath(p)
        }
    } else {
        v.AddConfigPath("config")
        v.AddConfigPath(".")
    }

    v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
    v.AutomaticEnv()

    _ = v.ReadInConfig()

    var cfg App
    _ = v.Unmarshal(&cfg)

    return cfg
}
```

> Add `"github.com/spf13/viper"` import — omitted here for brevity.

### internal/platform/logger/logger.go

```go
package logger

import (
    "os"
    "strings"

    "github.com/rs/zerolog"
)

// New creates a zerolog.Logger writing JSON to stdout at the given level.
func New(level string) zerolog.Logger {
    var lvl zerolog.Level
    switch strings.ToLower(level) {
    case "debug":
        lvl = zerolog.DebugLevel
    case "warn", "warning":
        lvl = zerolog.WarnLevel
    case "error":
        lvl = zerolog.ErrorLevel
    case "trace":
        lvl = zerolog.TraceLevel
    default:
        lvl = zerolog.InfoLevel
    }

    return zerolog.New(os.Stdout).Level(lvl).With().Timestamp().Logger()
}
```

### internal/platform/httpserver/server.go

```go
package httpserver

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"

    "github.com/rs/zerolog"
)

// HealthChecker returns dependency name -> status pairs (e.g. "connected").
type HealthChecker func(ctx context.Context) map[string]string

// Server wraps net/http.Server with structured logging and graceful shutdown.
type Server struct {
    srv             *http.Server
    logger          zerolog.Logger
    shutdownTimeout time.Duration
}

// New creates a Server bound to the given port.
func New(handler http.Handler, port int, readTimeout, writeTimeout, shutdownTimeout time.Duration, logger zerolog.Logger) *Server {
    return &Server{
        srv: &http.Server{
            Addr:         fmt.Sprintf(":%d", port),
            Handler:      handler,
            ReadTimeout:  readTimeout,
            WriteTimeout: writeTimeout,
        },
        logger:          logger,
        shutdownTimeout: shutdownTimeout,
    }
}

// Start begins listening. It blocks until the server is shut down.
func (s *Server) Start() error {
    s.logger.Info().Str("addr", s.srv.Addr).Msg("http server starting")
    return s.srv.ListenAndServe()
}

// Shutdown gracefully drains in-flight requests within the configured timeout.
func (s *Server) Shutdown(ctx context.Context) error {
    s.logger.Info().Msg("http server shutting down")
    shutdownCtx, cancel := context.WithTimeout(ctx, s.shutdownTimeout)
    defer cancel()
    return s.srv.Shutdown(shutdownCtx)
}

// HealthHandler returns an http.HandlerFunc that reports dependency health.
// Any dependency not reporting "connected" causes a 503 response.
func HealthHandler(checker HealthChecker) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        deps := checker(r.Context())

        status := "ok"
        httpCode := http.StatusOK
        for _, v := range deps {
            if v != "connected" {
                status = "degraded"
                httpCode = http.StatusServiceUnavailable
                break
            }
        }

        resp := map[string]any{
            "status": status,
        }
        for k, v := range deps {
            resp[k] = v
        }

        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(httpCode)
        _ = json.NewEncoder(w).Encode(resp)
    }
}
```

### internal/platform/middleware/requestlogger.go

```go
package middleware

import (
    "net/http"
    "time"

    "github.com/go-chi/chi/v5/middleware"
    "github.com/rs/zerolog"
)

// RequestLogger returns a chi-compatible middleware that logs every request
// with method, path, status, latency, and request ID.
func RequestLogger(log zerolog.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)

            reqLog := log.With().
                Str("requestId", middleware.GetReqID(r.Context())).
                Str("method", r.Method).
                Str("path", r.URL.Path).
                Logger()

            ctx := reqLog.WithContext(r.Context())

            next.ServeHTTP(ww, r.WithContext(ctx))

            reqLog.Info().
                Int("status", ww.Status()).
                Dur("latency", time.Since(start)).
                Msg("request completed")
        })
    }
}
```

### internal/platform/migrate/migrate.go

```go
package migrate

import (
    "errors"
    "fmt"
    "io/fs"
    "strings"

    "github.com/golang-migrate/migrate/v4"
    "github.com/golang-migrate/migrate/v4/source/iofs"
    "github.com/rs/zerolog"

    _ "github.com/golang-migrate/migrate/v4/database/pgx/v5" // register pgx/v5 database driver
)

// toPgx5DSN converts a standard postgres:// DSN to the pgx5:// scheme
// required by golang-migrate's pgx/v5 driver.
func toPgx5DSN(dsn string) string {
    if after, ok := strings.CutPrefix(dsn, "postgres://"); ok {
        return "pgx5://" + after
    }
    if after, ok := strings.CutPrefix(dsn, "postgresql://"); ok {
        return "pgx5://" + after
    }
    return dsn
}

// Run applies all pending up-migrations from the given filesystem to the database.
// The subdir parameter specifies the subdirectory within the FS that contains
// the migration files (e.g. "migration").
func Run(migrations fs.FS, subdir, dsn string, logger zerolog.Logger) error {
    source, err := iofs.New(migrations, subdir)
    if err != nil {
        return fmt.Errorf("open migrations source: %w", err)
    }

    m, err := migrate.NewWithSourceInstance("iofs", source, toPgx5DSN(dsn))
    if err != nil {
        return fmt.Errorf("create migrate instance: %w", err)
    }
    defer func() { _, _ = m.Close() }()

    if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
        return fmt.Errorf("run migrations: %w", err)
    }

    version, dirty, _ := m.Version()
    logger.Info().Uint("version", version).Bool("dirty", dirty).Msg("database migrations applied")
    return nil
}

// Rollback rolls back the last migration step.
func Rollback(migrations fs.FS, subdir, dsn string, logger zerolog.Logger) error {
    source, err := iofs.New(migrations, subdir)
    if err != nil {
        return fmt.Errorf("open migrations source: %w", err)
    }

    m, err := migrate.NewWithSourceInstance("iofs", source, toPgx5DSN(dsn))
    if err != nil {
        return fmt.Errorf("create migrate instance: %w", err)
    }
    defer func() { _, _ = m.Close() }()

    if err := m.Steps(-1); err != nil && !errors.Is(err, migrate.ErrNoChange) {
        return fmt.Errorf("rollback migration: %w", err)
    }

    version, dirty, verErr := m.Version()
    if verErr != nil {
        logger.Info().Msg("database rolled back to clean state (no migrations)")
    } else {
        logger.Info().Uint("version", version).Bool("dirty", dirty).Msg("database migration rolled back")
    }
    return nil
}

// Version returns the current migration version and dirty state.
func Version(migrations fs.FS, subdir, dsn string) (version uint, dirty bool, err error) {
    source, err := iofs.New(migrations, subdir)
    if err != nil {
        return 0, false, fmt.Errorf("open migrations source: %w", err)
    }

    m, err := migrate.NewWithSourceInstance("iofs", source, toPgx5DSN(dsn))
    if err != nil {
        return 0, false, fmt.Errorf("create migrate instance: %w", err)
    }
    defer func() { _, _ = m.Close() }()

    return m.Version()
}
```

### db/embed.go

```go
package db

import "embed"

// MigrationFS contains all SQL migration files from db/migration/.
//
//go:embed migration/*.sql
var MigrationFS embed.FS
```

### cmd/migrate/main.go

```go
package main

import (
    "fmt"
    "os"

    "github.com/rs/zerolog"

    "<service-name>/db"
    "<service-name>/internal/platform/config"
    "<service-name>/internal/platform/logger"
    dbmigrate "<service-name>/internal/platform/migrate"
)

func main() {
    cfg := config.Load()
    log := logger.New(cfg.Log.Level)

    if len(os.Args) < 2 {
        fmt.Fprintln(os.Stderr, "usage: migrate <up|down|version>")
        os.Exit(1)
    }

    dsn := cfg.Postgres.DSN

    switch os.Args[1] {
    case "up":
        if err := dbmigrate.Run(db.MigrationFS, "migration", dsn, log); err != nil {
            log.Fatal().Err(err).Msg("migration up failed")
        }
    case "down":
        if err := dbmigrate.Rollback(db.MigrationFS, "migration", dsn, log); err != nil {
            log.Fatal().Err(err).Msg("migration down failed")
        }
    case "version":
        version, dirty, err := dbmigrate.Version(db.MigrationFS, "migration", dsn)
        if err != nil {
            log.Fatal().Err(err).Msg("failed to get migration version")
        }
        fmt.Printf("version: %d, dirty: %v\n", version, dirty)
    default:
        fmt.Fprintf(os.Stderr, "unknown command: %s\nusage: migrate <up|down|version>\n", os.Args[1])
        os.Exit(1)
    }
}

func init() {
    zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
}
```

### cmd/\<service-name\>/main.go

```go
package main

import (
    "context"
    "errors"
    "net/http"
    "os"
    "os/signal"
    "syscall"

    "github.com/jackc/pgx/v5/pgxpool"
    _ "go.uber.org/automaxprocs"

    "<service-name>/db"
    "<service-name>/internal/platform/config"
    "<service-name>/internal/platform/httpserver"
    "<service-name>/internal/platform/logger"
    dbmigrate "<service-name>/internal/platform/migrate"
    transporthttp "<service-name>/internal/transport/http"
)

func main() {
    cfg := config.Load()
    log := logger.New(cfg.Log.Level)

    ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer stop()

    // --- Database migrations ---
    if err := dbmigrate.Run(db.MigrationFS, "migration", cfg.Postgres.DSN, log); err != nil {
        log.Fatal().Err(err).Msg("failed to run database migrations")
    }

    // --- PostgreSQL ---
    pgPool, err := pgxpool.New(ctx, cfg.Postgres.DSN)
    if err != nil {
        log.Fatal().Err(err).Msg("failed to create postgres connection pool")
    }
    defer pgPool.Close()

    if err := pgPool.Ping(ctx); err != nil {
        log.Fatal().Err(err).Msg("failed to ping postgres")
    }

    // --- Wire dependencies ---
    // store := pgadapter.NewStore(pgPool, log)
    // svc := <entity>.NewService(store, log)

    handler := transporthttp.NewHandler(/* svc, */ log)

    r := transporthttp.NewRouter(handler, func(ctx context.Context) map[string]string {
        deps := map[string]string{}
        if err := pgPool.Ping(ctx); err != nil {
            deps["postgres"] = "disconnected"
        } else {
            deps["postgres"] = "connected"
        }
        return deps
    }, log)

    port, readTimeout, writeTimeout, shutdownTimeout := cfg.Server.HTTPServerConfig()
    srv := httpserver.New(r, port, readTimeout, writeTimeout, shutdownTimeout, log)

    go func() {
        if err := srv.Start(); err != nil && !errors.Is(err, http.ErrServerClosed) {
            log.Fatal().Err(err).Msg("server failed")
        }
    }()

    log.Info().Int("port", cfg.Server.Port).Msg("<service-name> started")

    <-ctx.Done()
    log.Info().Msg("shutdown signal received")

    if err := srv.Shutdown(context.Background()); err != nil {
        log.Error().Err(err).Msg("shutdown error")
    }
}
```

### internal/transport/http/router.go

```go
package http

import (
    "github.com/go-chi/chi/v5"
    "github.com/go-chi/chi/v5/middleware"
    "github.com/rs/zerolog"

    "<service-name>/internal/platform/httpserver"
    commonmw "<service-name>/internal/platform/middleware"
)

// NewRouter creates a chi.Router with standard middleware, health endpoint,
// and all service routes.
func NewRouter(/* contextHandler *context.Handler, */ healthCheck httpserver.HealthChecker, log zerolog.Logger) chi.Router {
    r := chi.NewRouter()
    r.Use(middleware.Recoverer)
    r.Use(middleware.RealIP)
    r.Use(middleware.RequestID)
    r.Use(commonmw.RequestLogger(log))

    r.Get("/healthz", httpserver.HealthHandler(healthCheck))

    // Register context routes:
    // r.Post("/api/<resource>", contextHandler.Create)
    // r.Get("/api/<resource>/{id}", contextHandler.GetByID)
    // r.Get("/api/<resource>", contextHandler.List)
    // r.Put("/api/<resource>/{id}", contextHandler.Update)
    // r.Post("/api/<resource>/{id}/deactivate", contextHandler.Deactivate)

    return r
}
```

### internal/transport/http/\<context\>/request.go

```go
package <context>

// CreateRequest is the request body for creating a resource.
type CreateRequest struct {
    Name string `json:"name"`
}
```

### internal/transport/http/\<context\>/response.go

```go
package <context>

// Response is the response body for a single resource.
type Response struct {
    ID        string `json:"id"`
    Name      string `json:"name"`
    CreatedAt string `json:"created_at"`
}

// ListResponse wraps a paginated list of resources.
type ListResponse struct {
    Data   []Response `json:"data"`
    Total  int        `json:"total"`
    Limit  int        `json:"limit"`
    Offset int        `json:"offset"`
}

// ErrorResponse is the standard error response body.
type ErrorResponse struct {
    Code    string `json:"code"`
    Message string `json:"message"`
}
```

### internal/transport/http/\<context\>/handler.go

```go
package <context>

import (
    "encoding/json"
    "net/http"

    "github.com/rs/zerolog"
)

// Handler holds dependencies for HTTP handlers.
type Handler struct {
    // svc *<context>.Service
    log zerolog.Logger
}

// NewHandler creates a new Handler.
func NewHandler(/* svc *<context>.Service, */ log zerolog.Logger) *Handler {
    return &Handler{/* svc: svc, */ log: log}
}

// Create handles POST /api/<resource>.
func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
    var req CreateRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeError(w, http.StatusBadRequest, "bad_request", "Invalid request body")
        return
    }

    if req.Name == "" {
        writeError(w, http.StatusBadRequest, "bad_request", "Name is required")
        return
    }

    // result, err := h.svc.Create(r.Context(), req.Name)
    // if err != nil {
    //     handleDomainError(w, err)
    //     return
    // }

    // writeJSON(w, http.StatusCreated, toResponse(result))
}

func writeJSON(w http.ResponseWriter, status int, v any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    _ = json.NewEncoder(w).Encode(v)
}

func writeError(w http.ResponseWriter, status int, code, message string) {
    writeJSON(w, status, ErrorResponse{Code: code, Message: message})
}
```

---

## Testcontainers (Integration Tests)

All test files using containers must have the `//go:build integration` build tag.

### testinfra/postgres.go

```go
//go:build integration

package testinfra

import (
    "context"
    "fmt"
    "io/fs"
    "os"

    "github.com/jackc/pgx/v5/pgxpool"
    "github.com/rs/zerolog"
    tcpostgres "github.com/testcontainers/testcontainers-go/modules/postgres"

    dbmigrate "<service-name>/internal/platform/migrate"
)

// PostgresContainer wraps a testcontainers PostgreSQL instance, exposing the
// connection pool and providing helpers for migration and cleanup.
type PostgresContainer struct {
    container *tcpostgres.PostgresContainer
    Pool      *pgxpool.Pool
    DSN       string
}

// NewPostgres starts a PostgreSQL 17 container, creates a pgxpool, and returns
// the wrapper. Call Close() when done (typically deferred in TestMain).
func NewPostgres(ctx context.Context) (*PostgresContainer, error) {
    container, err := tcpostgres.Run(ctx,
        "postgres:17-alpine",
        tcpostgres.WithUsername("postgres"),
        tcpostgres.WithPassword("postgres"),
        tcpostgres.WithDatabase("testdb"),
        tcpostgres.BasicWaitStrategies(),
    )
    if err != nil {
        return nil, fmt.Errorf("start postgres container: %w", err)
    }

    dsn, err := container.ConnectionString(ctx, "sslmode=disable")
    if err != nil {
        _ = container.Terminate(ctx)
        return nil, fmt.Errorf("get postgres connection string: %w", err)
    }

    pool, err := pgxpool.New(ctx, dsn)
    if err != nil {
        _ = container.Terminate(ctx)
        return nil, fmt.Errorf("create pgxpool: %w", err)
    }

    if err := pool.Ping(ctx); err != nil {
        pool.Close()
        _ = container.Terminate(ctx)
        return nil, fmt.Errorf("ping postgres: %w", err)
    }

    return &PostgresContainer{
        container: container,
        Pool:      pool,
        DSN:       dsn,
    }, nil
}

// Migrate runs all pending up-migrations from the given embedded FS.
func (pc *PostgresContainer) Migrate(migrations fs.FS, subdir string) error {
    log := zerolog.New(os.Stderr).With().Str("component", "test-migrate").Logger()
    return dbmigrate.Run(migrations, subdir, pc.DSN, log)
}

// ApplyMigrationSQL executes raw SQL against the test database.
func (pc *PostgresContainer) ApplyMigrationSQL(ctx context.Context, sql string) error {
    _, err := pc.Pool.Exec(ctx, sql)
    if err != nil {
        return fmt.Errorf("exec migration sql: %w", err)
    }
    return nil
}

// Truncate removes all rows from the given table.
func (pc *PostgresContainer) Truncate(ctx context.Context, table string) error {
    _, err := pc.Pool.Exec(ctx, "TRUNCATE TABLE "+table)
    return err
}

// Close tears down the pool and terminates the container.
func (pc *PostgresContainer) Close(ctx context.Context) {
    if pc.Pool != nil {
        pc.Pool.Close()
    }
    if pc.container != nil {
        _ = pc.container.Terminate(ctx)
    }
}
```

### Usage in Tests

```go
//go:build integration

package mypackage_test

import (
    "context"
    "os"
    "testing"

    "<service-name>/db"
    "<service-name>/testinfra"
)

var pgContainer *testinfra.PostgresContainer

func TestMain(m *testing.M) {
    ctx := context.Background()

    var err error
    pgContainer, err = testinfra.NewPostgres(ctx)
    if err != nil {
        panic(err)
    }

    if err := pgContainer.Migrate(db.MigrationFS, "migration"); err != nil {
        pgContainer.Close(ctx)
        panic(err)
    }

    code := m.Run()
    pgContainer.Close(ctx)
    os.Exit(code)
}

func TestSomething(t *testing.T) {
    ctx := context.Background()
    _ = pgContainer.Truncate(ctx, "my_table")  // clean between tests
    // Use pgContainer.Pool for queries
}
```

**Available helpers on `PostgresContainer`:**
- `Pool` — `*pgxpool.Pool` for direct queries
- `DSN` — connection string
- `Migrate(fs, subdir)` — run embedded migrations
- `ApplyMigrationSQL(ctx, sql)` — run raw SQL
- `Truncate(ctx, table)` — truncate a table
- `Close(ctx)` — tear down pool and container

### Running Integration Tests

```bash
make test-integration    # Runs: go test -tags=integration -count=1 ./...
```

Docker must be running. Testcontainers manages container lifecycle automatically.

---

## Checklist for New Service

1. Copy directory structure from template above
2. Replace all `<service-name>` placeholders with the actual service name
3. Assign port number in `config.yaml`
4. Create `go.mod`, then `go mod tidy`
5. Write initial SQL migration in `db/migration/000001_create_<table>.up.sql` and `.down.sql`
6. Create `internal/domain/<context>/` package with aggregate, repository, service, and errors
7. Create `internal/transport/http/<context>/` package with handler, request, and response DTOs
8. Register routes in `router.go`
9. Run `make install-tools` then `make lint` and `make test`
