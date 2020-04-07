package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"time"

	"github.com/prometheus/procfs"
	"github.com/shirou/gopsutil/cpu"
	"github.com/shirou/gopsutil/load"
	"github.com/shirou/gopsutil/mem"
	"github.com/shirou/gopsutil/process"

	_ "expvar"         // to be used for monitoring, see https://github.com/divan/expvarmon
	_ "net/http/pprof" // profiler, see https://golang.org/pkg/net/http/pprof/
)

// global variabla
var lastUpdate time.Time
var verbose bool

func udpPing(host_port string) {
	// Connect to udp server
	conn, err := net.Dial("udp", host_port)
	if err != nil {
		fmt.Printf("Unable to contact: %s", host_port)
		return
	}
	defer conn.Close()

	// write ping message
	conn.Write([]byte("ping"))
}

func udpServerPID(pat string) int {
	cmd := fmt.Sprintf("ps auxw | grep \"%s\" | grep -v grep | awk '{print $2}'", pat)
	out, err := exec.Command("sh", "-c", cmd).Output()
	if err != nil {
		log.Printf("Unable to find process pattern: %v, error: %v\n", pat, err)
		return 0
	}
	pid, err := strconv.Atoi(string(out))
	if err != nil {
		return 0
	}
	return pid
}

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
	if verbose {
		log.Println("Execute:", cmd)
	}
	cmd.Stdout = pw
	cmd.Stderr = pw
	err := cmd.Run()
	if err != nil {
		log.Printf("Unable to start UDP server, error: %v\n", err)
		return
	}
}

func stop(pat string) bool {
	cmd := fmt.Sprintf("ps auxw | grep \"%s\" | grep -v grep | awk '{print $2}'", pat)
	if verbose {
		log.Println("Execute:", cmd)
	}
	out, err := exec.Command("sh", "-c", cmd).Output()
	if err != nil {
		log.Printf("Unable to find process pattern: %v, error: %v\n", pat, err)
		return false
	}
	pid := string(out)
	if pid != "" {
		cmd = fmt.Sprintf("kill -9 %s", pid)
		if verbose {
			log.Println("Execute:", cmd)
		}
		out, err = exec.Command("sh", "-c", cmd).Output()
		if err != nil {
			log.Printf("Unable to kill PID: %v, error: %v\n", pid, err)
			return false
		}
	}
	return true
}

func restart(config string, pw *io.PipeWriter, doStop bool) {
	if verbose {
		log.Println("Restart udp_server")
	}
	pat := fmt.Sprintf("udp_server -config %s", config)
	status := checkProcess(pat)
	if doStop && !status {
		stop(pat)
	}
	status = checkProcess(pat)
	if !status {
		start(config, pw)
	}
}

// requestHandler helper function for our monitoring server
// we should only received POST request from udp_server with pong data message
func requestHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	defer r.Body.Close()
	data, err := ioutil.ReadAll(r.Body)
	if verbose {
		log.Println("received", string(data), r.Method, r.RemoteAddr)
	}
	if err == nil {
		if string(data) == "pong" {
			lastUpdate = time.Now()
		}
	}
	w.WriteHeader(http.StatusOK)
}
func metricsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	pat := fmt.Sprintf("udp_server -config")
	pid := udpServerPID(pat)
	metrics := make(map[string]interface{})
	metrics["lastUpdate"] = lastUpdate.Unix()
	if v, e := mem.VirtualMemory(); e == nil {
		metrics["memory_percent"] = v.UsedPercent
		metrics["memory_total"] = float64(v.Total)
		metrics["memory_free"] = float64(v.Free)
	}
	if v, e := mem.SwapMemory(); e == nil {
		metrics["swap_percent"] = v.UsedPercent
		metrics["swap_total"] = float64(v.Total)
		metrics["swap_free"] = float64(v.Free)
	}
	if c, e := cpu.Percent(time.Millisecond, false); e == nil {
		metrics["cpu_percent"] = c[0] // one value since we didn't ask per cpu
	}
	if l, e := load.Avg(); e == nil {
		metrics["load1"] = l.Load1
		metrics["load5"] = l.Load5
		metrics["load15"] = l.Load15
	}
	if proc, err := procfs.NewProc(pid); err == nil {
		if stat, err := proc.NewStat(); err == nil {
			metrics["cpu_total"] = float64(stat.CPUTime())
			metrics["vsize"] = float64(stat.VirtualMemory())
			metrics["rss"] = float64(stat.ResidentMemory())
		}
		if fds, err := proc.FileDescriptorsLen(); err == nil {
			metrics["open_fds"] = float64(fds)
		}
		if limits, err := proc.NewLimits(); err == nil {
			metrics["max_fds"] = float64(limits.OpenFiles)
			metrics["max_vsize"] = float64(limits.AddressSpace)
		}
	}
	var estCon, lisCon, othCon, totCon, closeCon, timeCon float64
	if proc, err := process.NewProcess(int32(pid)); err == nil {
		if v, e := proc.CPUPercent(); e == nil {
			metrics["proccess_cpu"] = float64(v)
		}
		if v, e := proc.MemoryPercent(); e == nil {
			metrics["process_memory"] = float64(v)
		}

		if v, e := proc.NumThreads(); e == nil {
			metrics["number_threads"] = float64(v)
		}
		if connections, e := proc.Connections(); e == nil {
			for _, v := range connections {
				if v.Status == "LISTEN" {
					lisCon += 1
				} else if v.Status == "ESTABLISHED" {
					estCon += 1
				} else if v.Status == "TIME_WAIT" {
					timeCon += 1
				} else if v.Status == "CLOSE_WAIT" {
					closeCon += 1
				} else {
					othCon += 1
				}
			}
			totCon = lisCon + estCon + timeCon + closeCon + othCon
			metrics["total_connections"] = totCon
			metrics["listen_connections"] = lisCon
			metrics["established_connections"] = estCon
			metrics["time_connections"] = timeCon
			metrics["closed_connections"] = closeCon
			metrics["other_connections"] = othCon
		}
		if oFiles, e := proc.OpenFiles(); e == nil {
			metrics["open_files"] = float64(len(oFiles))
		}
	}
	data, err := json.Marshal(metrics)
	log.Println("metrics", string(data), err)
	if err == nil {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(data))
		return
	}
	log.Println(err)
	w.WriteHeader(http.StatusInternalServerError)
}

func main() {
	var config string
	flag.StringVar(&config, "config", "udp_server.json", "UDP server config")
	flag.Parse()

	// parse config file
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

	// setup variables from config parameters
	hostPort := fmt.Sprintf(":%d", int64(c["port"].(float64)))
	monHostPort := fmt.Sprintf(":%d", int64(c["monitorPort"].(float64)))
	d := time.Duration(int64(c["monitorInterval"].(float64))) * time.Second
	verbose = c["verbose"].(bool)
	if verbose {
		log.SetFlags(log.LstdFlags | log.Lshortfile)
	} else {
		log.SetFlags(log.LstdFlags)
	}

	// create a pipe to capture subprocess output
	pr, pw := io.Pipe()
	defer pr.Close()
	defer pw.Close()
	go func() {
		if _, err := io.Copy(os.Stdout, pr); err != nil {
			log.Printf("Unable to pipe udp_server output, error: %v\n", err)
		}
	}()

	// start udp_server process if it is not running
	go restart(config, pw, false)
	lastUpdate = time.Now()

	// create goroutine with running UDP ping
	go func() {
		for {
			time.Sleep(1 * time.Second)
			udpPing(hostPort)
		}
	}()

	// check asynchronously if our udp_server is running, if not we'll restart it
	go func() {
		for {
			// check that we receive last update
			sec := time.Since(lastUpdate).Seconds()
			if sec > 2*time.Duration(d).Seconds() {
				log.Printf("No repsonse from udp_server for %v seconds, last update: %v\n", sec, lastUpdate)
				go restart(config, pw, true) // true refers that we'll stop existing process
				lastUpdate = time.Now()
			}
			time.Sleep(1 * time.Second)
		}
	}()

	// start our monitoring server
	http.HandleFunc("/metrics", metricsHandler)
	http.HandleFunc("/", requestHandler)
	http.ListenAndServe(monHostPort, nil)
}
