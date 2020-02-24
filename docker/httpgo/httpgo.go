package main

import (
	"fmt"
	"log"
	"net/http"
	"net/http/httputil"
)

func RequestHandler(w http.ResponseWriter, r *http.Request) {
	requestDump, err := httputil.DumpRequest(r, true)
	if r.Method == "GET" {
		fmt.Println("TLS:", r.TLS)
		fmt.Println("Header:", r.Header)

		// print out all request headers
		fmt.Fprintf(w, "%s %s %s \n", r.Method, r.URL, r.Proto)
		for k, v := range r.Header {
			fmt.Fprintf(w, "Header field %q, Value %q\n", k, v)
		}
		fmt.Fprintf(w, "Host = %q\n", r.Host)
		fmt.Fprintf(w, "RemoteAddr= %q\n", r.RemoteAddr)
		fmt.Fprintf(w, "\n\nFinding value of \"Accept\" %q\n", r.Header["Accept"])

		page := "Hello from Go"
		w.Write([]byte(page))
	} else {
		if err != nil {
			fmt.Fprint(w, err.Error())
		} else {
			fmt.Fprint(w, string(requestDump))
		}
	}
	log.Println(string(requestDump))
}

func main() {
	http.HandleFunc("/", RequestHandler)
	http.ListenAndServe(":8888", nil)
}
