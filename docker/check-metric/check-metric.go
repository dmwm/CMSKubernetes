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
	"time"
)

type Metric struct {
	Name      string `json:"__name__"`
	App       string `json:"app"`
	Env       string `json:"env"`
	Instnace  string `json:"instance"`
	Job       string `json:"job"`
	Namespace string `json:"kubernetes_namespace"`
	PodName   string `json:"kubernetes_pod_name"`
	PodHash   string `json:"pod_template_hash"`
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
		if m.Name == metric {
			if len(r.Value) == 2 {
				s := r.Value[1].(string)
				v, e := strconv.ParseFloat(s, 10)
				if e != nil {
					log.Printf("Fail to convert value: %v, error %v\n", r.Value[1], e)
					return pods, e
				}
				if v > val {
					log.Printf("pod %s in namespace %s has %s=%v above threshold %v\n", m.PodName, m.Namespace, metric, v, val)
					pod := Pod{Name: m.PodName, Namespace: m.Namespace}
					pods = append(pods, pod)
				}
			}
		}
	}
	return pods, nil
}

func run(rurl, metric, value, kubectl string, dryRun bool, verbose int) {
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
				out, err := exec.Command(cmd).Output()
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
	if interval > 0 {
		for {
			run(rurl, metric, value, kubectl, dryRun, verbose)
			time.Sleep(time.Duration(interval) * time.Second)
		}
	} else {
		run(rurl, metric, value, kubectl, dryRun, verbose)
	}
}
