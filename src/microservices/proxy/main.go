package main

import (
	"log"
	"math/rand"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strconv"
	"time"
)

type Config struct {
	Port                   string
	MonolithURL            string
	MoviesServiceURL       string
	EventsServiceURL       string
	GradualMigration       bool
	MoviesMigrationPercent int
}

func loadConfig() *Config {
	config := &Config{}

	config.Port = os.Getenv("PORT")
	if config.Port == "" {
		config.Port = "8000"
	}

	config.MonolithURL = os.Getenv("MONOLITH_URL")
	if config.MonolithURL == "" {
		config.MonolithURL = "http://localhost:8080"
	}

	config.MoviesServiceURL = os.Getenv("MOVIES_SERVICE_URL")
	if config.MoviesServiceURL == "" {
		config.MoviesServiceURL = "http://localhost:8081"
	}

	config.EventsServiceURL = os.Getenv("EVENTS_SERVICE_URL")
	if config.EventsServiceURL == "" {
		config.EventsServiceURL = "http://localhost:8082"
	}

	gradualMigration := os.Getenv("GRADUAL_MIGRATION")
	config.GradualMigration = gradualMigration == "true"

	migrationPercent := os.Getenv("MOVIES_MIGRATION_PERCENT")
	if migrationPercent != "" {
		if percent, err := strconv.Atoi(migrationPercent); err == nil {
			config.MoviesMigrationPercent = percent
		}
	}

	return config
}

func main() {
	config := loadConfig()

	// Initialize random seed for migration percentage
	rand.Seed(time.Now().UnixNano())

	log.Printf("Starting API Gateway (Proxy Service) on port %s", config.Port)
	log.Printf("Monolith URL: %s", config.MonolithURL)
	log.Printf("Movies Service URL: %s", config.MoviesServiceURL)
	log.Printf("Events Service URL: %s", config.EventsServiceURL)
	log.Printf("Gradual Migration: %t", config.GradualMigration)
	log.Printf("Movies Migration Percent: %d%%", config.MoviesMigrationPercent)

	// Setup routes
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": true, "service": "proxy"}`))
	})

	// API routes with Strangler Fig pattern
	http.HandleFunc("/api/", func(w http.ResponseWriter, r *http.Request) {
		handleAPIRequest(w, r, config)
	})

	// Start server
	log.Fatal(http.ListenAndServe(":"+config.Port, nil))
}

func handleAPIRequest(w http.ResponseWriter, r *http.Request, config *Config) {
	path := r.URL.Path

	// Route to appropriate service based on path and migration strategy
	switch {
	case isMoviesPath(path):
		handleMoviesRequest(w, r, config)
	case isEventsPath(path):
		handleEventsRequest(w, r, config)
	default:
		// All other requests go to monolith
		proxyToMonolith(w, r, config)
	}
}

func isMoviesPath(path string) bool {
	moviesEndpoints := []string{
		"/api/movies",
		"/api/movies/",
	}

	for _, endpoint := range moviesEndpoints {
		if path == endpoint || len(path) > len(endpoint) && path[:len(endpoint)] == endpoint {
			return true
		}
	}
	return false
}

func isEventsPath(path string) bool {
	eventsEndpoints := []string{
		"/api/events",
		"/api/events/",
	}

	for _, endpoint := range eventsEndpoints {
		if path == endpoint || len(path) > len(endpoint) && path[:len(endpoint)] == endpoint {
			return true
		}
	}
	return false
}

func handleMoviesRequest(w http.ResponseWriter, r *http.Request, config *Config) {
	// Check if gradual migration is enabled and determine routing
	if config.GradualMigration && shouldRouteToMicroservice(config.MoviesMigrationPercent) {
		log.Printf("Routing movies request to microservice: %s %s", r.Method, r.URL.Path)
		proxyToService(w, r, config.MoviesServiceURL)
	} else {
		log.Printf("Routing movies request to monolith: %s %s", r.Method, r.URL.Path)
		proxyToMonolith(w, r, config)
	}
}

func handleEventsRequest(w http.ResponseWriter, r *http.Request, config *Config) {
	// Events always go to the events microservice
	log.Printf("Routing events request to microservice: %s %s", r.Method, r.URL.Path)
	proxyToService(w, r, config.EventsServiceURL)
}

func shouldRouteToMicroservice(migrationPercent int) bool {
	if migrationPercent <= 0 {
		return false
	}
	if migrationPercent >= 100 {
		return true
	}

	// Generate random number between 0-99 and check if it's less than migration percentage
	randomNum := rand.Intn(100)
	return randomNum < migrationPercent
}

func proxyToMonolith(w http.ResponseWriter, r *http.Request, config *Config) {
	proxyToService(w, r, config.MonolithURL)
}

func proxyToService(w http.ResponseWriter, r *http.Request, targetURL string) {
	// Parse the target URL
	target, err := url.Parse(targetURL)
	if err != nil {
		log.Printf("Error parsing target URL %s: %v", targetURL, err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	// Create a reverse proxy
	proxy := httputil.NewSingleHostReverseProxy(target)

	// Customize the request
	originalDirector := proxy.Director
	proxy.Director = func(req *http.Request) {
		originalDirector(req)
		req.Header.Set("X-Forwarded-Host", r.Header.Get("Host"))
		req.Header.Set("X-Origin-Host", target.Host)
		req.Header.Set("X-Forwarded-For", r.RemoteAddr)
	}

	// Handle errors
	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		log.Printf("Proxy error for %s %s to %s: %v", r.Method, r.URL.Path, targetURL, err)
		http.Error(w, "Service Unavailable", http.StatusServiceUnavailable)
	}

	// Forward the request
	proxy.ServeHTTP(w, r)
}
