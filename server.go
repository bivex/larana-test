package main

import (
	"flag"
	"log"
	"net/http"
	"strings"
)

func withHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h := w.Header()
		h.Set("X-Frame-Options", "DENY")
		h.Set("X-Content-Type-Options", "nosniff")
		h.Set("Cross-Origin-Opener-Policy", "same-origin")
		h.Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		h.Set("Content-Security-Policy",
			"default-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; object-src 'none'; base-uri 'self'; frame-ancestors 'none'; require-trusted-types-for 'script'")

		// cache static assets for 1 hour
		path := r.URL.Path
		if strings.HasSuffix(path, ".css") || strings.HasSuffix(path, ".js") ||
			strings.HasSuffix(path, ".ico") || strings.HasSuffix(path, ".png") ||
			strings.HasSuffix(path, ".webp") || strings.HasSuffix(path, ".woff2") {
			h.Set("Cache-Control", "public, max-age=3600")
		} else {
			h.Set("Cache-Control", "public, max-age=60")
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	dir := flag.String("d", "./mysite/dist", "directory to serve")
	port := flag.String("p", ":8383", "port to listen on")
	flag.Parse()

	fs := http.FileServer(http.Dir(*dir))
	http.Handle("/", withHeaders(fs))

	log.Printf("serving %s on %s", *dir, *port)
	log.Fatal(http.ListenAndServe(*port, nil))
}
