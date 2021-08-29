package main

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"

	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	log "github.com/sirupsen/logrus"
)

func init() {
	log.SetFormatter(&log.JSONFormatter{})
	prometheus.Register(totalRequests)
	prometheus.Register(responseStatus)
	prometheus.Register(httpDuration)
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Info(fmt.Sprintf("handling %s request on %s", r.Method, r.RequestURI))
		route := mux.CurrentRoute(r)
		path, err := route.GetPathTemplate()
		if err != nil {
			log.Info(err)
		}

		timer := prometheus.NewTimer(httpDuration.WithLabelValues(path))
		next.ServeHTTP(w, r)

		statusCode := http.StatusOK
		responseStatus.WithLabelValues(strconv.Itoa(statusCode)).Inc()
		totalRequests.WithLabelValues("path").Inc()
		timer.ObserveDuration()
	})
}

//go:embed index.html
var templatedHTML string

func defaultHandler(w http.ResponseWriter, req *http.Request) {
	u, err := url.Parse(req.Host)
	if err != nil {
		log.Info(err)
	}

	for key, value := range map[string]string{
		"{{HOST}}":   u.Hostname(),
		"{{METHOD}}": req.Method,
		"{{COLOR}}":  os.Getenv("COLOR"),
	} {
		templatedHTML = strings.ReplaceAll(templatedHTML, key, value)
	}

	w.Header().Add("Content-Type", "text/html; charset=utf8")
	fmt.Fprintf(w, "%v", templatedHTML)
}

func headersHandler(w http.ResponseWriter, req *http.Request) {
	requestHeaders := make(map[string]string)
	for name, headers := range req.Header {
		for _, header := range headers {
			requestHeaders[name] = header
		}
	}
	w.Header().Add("Content-Type", "application/json")
	json.NewEncoder(w).Encode(requestHeaders)
}

func main() {
	log.Info("initializing server...")

	r := mux.NewRouter()
	r.Use(loggingMiddleware)

	r.HandleFunc("/", defaultHandler).Methods("GET")
	r.HandleFunc("/headers", headersHandler).Methods("GET")
	r.Path("/metrics").Handler(promhttp.Handler())

	log.Fatal(http.ListenAndServe(":8080", r))
}
