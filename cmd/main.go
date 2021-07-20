package main

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"
)

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Info(fmt.Sprintf("handling %v request on %v", r.Method, r.RequestURI))
		next.ServeHTTP(w, r)
	})
}

//go:embed home.html
var templatedHTML string

func defaultHandler(w http.ResponseWriter, req *http.Request) {
	for key, value := range map[string]string{
		"{{HOST}}":   req.Host,
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
	log.SetFormatter(&log.JSONFormatter{})
	log.Info("initializing server...")

	r := mux.NewRouter()
	r.Use(loggingMiddleware)

	r.HandleFunc("/", defaultHandler).Methods("GET")
	r.HandleFunc("/headers", headersHandler).Methods("GET")

	log.Fatal(http.ListenAndServe(":3000", r))
}
