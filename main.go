package main

import (
	"log"
	"net/http"

	"github.com/groob/elm-http-request/server"
)

func main() {
	srv := server.New(
		server.Debug(),
	)
	log.Fatal(
		http.ListenAndServe(":3000", srv),
	)
}
