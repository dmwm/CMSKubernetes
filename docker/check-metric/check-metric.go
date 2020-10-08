package main

// File       : check-metric.go
// Author     : Valentin Kuznetsov <vkuznet AT gmail dot com>
// Created    : Fri Jul 24 15:13:57 EDT 2020
// Description: client k8s to check metrics in Prometheus and act upon them

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/http/httputil"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync"
	"time"
)

type Metric struct {
	Name      string `json:"__name__"`             // metric name
	App       string `json:"app"`                  // cmsweb k8s annotation
	Apod      string `json:"apod"`                 // cmsweb k8s annotation
	NS        string `json:"ns"`                   // cmsweb k8s annotations
	Env       string `json:"env"`                  // cmsweb env
	Instance  string `json:"instance"`             // cmsweb instance
	Job       string `json:"job"`                  // pod job name
	Namespace string `json:"kubernetes_namespace"` // k8s namespace
	PodName   string `json:"kubernetes_pod_name"`  // k8s pod name
	PodHash   string `json:"pod_template_hash"`    // k8d pod hash
}

type Record struct {
	Metric Metric        `json:"metric"`
	Value  []interface{} `json:"value"`
}
type Data struct {
	ResultType string   `json:"resultType"`
	Result     []Record `json:"result"`
}

type Response struct {
	Status string `json:"status"`
	Data   Data   `json:"data"`
}

type Pod struct {
	Namespace string `json:"namespace"`
	Name      string `json:"name"`
}

// helper function to get pod name and namespace from metric record
func getPodNameAndNS(m Metric) (string, string) {
	var name, ns string
	if m.Apod != "" {
		name = m.Apod
	} else if m.Name != "" {
		name = m.Name
	} else {
		log.Fatalf("unable to determine pod name from metric record %+v\n", m)
	}
	if m.NS != "" {
		ns = m.NS
	} else if m.Namespace != "" {
		ns = m.Namespace
	} else {
		log.Fatalf("unable to determine namespace from metric record %+v\n", m)
	}
	return name, ns
}

func findPods(rurl, metric, value string, verbose int) ([]Pod, error) {
	// declare our output
	var pods []Pod

	apiurl := fmt.Sprintf("%s/api/v1/query?query=%s", rurl, metric)
	req, err := http.NewRequest("GET", apiurl, nil)
	if err != nil {
		log.Printf("Request Error, error: %v\n", err)
		return pods, err
	}
	req.Header.Add("Accept-Encoding", "identity")
	req.Header.Add("Accept", "application/json")

	timeout := time.Duration(10) * time.Second
	client := &http.Client{Timeout: timeout}

	if verbose > 1 {
		log.Println("GET", apiurl)
	} else if verbose > 1 {
		dump, err := httputil.DumpRequestOut(req, true)
		if err == nil {
			log.Println("Request: ", string(dump))
		}
	}

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Response Error, error: %v\n", err)
		return pods, err
	}
	if resp.StatusCode != http.StatusOK {
		log.Printf("Http Response Code Error, status code: %d", resp.StatusCode)
		return pods, errors.New("Respose Error")
	}

	defer resp.Body.Close()
	var r Response
	// Deserialize the response into a map.
	if err := json.NewDecoder(resp.Body).Decode(&r); err != nil {
		d, e := ioutil.ReadAll(resp.Body)
		log.Printf("Error parsing the response body: %s, %+v\n", err, string(d))
		return pods, e
	}
	if verbose > 0 {
		log.Printf("Response: %+v\n", r)
	}
	if r.Status != "success" {
		return pods, errors.New("prometheus status: " + r.Status)
	}
	val, err := strconv.ParseFloat(value, 10)
	if err != nil {
		log.Printf("Fail to convert value: %v, error %v\n", value, err)
		return pods, err
	}
	for _, r := range r.Data.Result {
		m := r.Metric
		name, ns := getPodNameAndNS(m)
		if verbose > 1 {
			log.Println("look-up", name, "in", ns, "namespace")
		}
		if m.Name == metric {
			if len(r.Value) == 2 {
				s := r.Value[1].(string)
				v, e := strconv.ParseFloat(s, 10)
				if e != nil {
					log.Printf("Fail to convert value: %v, error %v\n", r.Value[1], e)
					return pods, e
				}
				if verbose > 1 {
					log.Println("check metric", metric, "of", name, "in", ns, "namespace, current value", v, "compare to requested value", val)
				}
				if v > val {
					log.Printf("pod %s in namespace %s has %s=%v above threshold %v\n", name, ns, metric, v, val)
					pod := Pod{Name: name, Namespace: ns}
					pods = append(pods, pod)
				}
			}
		}
	}
	return pods, nil
}

func run(rurl, metric, value, kubectl string, dryRun bool, verbose int, wg *sync.WaitGroup) {
	defer wg.Done()
	pods, err := findPods(rurl, metric, value, verbose)
	if err != nil {
		log.Println("Unable to find pods", err)
		return
	}
	if _, err := os.Stat(kubectl); err == nil {
		for _, pod := range pods {
			ns := pod.Namespace
			pn := pod.Name
			cmd := fmt.Sprintf("%s -n %s delete pod %s", kubectl, ns, pn)
			if dryRun {
				log.Println(cmd)
			} else {
				out, err := exec.Command(kubectl, "-n", ns, "delete", "pod", pn).Output()
				if err != nil {
					log.Printf("Fail to execute: %s, error %v\n", cmd, err)
				}
				if verbose > 0 {
					log.Println("Executed: %s, output %v\n", cmd, out)
				}
			}
		}
	}
}

func main() {
	var verbose int
	flag.IntVar(&verbose, "verbose", 0, "verbosity level")
	// http://prometheus-service.monitoring.svc.cluster.local:8080/api/v1/query
	var rurl string
	flag.StringVar(&rurl, "url", "", "prometheus url")
	var metric string
	flag.StringVar(&metric, "metric", "", "prometheus metric to lookup")
	var value string
	flag.StringVar(&value, "value", "", "metric value to check")
	var kubectl string
	flag.StringVar(&kubectl, "kubectl", "", "kubectl command to use")
	var dryRun bool
	flag.BoolVar(&dryRun, "dryRun", false, "do not execute kubectl command but run the entire pipeline")
	var interval int
	flag.IntVar(&interval, "interval", 0, "run as daemon and check metrics with this interval (in seconds)")
	flag.Parse()
	// get list of metrics and their values
	metrics := strings.Split(metric, ",")
	values := strings.Split(value, ",")
	if len(metrics) != len(values) {
		log.Fatal("length metrics != length values")
	}
	if interval > 0 {
		// run in daemon mode and concurrently
		for {
			var wg sync.WaitGroup
			for i := 0; i < len(values); i++ {
				wg.Add(1)
				m := strings.Trim(metrics[i], " ")
				v := strings.Trim(values[i], " ")
				go run(rurl, m, v, kubectl, dryRun, verbose, &wg)
			}
			wg.Wait()
			time.Sleep(time.Duration(interval) * time.Second)
		}
	} else {
		// run once, but concurrently
		var wg sync.WaitGroup
		for i := 0; i < len(values); i++ {
			wg.Add(1)
			m := strings.Trim(metrics[i], " ")
			v := strings.Trim(values[i], " ")
			go run(rurl, m, v, kubectl, dryRun, verbose, &wg)
		}
		wg.Wait()
	}
}
