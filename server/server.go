package server

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httputil"
)

type Server struct {
	debug bool

	err error
}

type Option func(*Server)

func Debug() Option {
	return func(s *Server) {
		s.debug = true
	}
}

func New(opts ...Option) *Server {
	srv := Server{}
	for _, opt := range opts {
		opt(&srv)
	}
	return &srv
}

func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// set CORS headers. Without these, HTTP Request from a different origin (elm-reactor for example) will fail,
	// resulting in a Network Error.
	// Only desirable for development, in a production setup these should likely not be set.
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
	w.Header().Set("Access-Control-Allow-Headers", "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

	// print request body and headers to stdout
	s.printRequest(r)
	if s.err != nil {
		http.Error(w, s.err.Error(), http.StatusInternalServerError)
		return
	}

	// CORS requests send OPTIONS before the actual request, only handle the headers.
	if r.Method == "OPTIONS" {
		return
	}

	if r.URL.Path == "/fail_500" {
		http.Error(w, "something went terribly wrong", http.StatusInternalServerError)
		return
	}

	if r.URL.Path == "/user/1" {
		json.NewEncoder(w).Encode(&User{
			Name: "groob",
			Age:  30,
		})
		return
	}

	// handle anything
	w.Write([]byte(`foo bar`))

	return
}

func (s *Server) printRequest(r *http.Request) {
	if s.err != nil || !s.debug {
		return
	}

	duplicate := r
	out, err := httputil.DumpRequest(duplicate, true)
	if err != nil {
		s.err = err
		return
	}

	fmt.Println(string(out))
	fmt.Println("")
	fmt.Println("")
}

type User struct {
	Name string `json:"name"`
	Age  int    `json:"age"`
}
