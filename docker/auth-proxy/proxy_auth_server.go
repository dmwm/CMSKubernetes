package main

// proxy_auth_server - Go implementation of reverse proxy server with CERN SSO OAuth2 OICD
//
// Copyright (c) 2020 - Valentin Kuznetsov <vkuznet@gmail.com>
//

/*
CERN SSO OAuth2 OICD
   https://gitlab.cern.ch/authzsvc/docs/keycloak-sso-examples

Reverse proxy examples:
   https://hackernoon.com/writing-a-reverse-proxy-in-just-one-line-with-go-c1edfa78c84b
   https://github.com/bechurch/reverse-proxy-demo/blob/master/main.go
   https://imti.co/golang-reverse-proxy/
   https://itnext.io/capturing-metrics-with-gos-reverse-proxy-5c36cb20cb20
*/

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"
	"time"

	oidc "github.com/coreos/go-oidc"
	"github.com/google/uuid"
	"github.com/thomasdarimont/go-kc-example/session"
	_ "github.com/thomasdarimont/go-kc-example/session_memory"
	"golang.org/x/oauth2"
)

// globalSession manager for our HTTP requests
var globalSessions *session.Manager

// initialize global session manager
func init() {
	globalSessions, _ = session.NewManager("memory", "gosessionid", 3600)
	go globalSessions.GC()
}

// TokenAttributes contains structure of valid token attributes
type TokenAttributes struct {
	UserName     string `json:"username"`
	Active       bool   `json:"active"`
	SessionState string `json:"session_state"`
	ClientID     string `json:"clientId"`
	Email        string `json:"email"`
	Scope        string `json:"scope"`
	Expiration   int64  `json:"exp"`
	ClientHost   string `json:"clientHost"`
}

// helper function to print JSON data
func printJSON(j interface{}) error {
	var out []byte
	var err error
	out, err = json.MarshalIndent(j, "", "    ")
	if err == nil {
		fmt.Println(string(out))
	}

	return err
}

// helper function to print HTTP requests
func printHTTPRequest(w http.ResponseWriter, r *http.Request) {
	log.Printf("user request info:\n")
	fmt.Println("TLS:", r.TLS)
	fmt.Println("Header:", r.Header)

	// print out all request headers
	fmt.Printf("%s %s %s \n", r.Method, r.URL, r.Proto)
	for k, v := range r.Header {
		fmt.Printf("Header field %q, Value %q\n", k, v)
	}
	fmt.Printf("Host = %q\n", r.Host)
	fmt.Printf("RemoteAddr= %q\n", r.RemoteAddr)
	fmt.Printf("\n\nFinding value of \"Accept\" %q\n", r.Header["Accept"])
}

// Serve a reverse proxy for a given url
func serveReverseProxy(targetUrl string, res http.ResponseWriter, req *http.Request) {
	// parse the url
	url, _ := url.Parse(targetUrl)

	// create the reverse proxy
	proxy := httputil.NewSingleHostReverseProxy(url)

	// Update the headers to allow for SSL redirection
	req.URL.Host = url.Host
	req.URL.Scheme = url.Scheme
	reqHost := req.Header.Get("Host")
	if reqHost == "" {
		name, err := os.Hostname()
		if err == nil {
			reqHost = name
		}
	}
	req.Header.Set("X-Forwarded-Host", reqHost)
	req.Host = url.Host

	// Note that ServeHttp is non blocking and uses a go routine under the hood
	proxy.ServeHTTP(res, req)
}

// helper function to verify/validate given token
func introspectToken(authUrl, token, clientID, clientSecret string, verbose bool) (TokenAttributes, error) {
	verifyUrl := fmt.Sprintf("%s/introspect", authUrl)
	form := url.Values{}
	form.Add("token", token)
	form.Add("client_id", clientID)
	form.Add("client_secret", clientSecret)
	r, err := http.NewRequest("POST", verifyUrl, strings.NewReader(form.Encode()))
	if err != nil {
		msg := fmt.Sprintf("unable to POST request to %s, %v", verifyUrl, err)
		return TokenAttributes{}, errors.New(msg)
	}
	r.Header.Add("Content-Type", "application/x-www-form-urlencoded")
	r.Header.Add("User-Agent", "go-client")
	client := http.Client{}
	if verbose {
		dump, err := httputil.DumpRequestOut(r, true)
		log.Println("request", string(dump), err)
	}
	resp, err := client.Do(r)
	if verbose {
		dump, err := httputil.DumpResponse(resp, true)
		log.Println("response", string(dump), err)
	}
	if err != nil {
		msg := fmt.Sprintf("validate error: %+v", err)
		return TokenAttributes{}, errors.New(msg)
	}
	defer resp.Body.Close()
	var tokenAttributes TokenAttributes
	err = json.NewDecoder(resp.Body).Decode(&tokenAttributes)
	if err != nil {
		msg := fmt.Sprintf("unable to decode response body: %+v", err)
		return TokenAttributes{}, errors.New(msg)
	}
	return tokenAttributes, nil

}

// helper function to check access token of the client
func checkAccessToken(authUrl, clientID, clientSecret string, r *http.Request, verbose bool) bool {
	// extract token from a request
	tokenStr := r.Header.Get("Authorization")
	if tokenStr == "" {
		return false
	}
	// token is last part of Authorization header
	arr := strings.Split(tokenStr, " ")
	token := arr[len(arr)-1]
	// verify token
	attrs, err := introspectToken(authUrl, token, clientID, clientSecret, verbose)
	if err != nil {
		msg := fmt.Sprintf("unable to verify token: %+v", err)
		log.Println(msg)
		return false
	}
	if !attrs.Active || attrs.Expiration-time.Now().Unix() < 0 {
		msg := fmt.Sprintf("token is invalid: %+v", attrs)
		log.Println(msg)
		return false
	}
	if verbose {
		if err := printJSON(attrs); err != nil {
			msg := fmt.Sprintf("Failed to output token attributes: %v", err)
			log.Println(msg)
		}
	}
	return true
}

// auth server provides reverse proxy functionality with
// CERN SSO OAuth2 OICD authentication method
// It performs authentication of clients via internal callback function
// and redirects their requests to targetUrl of reverse proxy.
// If targetUrl is empty string it will redirect all request to
// simple hello page.
func auth_proxy_server(targetUrl, clientID, clientSecret string, port int, verbose bool) {

	// redirectURL defines where incoming requests will be redirected for authentication
	redirectURL := fmt.Sprintf("http://localhost:%d/callback", port)
	// configURL defines CERN SSO OAuth2 OICD end-point
	configURL := "https://auth.cern.ch/auth/realms/cern"
	authURL := fmt.Sprintf("%s/protocol/openid-connect/token", configURL)

	// Provider is a struct in oidc package that represents
	// an OpenID Connect server's configuration.
	ctx := context.Background()
	provider, err := oidc.NewProvider(ctx, configURL)
	if err != nil {
		panic(err)
	}

	// Configure an OpenID Connect aware OAuth2 client.
	oauth2Config := oauth2.Config{
		ClientID:     clientID,
		ClientSecret: clientSecret,
		RedirectURL:  redirectURL,
		// Discovery returns the OAuth2 endpoints.
		Endpoint: provider.Endpoint(),
		// "openid" is a required scope for OpenID Connect flows.
		Scopes: []string{oidc.ScopeOpenID, "profile", "email"},
	}
	state := "somestate"
	oidcConfig := &oidc.Config{
		ClientID: clientID,
	}
	verifier := provider.Verifier(oidcConfig)

	// handling the callback authentication requests
	http.HandleFunc("/callback", func(w http.ResponseWriter, r *http.Request) {
		if verbose {
			printHTTPRequest(w, r)
		}
		sess := globalSessions.SessionStart(w, r)
		state := sess.Get(state)
		if state == nil {
			http.Error(w, fmt.Sprintf("state did not match, %v", state), http.StatusBadRequest)
			return
		}
		if r.URL.Query().Get("state") != state.(string) {
			http.Error(w, fmt.Sprintf("r.URL state did not match, %v", state), http.StatusBadRequest)
			return
		}

		//exchanging the code for a token
		oauth2Token, err := oauth2Config.Exchange(ctx, r.URL.Query().Get("code"))
		if err != nil {
			http.Error(w, "Failed to exchange token: "+err.Error(), http.StatusInternalServerError)
			return
		}
		rawIDToken, ok := oauth2Token.Extra("id_token").(string)
		if !ok {
			http.Error(w, "No id_token field in oauth2 token.", http.StatusInternalServerError)
			return
		}
		idToken, err := verifier.Verify(ctx, rawIDToken)
		if err != nil {
			http.Error(w, "Failed to verify ID Token: "+err.Error(), http.StatusInternalServerError)
			return
		}

		//preparing the data to be presented on the page
		//it includes the tokens and the user info
		resp := struct {
			OAuth2Token   *oauth2.Token
			IDTokenClaims *json.RawMessage // ID Token payload is just JSON.
		}{oauth2Token, new(json.RawMessage)}

		err = idToken.Claims(&resp.IDTokenClaims)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		data, err := json.MarshalIndent(resp, "", "    ")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		//storing the token and the info of the user in session memory
		sess.Set("rawIDToken", rawIDToken)
		sess.Set("userinfo", resp.IDTokenClaims)
		urlPath := sess.Get("path").(string)
		if verbose {
			fmt.Println("session data", string(data))
			fmt.Println("redirect to", urlPath)
		}
		http.Redirect(w, r, urlPath, http.StatusFound)
		return
	})

	// handling the user request
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if verbose {
			printHTTPRequest(w, r)
		}
		sess := globalSessions.SessionStart(w, r)
		oauthState := uuid.New().String()
		sess.Set(state, oauthState)
		sess.Set("path", r.URL.Path)
		// checking the userinfo in the session or if client provides valid access token.
		// if either is present we'll allow user request
		userInfo := sess.Get("userinfo")
		hasToken := checkAccessToken(authURL, clientID, clientSecret, r, verbose)
		if userInfo != nil || hasToken {
			if targetUrl == "" {
				msg := fmt.Sprintf("Hello %s", r.URL.Path)
				data := []byte(msg)
				w.Write(data)
			} else {
				serveReverseProxy(targetUrl, w, r)
			}
			return
		}
		// there is no proper authentication, redirect users to auth callback
		http.Redirect(w, r, oauth2Config.AuthCodeURL(oauthState), http.StatusFound)
		return
	})

	log.Printf("listening on port %d", port)
	uri := fmt.Sprintf(":%d", port)
	log.Fatal(http.ListenAndServe(uri, nil))
}

func main() {
	var targetUrl string
	flag.StringVar(&targetUrl, "targetUrl", "", "reverse proxy target Url")
	var client string
	flag.StringVar(&client, "client", "", "client ID")
	var secret string
	flag.StringVar(&secret, "secret", "", "client secret")
	var port int
	flag.IntVar(&port, "port", 8181, "port number")
	var verbose bool
	flag.BoolVar(&verbose, "verbose", false, "turn on verbosity output")
	flag.Parse()
	auth_proxy_server(targetUrl, client, secret, port, verbose)
}
