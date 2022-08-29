package main

// k8s_info - tool to provide k8s information about pods/images, etc.
//
// Copyright (c) 2020 - Valentin Kuznetsov <vkuznet@gmail.com>
//

import (
	"encoding/json"
	"flag"
	"fmt"
	"net"
	"os/exec"
	"regexp"
	"strings"
)

// type State struct {
//     ContainerID string `json:"ContainerID"`
//     ExitCode    int    `json:"ExitCode"`
//     FinishedAt  string `json:"FinishedAt"`
//     Reason      string `json:"Reason"`
//     StartedAt   string `json:"StartedAt"`
// }
type ContainerStatus struct {
	ContainerID  string                 `json:"ContainerID"`
	Image        string                 `json:"Image"`
	ImageID      string                 `json:"ImageID"`
	LastState    interface{}            `json:"LastState"`
	Name         string                 `json:"Name"`
	Ready        bool                   `json:"Ready"`
	RestartCount int                    `json:"RestartCount"`
	State        map[string]interface{} `json:"State"`
}

type Metadata struct {
	Annotations       map[string]string        `json:"Annotations"`
	CreationTimestamp string                   `json:"CreationTimestamp"`
	GenerateName      string                   `json:"GenerateName"`
	Labels            map[string]string        `json:"Labels"`
	Name              string                   `json:"Name"`
	Namespace         string                   `json:"Namespace"`
	OwnerReferences   []map[string]interface{} `json:"OwnerReferences"`
}

type Spec struct {
	Containers []map[string]interface{} `json:"Containers"`
}

type Status struct {
	Conditions            []interface{}       `json:"Conditions"`
	ContainerStatuses     []ContainerStatus   `json:"ContainerStatuses"`
	HostIP                string              `json:"HostIP"`
	InitContainerStatuses []ContainerStatus   `json:"InitContainerStatuses"`
	Phase                 string              `json:"Phase"`
	PodIP                 string              `json:"PodIP"`
	PodIPs                []map[string]string `json:"PodIPs"`
	QosClass              string              `json:"QosClass"`
	StartTime             string              `json:"StartTime"`
}

type PodInfo struct {
	ApiVersion string   `json:"ApiVersion"`
	Kind       string   `json:"Kind"`
	Metadata   Metadata `json:"Metadata"`
	Spec       Spec     `json:"Spec"`
	Status     Status   `json:"Status"`
}

func (p *PodInfo) Info(pat string, verbose int) string {
	var info string
	//     fmt.Printf("pod info %+v\n", p)
	//     fmt.Printf("pod status %+v\n", p.Status)
	for _, cs := range p.Status.ContainerStatuses {
		if pat != "" {
			if matched, err := regexp.MatchString(pat, cs.Name); err == nil && !matched {
				continue
			}
		}
		//         fmt.Println("status", cs)
		info += fmt.Sprintf("name       : %s\n", cs.Name)
		info += fmt.Sprintf("image      : %s\n", cs.Image)
		if verbose > 0 {
			info += fmt.Sprintf("imageID    : %s\n", cs.ImageID)
			info += fmt.Sprintf("containerID: %s\n", cs.ContainerID)
		}
	}
	if verbose > 0 {
		host, err := net.LookupAddr(p.Status.HostIP)
		if err == nil {
			info += fmt.Sprintf("Host       : %s\n", host)
		} else {
			info += fmt.Sprintf("HostIP     : %s\n", p.Status.HostIP)
			info += fmt.Sprintf("PodIP      : %s\n", p.Status.PodIP)
		}
	}
	return info
}

// helper function to execute command
func exe(command string, args ...string) ([]string, error) {
	var out []string
	cmd := exec.Command(command, args...)
	stdout, err := cmd.Output()
	if err != nil {
		fmt.Println("ERROR:", err, "while executing", command, args)
		panic(err)
		//         return out, err
	}
	for _, v := range strings.Split(string(stdout), "\n") {
		if strings.HasPrefix(v, "NAME") {
			continue
		}
		arr := strings.Split(v, " ")
		if len(arr) > 0 {
			v := strings.Trim(arr[0], " ")
			if v != "" {
				out = append(out, arr[0])
			}
		}
	}
	return out, nil
}

// helper function to get namespaces
func namespaces() ([]string, error) {
	args := []string{"get", "namespaces", "-A"}
	out, err := exe("kubectl", args...)
	return out, err
}

// helper function to get deployments
func deployments(ns string) ([]string, error) {
	args := []string{"get", "deployments", "-n", ns}
	out, err := exe("kubectl", args...)
	return out, err
}

// helper function to get pods
func pods(ns string) ([]string, error) {
	args := []string{"get", "pods", "-n", ns}
	out, err := exe("kubectl", args...)
	return out, err
}

// helper function to get pod information
func info(pod, ns string) (PodInfo, error) {
	var rec PodInfo
	args := []string{"get", "pod", "-n", ns, pod, "-o", "json"}
	cmd := exec.Command("kubectl", args...)
	stdout, err := cmd.Output()
	if err != nil {
		return rec, err
	}
	//     fmt.Println("output of pod info", string(stdout))
	err = json.Unmarshal(stdout, &rec)
	return rec, err
}

// main function
func main() {
	var verbose int
	flag.IntVar(&verbose, "verbose", 0, "verbosity level")
	var ns string
	flag.StringVar(&ns, "n", "", "k8s namespace")
	var pattern string
	flag.StringVar(&pattern, "pattern", "", "pod name pattern to show")
	var pod string
	flag.StringVar(&pod, "pod", "", "k8s pod")
	flag.Parse()
	if pod != "" && ns != "" {
		p, err := info(pod, ns)
		if err == nil {
			fmt.Println(p.Info(pattern, verbose))
		} else {
			fmt.Println("pod", pod, "error", err)
		}
	} else {
		nss, _ := namespaces()
		if ns != "" {
			nss = []string{ns}
		}
		for _, ns := range nss {
			fmt.Println("namespace:", ns)
			pods, err := pods(ns)
			if err != nil {
				panic(err)
			}
			for _, pod := range pods {
				p, err := info(pod, ns)
				if err == nil {
					//                     fmt.Println(p.Info(pattern, verbose))
					msg := p.Info(pattern, verbose)
					if msg != "" {
						fmt.Println(msg)
					}
				} else {
					fmt.Println("pod", pod, "error", err)
				}
			}
		}
	}
}
