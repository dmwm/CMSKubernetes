package main

import (
    "encoding/json"
    "flag"
    "fmt"
    "io"
    "io/ioutil"
    "log"
    "net/http"
    "os"
    "os/exec"
    "regexp"
    "time"

    _ "expvar"         // to be used for monitoring, see https://github.com/divan/expvarmon
    _ "net/http/pprof" // profiler, see https://golang.org/pkg/net/http/pprof/
)

func checkProcess(pat string) bool {
    cmd := fmt.Sprintf("ps auxw | grep \"%s\" | grep -v grep", pat)
    out, err := exec.Command("sh", "-c", cmd).Output()
    if err != nil {
        log.Printf("Unable to find process pattern: %v, error: %v\n", pat, err)
        return false
    }
    matched, _ := regexp.MatchString(pat, fmt.Sprintf("%s", out))
    if matched {
        return true
    }
    return false
}

// helper function to start underlying udp_server server
// for pipe usage see https://zupzup.org/io-pipe-go/
func start(config string, pw *io.PipeWriter) {
    cmd := exec.Command("udp_server", "-config", config)
    cmd.Stdout = pw
    cmd.Stderr = pw
    err := cmd.Run()
    if err != nil {
        log.Printf("Unable to start UDP server, error: %v\n", err)
        return
    }
}

func monitor(port int64, config string) {
    pr, pw := io.Pipe()
    defer pr.Close()
    defer pw.Close()
    go func() {
        if _, err := io.Copy(os.Stdout, pr); err != nil {
            log.Printf("Unable to pipe udp_server output, error: %v\n", err)
            return
        }
    }()
    pat := "udp_server -config"
    // check local server
    status := checkProcess(pat)
    if !status {
        log.Printf("UDP server is not running, pattern: %v, status: %v, will start new server\n", pat, status)
        start(config, pw)
    }
    for {
        status = checkProcess(pat)
        if !status {
            log.Printf("UDP server, pattern: %v, status: %v, will restart the server\n", pat, status)
            start(config, pw)
        }
        sleep := time.Duration(10) * time.Second
        time.Sleep(sleep)
    }
}

func main() {
    var config string
    flag.StringVar(&config, "config", "udp_server.json", "UDP server config")
    flag.Parse()
    // parse UDP config file and find our on which port it is running
    data, e := ioutil.ReadFile(config)
    if e != nil {
        log.Fatalf("Unable to read config file: %v\n", config)
        os.Exit(1)
    }
    var c map[string]interface{}
    e = json.Unmarshal(data, &c)
    if e != nil {
        log.Fatalf("Unable to unmarshal data: %v\n", data)
    }
    port := int64(c["port"].(float64))
    go monitor(port, config)
    http.ListenAndServe(":9330", nil)
}
