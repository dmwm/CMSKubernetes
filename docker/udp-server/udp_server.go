package main

// udp_server - UDP Server implementation with optional support to send UDP messages
//              to StompAMQ endpoint
//
// Copyright (c) 2020 - Valentin Kuznetsov <vkuznet@gmail.com>
//

import (
	"encoding/json"
	"flag"
	"io/ioutil"
	"log"
	"net"
	"strings"

	"github.com/go-stomp/stomp"
)

// Configuration stores server configuration parameters
type Configuration struct {
	Port          int    `json:"port"`          // server port number
	BufSize       int    `json:"bufSize"`       // buffer size
	StompURI      string `json:"stompURI"`      // StompAMQ URI
	StompLogin    string `json:"stompLogin"`    // StompAQM login name
	StompPassword string `json:"stompPassword"` // StompAQM password
	Endpoint      string `json:"endpoint"`      // StompAMQ endpoint
	ContentType   string `json:"contentType"`   // ContentType of UDP packet
	Verbose       bool   `json:"verbose"`       // verbose output
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
		Config.Port = 9331
	}
	if Config.BufSize == 0 {
		Config.BufSize = 1024 // 1 KByte
	}
	if Config.ContentType == "" {
		Config.ContentType = "application/json"
	}
	return nil
}

// send data to StompAMQ endpoint
func sendStomp() {
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

	var stompConn *stomp.Conn
	if Config.StompURI != "" && Config.StompLogin != "" && Config.StompPassword != "" {
		stompConn, err = stomp.Dial("tcp",
			Config.StompURI,
			stomp.ConnOpt.Login(Config.StompLogin, Config.StompPassword))
		if err != nil {
			log.Printf("Unable to connect to %s, error %v", Config.StompURI, err)
		}
		if Config.Verbose {
			log.Printf("connected to StompAMQ server %s %v", Config.StompURI, stompConn)
		}
	}
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
			continue
		}
		data := buffer[:rlen]

		// try to parse the data, we are expecting JSON
		var packet map[string]interface{}
		err = json.Unmarshal(data, &packet)
		if err != nil {
			log.Printf("unable to unmarshal UDP packet into JSON, error %v\n", err)
			// let's increse buf size to adjust to the packet
			bufSize = bufSize * 2
			if bufSize > 100*Config.BufSize {
				log.Fatal("unable to unmarshal UDP packet into JSON with buffer size %d", bufSize)
			}
		}

		// dump message to our log
		if Config.Verbose {
			sdata := strings.TrimSpace(string(data))
			log.Printf("received: %s from %s\n", sdata, remote)
		}

		// send data to Stomp endpoint
		if Config.Endpoint != "" && stompConn != nil {
			err = stompConn.Send(Config.Endpoint, Config.ContentType, data)
			if err != nil {
				log.Printf("Stomp, unable to send to %s, data %s, error %v", Config.Endpoint, string(data), err)
			} else {
				if Config.Verbose {
					log.Printf("send data to StompAMQ endpoint %s", Config.Endpoint)
				}
			}
		}

		// clear-up our buffer
		buffer = nil
	}
}

func main() {
	var config string
	flag.StringVar(&config, "config", "", "configuration file")
	flag.Parse()
	err := parseConfig(config)
	if err == nil {
		udpServer()
	}
	log.Fatal(err)
}
