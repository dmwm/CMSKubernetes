package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
)

type Configuration struct {
	Port      int    `json:port`
	ServerKey string `json:serverkey`
	ServerCrt string `json:servercrt`
}

var Config Configuration

func RequestHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	fmt.Println("Header:", r.Header)
	fmt.Println("TLS:", r.TLS)

	// print out all request headers
	fmt.Fprintf(w, "%s %s %s \n", r.Method, r.URL, r.Proto)
	for k, v := range r.Header {
		fmt.Fprintf(w, "Header field %q, Value %q\n", k, v)
	}
	fmt.Fprintf(w, "Host = %q\n", r.Host)
	fmt.Fprintf(w, "RemoteAddr= %q\n", r.RemoteAddr)
	fmt.Fprintf(w, "\n\nFinding value of \"Accept\" %q", r.Header["Accept"])

	w.WriteHeader(http.StatusOK)
	page := "Hello Go TLS world!!!"
	w.Write([]byte(page))
}

func parseConfig(configFile string) error {
	data, err := ioutil.ReadFile(configFile)
	if err != nil {
		fmt.Println(err)
		return err
	}
	err = json.Unmarshal(data, &Config)
	if err != nil {
		fmt.Println(err)
		return err
	}
	return nil
}

func main() {
	var config string
	flag.StringVar(&config, "config", "config.json", "server config JSON file")
	flag.Parse()

	err := parseConfig(config)
	if err != nil {
		panic(err)
	}
	http.HandleFunc("/", RequestHandler)
	server := &http.Server{
		Addr: fmt.Sprintf(":%d", Config.Port),
	}
	err = server.ListenAndServeTLS(Config.ServerCrt, Config.ServerKey)
	if err != nil {
		fmt.Println("Unable to start the server", err)
	}
}
