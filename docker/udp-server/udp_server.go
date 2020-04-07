package main

// udp_server - UDP Server implementation with optional support to send UDP messages
//              to StompAMQ endpoint
//
// Copyright (c) 2020 - Valentin Kuznetsov <vkuznet@gmail.com>
//

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"strings"

	"github.com/go-stomp/stomp"
)

// global pointer to Stomp connection
var stompConn *stomp.Conn

// Configuration stores server configuration parameters
type Configuration struct {
	Port            int    `json:"port"`            // server port number
	MonitorPort     int    `json:"monitorPort"`     // server monitor port number
	MonitorInterval int    `json:"monitorInterval"` // server monitor interval
	BufSize         int    `json:"bufSize"`         // buffer size
	StompURI        string `json:"stompURI"`        // StompAMQ URI
	StompLogin      string `json:"stompLogin"`      // StompAQM login name
	StompPassword   string `json:"stompPassword"`   // StompAQM password
	StompIterations int    `json:"stompIterations"` // Stomp iterations
	Endpoint        string `json:"endpoint"`        // StompAMQ endpoint
	ContentType     string `json:"contentType"`     // ContentType of UDP packet
	Verbose         bool   `json:"verbose"`         // verbose output
}

var Config Configuration

// parseConfig parse given config file
func parseConfig(configFile string) error {
	data, err := ioutil.ReadFile(configFile)
	if err != nil {
		log.Println("Unable to read", err)
		return err
	}
	err = json.Unmarshal(data, &Config)
	if err != nil {
		log.Println("Unable to parse", err)
		return err
	}
	// default values
	if Config.Port == 0 {
		Config.Port = 9331 // default port
	}
	if Config.MonitorPort == 0 {
		Config.MonitorPort = 9330 // default port
	}
	if Config.MonitorInterval == 0 {
		Config.MonitorInterval = 10 // default 10 seconds
	}
	if Config.BufSize == 0 {
		Config.BufSize = 1024 // 1 KByte
	}
	if Config.StompIterations == 0 {
		Config.StompIterations = 3 // number of Stomp attempts
	}
	if Config.ContentType == "" {
		Config.ContentType = "application/json"
	}
	return nil
}

// StompConnection returns Stomp connection
func StompConnection() (*stomp.Conn, error) {
	if Config.StompURI == "" {
		err := errors.New("Unable to connect to Stomp, not URI")
		return nil, err
	}
	if Config.StompLogin == "" {
		err := errors.New("Unable to connect to Stomp, not login")
		return nil, err
	}
	if Config.StompPassword == "" {
		err := errors.New("Unable to connect to Stomp, not password")
		return nil, err
	}
	conn, err := stomp.Dial("tcp",
		Config.StompURI,
		stomp.ConnOpt.Login(Config.StompLogin, Config.StompPassword))
	if err != nil {
		log.Printf("Unable to connect to %s, error %v", Config.StompURI, err)
	}
	if Config.Verbose {
		log.Printf("connected to StompAMQ server %s %v", Config.StompURI, conn)
	}
	return conn, err
}

func sendDataToStomp(data []byte) {
	for i := 0; i < Config.StompIterations; i++ {
		err := stompConn.Send(Config.Endpoint, Config.ContentType, data)
		if err != nil {
			if i == Config.StompIterations-1 {
				log.Printf("unable to send data to %s, data %s, error %v, iteration %d", Config.Endpoint, string(data), err, i)
			} else {
				log.Printf("unable to send data to %s, error %v, iteration %d", Config.Endpoint, err, i)
			}
			if stompConn != nil {
				stompConn.Disconnect()
			}
			stompConn, err = StompConnection()
		} else {
			if Config.Verbose {
				log.Printf("send data to StompAMQ endpoint %s", Config.Endpoint)
			}
			return
		}
	}
}

// udp server implementation
func udpServer() {
	conn, err := net.ListenUDP("udp", &net.UDPAddr{
		Port: Config.Port,
		IP:   net.ParseIP("0.0.0.0"),
	})
	if err != nil {
		panic(err)
	}

	defer conn.Close()
	log.Printf("UDP server %s\n", conn.LocalAddr().String())

	stompConn, err = StompConnection()
	// defer stomp connection if it exists
	if stompConn != nil {
		defer stompConn.Disconnect()
	}

	// set initial buffer size to handle UDP packets
	bufSize := Config.BufSize
	for {
		// create a buffer we'll use to read the UDP packets
		buffer := make([]byte, bufSize)

		// read UDP packets
		rlen, remote, err := conn.ReadFromUDP(buffer[:])
		if err != nil {
			log.Printf("Unable to read UDP packet, error %v", err)
			// clear-up our buffer
			buffer = buffer[:0]
			continue
		}
		data := buffer[:rlen]

		// if we receive ping message from monitoring server
		// we will send POST HTTP request to it with our pong reply
		if string(data) == "ping" {
			if Config.Verbose {
				log.Println("received monitor", string(data))
			}
			// send POST request to monitoring server, but don't care about response
			s := []byte("pong")
			rurl := fmt.Sprintf("http://localhost:%d", Config.MonitorPort)
			http.Post(rurl, "text/plain", bytes.NewBuffer(s))

			// clean-up our buffer
			buffer = buffer[:0]
			continue
		}

		// try to parse the data, we are expecting JSON
		var packet map[string]interface{}
		err = json.Unmarshal(data, &packet)
		if err != nil {
			log.Printf("unable to unmarshal UDP packet into JSON, error %v\n", err)
			e := string(err.Error())
			if strings.Contains(e, "invalid character") {
				// nothing we can do about mailformed JSON, let's dump it
				fmt.Println(string(data))
			} else if strings.Contains(e, "unexpected end of JSON input") {
				// let's increse buf size to adjust to the packet size
				bufSize = bufSize * 2
				if bufSize > 1024*Config.BufSize {
					log.Fatalf("unable to unmarshal UDP packet into JSON with buffer size %d", bufSize)
				}
			}
			// at this point we already read from UDP connection and our
			// message didn't fit into buffer therefore we may skip the rest
			// clear-up our buffer and continue
			buffer = buffer[:0]
			continue
		}

		// dump message to our log
		if Config.Verbose {
			sdata := strings.TrimSpace(string(data))
			log.Printf("received: %s from %s\n", sdata, remote)
		}

		// send data to Stomp endpoint
		if Config.Endpoint != "" && stompConn != nil {
			sendDataToStomp(data)
		}

		// clear-up our buffer
		buffer = buffer[:0]
	}
}

func main() {
	var config string
	flag.StringVar(&config, "config", "", "configuration file")
	flag.Parse()
	err := parseConfig(config)
	if Config.Verbose {
		log.SetFlags(log.LstdFlags | log.Lshortfile)
	} else {
		log.SetFlags(log.LstdFlags)
	}
	if err == nil {
		udpServer()
	}
	log.Fatal(err)
}
