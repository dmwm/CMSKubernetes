package main

import (
	"fmt"
	"net/http"
)

func RequestHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	fmt.Println("TLS:", r.TLS)
	fmt.Println("Header:", r.Header)

	// print out all request headers
	fmt.Fprintf(w, "%s %s %s \n", r.Method, r.URL, r.Proto)
	for k, v := range r.Header {
		fmt.Fprintf(w, "Header field %q, Value %q\n", k, v)
	}
	fmt.Fprintf(w, "Host = %q\n", r.Host)
	fmt.Fprintf(w, "RemoteAddr= %q\n", r.RemoteAddr)
	fmt.Fprintf(w, "\n\nFinding value of \"Accept\" %q", r.Header["Accept"])

	w.WriteHeader(http.StatusOK)
	page := "Hello Go world!!!"
	w.Write([]byte(page))
}

func main() {
	http.HandleFunc("/", RequestHandler)
	http.ListenAndServe(":8888", nil)
}
