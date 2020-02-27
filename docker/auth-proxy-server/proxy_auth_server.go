package main

// proxy_auth_server - Go implementation of reverse proxy server with CERN SSO OAuth2 OICD
//
// Copyright (c) 2020 - Valentin Kuznetsov <vkuznet@gmail.com>
//

/*
This is a Go-based implementation of CMS reverse proxy server
with CERN SSO OAuth2 OICD authentication schema. An initial user
request is redirected oauth_url defined in configuration. Then it is
authenticated and this codebase provides CMS X509 headers based on
CMS CRIC meta-data. An additional hmac is set via cmsauth package.
The server can be initialize either as HTTP or HTTPs and provides the
following end-points
- /token returns information about tokens
- /renew renew user tokens
- /callback handles the callback authentication requests
- /server can be used to update server settings, e.g.
  curl -X POST -H"Content-type: application/json" -d '{"verbose":true}' https://a.b.com/server
  will update verbose level of the server
- / performs reverse proxy redirects to backends defined in ingress part of configuration

To access the server clients need to obtain an original token from web interface,
and then they may use it for CLI access, e.g.
curl -v -H "Authorization: Bearer $token" https://xxx.cern.ch/<path>
If token needs to be renewed, clients should use /renew end-point

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
	"io/ioutil"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"reflect"
	"strings"
	"time"

	oidc "github.com/coreos/go-oidc"
	"github.com/dmwm/cmsauth"
	"github.com/google/uuid"
	"github.com/thomasdarimont/go-kc-example/session"
	_ "github.com/thomasdarimont/go-kc-example/session_memory"
	"golang.org/x/oauth2"
)

// Ingress part of server configuration
type Ingress struct {
	Path       string `json:"path"`        // url path to the service
	ServiceUrl string `json:"service_url"` // service url
	OldPath    string `json:"old_path"`    // path from url to be replaced with new_path
	NewPath    string `json:"new_path"`    // path from url to replace old_path
}

// Configuration stores server configuration parameters
type Configuration struct {
	Port               int       `json:"port"`           // server port number
	Base               string    `json:"base"`           // base URL
	ClientID           string    `json:"client_id"`      // OICD client id
	ClientSecret       string    `json:"client_secret"`  // OICD client secret
	TargetUrl          string    `json:"target_url"`     // proxy target url (where requests will go)
	DocumentRoot       string    `json:"document_root"`  // root directory for the server
	OAuthUrl           string    `json:"oauth_url"`      // CERN SSO OAuth2 realm url
	AuthTokenUrl       string    `json:"auth_token_url"` // CERN SSO OAuth2 OICD Token url
	CMSHeaders         bool      `json:"cms_headers"`    // set CMS headers
	RedirectUrl        string    `json:"redirect_url"`   // redirect auth url for proxy server
	Verbose            bool      `json:"verbose"`        // verbose output
	Ingress            []Ingress `json:"ingress"`        // incress section
	ServerCrt          string    `json:"server_cert"`    // server certificate
	ServerKey          string    `json:"server_key"`     // server certificate
	Hmac               string    `json:"hmac"`           // cmsweb hmac file
	CricUrl            string    `json:"cric_url"`       // CRIC URL
	CricFile           string    `json:"cric_file"`      // name of the CRIC file
	UpdateCricInterval int64     `json:"update_cric"`    // interval (in sec) to update cric records
}

// ServerSettings controls server parameters
type ServerSettings struct {
	Verbose bool `json:"verbose"` // verbosity output
}

// TokenAttributes contains structure of access token attributes
type TokenAttributes struct {
	UserName     string `json:"username"`      // user name
	Active       bool   `json:"active"`        // is token active or not
	SessionState string `json:"session_state"` // session state fields
	ClientID     string `json:"clientId"`      // client id
	Email        string `json:"email"`         // client email address
	Scope        string `json:"scope"`         // scope of the token
	Expiration   int64  `json:"exp"`           // token expiration
	ClientHost   string `json:"clientHost"`    // client host
}

// TokenInfo contains information about all tokens
type TokenInfo struct {
	AccessToken   string `json:"access_token"`       // access token
	AccessExpire  int64  `json:"expires_in"`         // access token expiration
	RefreshToken  string `json:"refresh_token"`      // refresh token
	RefreshExpire int64  `json:"refresh_expires_in"` // refresh token expireation
	IdToken       string `json:"id_token"`           // id token
}

// String convert TokenInfo into html snippet
func (t *TokenInfo) String() string {
	var s string
	s = fmt.Sprintf("%s\nAccessToken:\n%s", s, t.AccessToken)
	s = fmt.Sprintf("%s\nAccessExpire: %d", s, t.AccessExpire)
	s = fmt.Sprintf("%s\nRefreshToken:\n%s", s, t.RefreshToken)
	s = fmt.Sprintf("%s\nRefreshExpire: %d", s, t.RefreshExpire)
	return s
}

// CMSAuth structure to create CMS Auth headers
var CMSAuth cmsauth.CMSAuth

// globalSession manager for our HTTP requests
var globalSessions *session.Manager

// Config variable represents configuration object
var Config Configuration

// CricRecords list to hold CMS CRIC entries
var CricRecords cmsauth.CricRecords

// AuthTokenUrl holds url for token authentication
var AuthTokenUrl string

// OAuth2Config holds OAuth2 configuration
var OAuth2Config oauth2.Config

// Verifier is ID token verifier
var Verifier *oidc.IDTokenVerifier

// Context for our requests
var Context context.Context

// initialize global session manager
func init() {
	globalSessions, _ = session.NewManager("memory", "gosessionid", 3600)
	go globalSessions.GC()
}

// helper function to parse server configuration file
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
	if Config.ClientID == "" {
		log.Fatal("No ClientID found in configuration file")
	}
	if Config.ClientSecret == "" {
		log.Fatal("No ClientSecret found in configuration file")
	}
	// default values
	if Config.Port == 0 {
		Config.Port = 8181
	}
	if Config.OAuthUrl == "" {
		Config.OAuthUrl = "https://auth.cern.ch/auth/realms/cern"
	}
	if Config.Verbose {
		log.Printf("%+v\n", Config)
	}
	return nil
}

// helper function to print JSON data
func printJSON(j interface{}, msg string) error {
	if msg != "" {
		log.Println(msg)
	}
	var out []byte
	var err error
	out, err = json.MarshalIndent(j, "", "    ")
	if err == nil {
		fmt.Println(string(out))
	}
	return err
}

// helper function to print HTTP request information
func printHTTPRequest(r *http.Request, msg string) {
	log.Printf("HTTP request: %s\n", msg)
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
func introspectToken(token string) (TokenAttributes, error) {
	verifyUrl := fmt.Sprintf("%s/introspect", AuthTokenUrl)
	form := url.Values{}
	form.Add("token", token)
	form.Add("client_id", Config.ClientID)
	form.Add("client_secret", Config.ClientSecret)
	r, err := http.NewRequest("POST", verifyUrl, strings.NewReader(form.Encode()))
	if err != nil {
		msg := fmt.Sprintf("unable to POST request to %s, %v", verifyUrl, err)
		return TokenAttributes{}, errors.New(msg)
	}
	r.Header.Add("Content-Type", "application/x-www-form-urlencoded")
	r.Header.Add("User-Agent", "go-client")
	client := http.Client{}
	if Config.Verbose {
		dump, err := httputil.DumpRequestOut(r, true)
		log.Println("request", string(dump), err)
	}
	resp, err := client.Do(r)
	if Config.Verbose {
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

// helper function to renew access token of the client
func renewToken(token string, r *http.Request) (TokenInfo, error) {
	if token == "" {
		msg := fmt.Sprintf("empty authorization token")
		return TokenInfo{}, errors.New(msg)
	}
	form := url.Values{}
	form.Add("refresh_token", token)
	form.Add("grant_type", "refresh_token")
	form.Add("client_id", Config.ClientID)
	form.Add("client_secret", Config.ClientSecret)
	r, err := http.NewRequest("POST", AuthTokenUrl, strings.NewReader(form.Encode()))
	if err != nil {
		msg := fmt.Sprintf("unable to POST request to %s, %v", AuthTokenUrl, err)
		return TokenInfo{}, errors.New(msg)
	}
	r.Header.Add("Content-Type", "application/x-www-form-urlencoded")
	r.Header.Add("User-Agent", "go-client")
	client := http.Client{}
	if Config.Verbose {
		dump, err := httputil.DumpRequestOut(r, true)
		log.Println("request", string(dump), err)
	}
	resp, err := client.Do(r)
	if Config.Verbose {
		dump, err := httputil.DumpResponse(resp, true)
		log.Println("response", string(dump), err)
	}
	if err != nil {
		msg := fmt.Sprintf("validate error: %+v", err)
		return TokenInfo{}, errors.New(msg)
	}
	defer resp.Body.Close()
	var tokenInfo TokenInfo
	err = json.NewDecoder(resp.Body).Decode(&tokenInfo)
	if err != nil {
		msg := fmt.Sprintf("unable to decode response body: %+v", err)
		return TokenInfo{}, errors.New(msg)
	}
	return tokenInfo, nil
}

// helper function to check access token of the client
// it is done via introspect auth end-point
func checkAccessToken(r *http.Request) bool {
	// extract token from a request
	tokenStr := r.Header.Get("Authorization")
	if tokenStr == "" {
		return false
	}
	// token is last part of Authorization header
	arr := strings.Split(tokenStr, " ")
	token := arr[len(arr)-1]
	// verify token
	attrs, err := introspectToken(token)
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
	if Config.Verbose {
		if err := printJSON(attrs, "token attributes"); err != nil {
			msg := fmt.Sprintf("Failed to output token attributes: %v", err)
			log.Println(msg)
		}
	}
	r.Header.Set("scope", attrs.Scope)
	r.Header.Set("client-host", attrs.ClientHost)
	r.Header.Set("client-id", attrs.ClientID)
	return true
}

// setting handler function, i.e. it can be used to change server settings
func serverSettingsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != "POST" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	defer r.Body.Close()
	var s = ServerSettings{}
	err := json.NewDecoder(r.Body).Decode(&s)
	if err != nil {
		log.Printf("unable to unmarshal incoming request, error %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	Config.Verbose = s.Verbose
	log.Println("Update verbose level of config", Config)
	w.WriteHeader(http.StatusOK)
	return
}

// callback handler function performs authentication callback and obtain
// user tokens
func serverCallbackHandler(w http.ResponseWriter, r *http.Request) {
	sess := globalSessions.SessionStart(w, r)
	if Config.Verbose {
		msg := fmt.Sprintf("call from '/callback', r.URL %s, sess.path %v", r.URL, sess.Get("path"))
		printHTTPRequest(r, msg)
	}
	state := sess.Get("somestate")
	if state == nil {
		http.Error(w, fmt.Sprintf("state did not match, %v", state), http.StatusBadRequest)
		return
	}
	if r.URL.Query().Get("state") != state.(string) {
		http.Error(w, fmt.Sprintf("r.URL state did not match, %v", state), http.StatusBadRequest)
		return
	}

	//exchanging the code for a token
	oauth2Token, err := OAuth2Config.Exchange(Context, r.URL.Query().Get("code"))
	if err != nil {
		http.Error(w, "Failed to exchange token: "+err.Error(), http.StatusInternalServerError)
		return
	}
	if Config.Verbose {
		log.Println("oauth2Token", oauth2Token)
	}
	rawIDToken, ok := oauth2Token.Extra("id_token").(string)
	if !ok {
		http.Error(w, "No id_token field in oauth2 token.", http.StatusInternalServerError)
		return
	}
	refreshToken, ok := oauth2Token.Extra("refresh_token").(string)
	refreshExpire, ok := oauth2Token.Extra("refresh_expires_in").(float64)
	accessExpire, ok := oauth2Token.Extra("expires_in").(float64)
	if Config.Verbose {
		log.Println("rawIDToken", rawIDToken)
	}
	idToken, err := Verifier.Verify(Context, rawIDToken)
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
	sess.Set("refreshToken", refreshToken)
	sess.Set("refreshExpire", int64(refreshExpire))
	sess.Set("accessExpire", int64(accessExpire))
	sess.Set("userinfo", resp.IDTokenClaims)
	urlPath := sess.Get("path").(string)
	if Config.Verbose {
		log.Println("session data", string(data))
		log.Println("redirect to", urlPath)
	}
	http.Redirect(w, r, urlPath, http.StatusFound)
	return
}

// server request handler performs reverse proxy action on incoming user request
// the proxy redirection is based on Config.Ingress dictionary, see Configuration
// struct. The only exceptions are /token and /renew end-points which used internally
// to display or renew user tokens, respectively
func serverRequestHandler(w http.ResponseWriter, r *http.Request) {
	sess := globalSessions.SessionStart(w, r)
	if Config.Verbose {
		msg := fmt.Sprintf("call from '/', r.URL %s, sess.Path %v", r.URL, sess.Get("path"))
		printHTTPRequest(r, msg)
	}
	oauthState := uuid.New().String()
	sess.Set("somestate", oauthState)
	if sess.Get("path") == nil || sess.Get("path") == "" {
		sess.Set("path", r.URL.Path)
	}
	// checking the userinfo in the session or if client provides valid access token.
	// if either is present we'll allow user request
	userInfo := sess.Get("userinfo")
	hasToken := checkAccessToken(r)
	accept := r.Header["Accept"][0]
	if userInfo != nil || hasToken {
		// decode userInfo
		var userData map[string]interface{}
		switch t := userInfo.(type) {
		case *json.RawMessage:
			err := json.Unmarshal(*t, &userData)
			if err != nil {
				msg := fmt.Sprintf("unable to decode user data, %v", err)
				http.Error(w, msg, http.StatusInternalServerError)
				return
			}
		}
		// set CMS headers
		if Config.CMSHeaders {
			if Config.Verbose {
				if err := printJSON(userData, "user data"); err != nil {
					log.Println("unable to print user data")
				}
			}
			CMSAuth.SetCMSHeaders(r, userData, CricRecords, Config.Verbose)
			if Config.Verbose {
				printHTTPRequest(r, "cms headers")
			}
		}
		// return token back to the user
		if r.URL.Path == fmt.Sprintf("%s/token", Config.Base) {
			var token, rtoken string
			t := sess.Get("rawIDToken")
			rt := sess.Get("refreshToken")
			if t == nil { // cli request
				if v, ok := r.Header["Authorization"]; ok {
					if len(v) == 1 {
						token = strings.Replace(v[0], "Bearer ", "", 1)
					}
				}
			} else {
				token = t.(string)
			}
			if rt == nil { // cli request
				if v, ok := r.Header["Refresh-Token"]; ok {
					if len(v) == 1 {
						rtoken = v[0]
					}
				}
			} else {
				rtoken = rt.(string)
			}
			var texp, rtexp int64
			if sess.Get("accessExpire") != nil {
				texp = sess.Get("accessExpire").(int64)
			}
			if sess.Get("refreshExpire") != nil {
				rtexp = sess.Get("refreshExpire").(int64)
			}
			tokenInfo := TokenInfo{AccessToken: token, RefreshToken: rtoken, AccessExpire: texp, RefreshExpire: rtexp, IdToken: token}
			if !strings.Contains(strings.ToLower(accept), "json") {
				w.Write([]byte(tokenInfo.String()))
				return
			}
			data, err := json.Marshal(tokenInfo)
			if err != nil {
				msg := fmt.Sprintf("unable to marshal token info, %v", err)
				http.Error(w, msg, http.StatusInternalServerError)
				return
			}
			w.Write(data)
			return
		}
		// renew existing token
		if r.URL.Path == fmt.Sprintf("%s/renew", Config.Base) {
			var token string
			t := sess.Get("refreshToken")
			if t == nil { // cli request
				if v, ok := r.Header["Authorization"]; ok {
					if len(v) == 1 {
						token = strings.Replace(v[0], "Bearer ", "", 1)
					}
				}
			} else {
				token = t.(string)
			}
			tokenInfo, err := renewToken(token, r)
			if err != nil {
				msg := fmt.Sprintf("unable to refresh access token, %v", err)
				http.Error(w, msg, http.StatusInternalServerError)
				return
			}
			if Config.Verbose {
				printJSON(tokenInfo, "new token info")
			}
			if !strings.Contains(strings.ToLower(accept), "json") {
				w.Write([]byte(tokenInfo.String()))
				return
			}
			data, err := json.Marshal(tokenInfo)
			if err != nil {
				msg := fmt.Sprintf("unable to marshal token info, %v", err)
				http.Error(w, msg, http.StatusInternalServerError)
				return
			}
			w.Write(data)
			return
		}
		// if Configuration provides Ingress rules we'll use them
		// to redirect user request
		for _, rec := range Config.Ingress {
			if strings.Contains(r.URL.Path, rec.Path) {
				if Config.Verbose {
					log.Printf("ingress request path %s, record path %s, service url %s, old path %s, new path %s\n", r.URL.Path, rec.Path, rec.ServiceUrl, rec.OldPath, rec.NewPath)
				}
				url := rec.ServiceUrl
				if rec.OldPath != "" {
					// replace old path to new one, e.g. /couchdb/_all_dbs => /_all_dbs
					r.URL.Path = strings.Replace(r.URL.Path, rec.OldPath, rec.NewPath, 1)
					// if r.URL.Path ended with "/", remove it to avoid
					// cases /path/index.html/ after old->new path substitution
					r.URL.Path = strings.TrimSuffix(r.URL.Path, "/")
					// replace empty path with root path
					if r.URL.Path == "" {
						r.URL.Path = "/"
					}
					if Config.Verbose {
						log.Printf("service url %s, new request path %s\n", url, r.URL.Path)
					}
				}
				log.Println("serveReverseProxy", url, r.URL.Path)
				serveReverseProxy(url, w, r)
				return
			}
		}
		// if no redirection was done, then we'll use either TargetURL
		// or return Hello reply
		if Config.TargetUrl != "" {
			serveReverseProxy(Config.TargetUrl, w, r)
		} else {
			if Config.DocumentRoot != "" {
				fname := fmt.Sprintf("%s%s", Config.DocumentRoot, r.URL.Path)
				if strings.HasSuffix(fname, "css") {
					w.Header().Set("Content-Type", "text/css")
				} else if strings.HasSuffix(fname, "js") {
					w.Header().Set("Content-Type", "application/javascript")
				}
				if r.URL.Path == "/" {
					fname = fmt.Sprintf("%s/index.html", Config.DocumentRoot)
				}
				if _, err := os.Stat(fname); err == nil {
					body, err := ioutil.ReadFile(fname)
					if err == nil {
						data := []byte(body)
						w.Write(data)
						return
					}
				}
			}
			msg := fmt.Sprintf("Hello %s", r.URL.Path)
			data := []byte(msg)
			w.Write(data)
			return
		}
		return
	}
	// there is no proper authentication yet, redirect users to auth callback
	aurl := OAuth2Config.AuthCodeURL(oauthState)
	if Config.Verbose {
		log.Println("auth redirect to", aurl)
	}
	http.Redirect(w, r, aurl, http.StatusFound)
	return
}

// auth server provides reverse proxy functionality with
// CERN SSO OAuth2 OICD authentication method
// It performs authentication of clients via internal callback function
// and redirects their requests to targetUrl of reverse proxy.
// If targetUrl is empty string it will redirect all request to
// simple hello page.
func auth_proxy_server(serverCrt, serverKey string) {

	// redirectUrl defines where incoming requests will be redirected for authentication
	redirectUrl := fmt.Sprintf("http://localhost:%d/callback", Config.Port)
	if serverCrt != "" {
		redirectUrl = fmt.Sprintf("https://localhost:%d/callback", Config.Port)
	}
	if Config.RedirectUrl != "" {
		redirectUrl = Config.RedirectUrl
	}

	// authTokenUrl defines where token can be obtained
	AuthTokenUrl = fmt.Sprintf("%s/protocol/openid-connect/token", Config.OAuthUrl)
	if Config.AuthTokenUrl != "" {
		AuthTokenUrl = Config.AuthTokenUrl
	}

	// Provider is a struct in oidc package that represents
	// an OpenID Connect server's configuration.
	Context = context.Background()
	provider, err := oidc.NewProvider(Context, Config.OAuthUrl)
	if err != nil {
		log.Fatal(err)
	}

	// configure an OpenID Connect aware OAuth2 client
	OAuth2Config = oauth2.Config{
		ClientID:     Config.ClientID,
		ClientSecret: Config.ClientSecret,
		RedirectURL:  redirectUrl,
		Endpoint:     provider.Endpoint(),
		Scopes:       []string{oidc.ScopeOpenID, "profile", "email"},
	}

	// define token ID verifier
	oidcConfig := &oidc.Config{ClientID: Config.ClientID}
	Verifier = provider.Verifier(oidcConfig)

	// define server handlers

	// the server settings handler
	http.HandleFunc(fmt.Sprintf("%s/server", Config.Base), serverSettingsHandler)

	// the callback authentication handler
	http.HandleFunc(fmt.Sprintf("%s/callback", Config.Base), serverCallbackHandler)

	// the request handler
	http.HandleFunc("/", serverRequestHandler)

	// start HTTP or HTTPs server based on provided configuration
	addr := fmt.Sprintf(":%d", Config.Port)
	if serverCrt != "" && serverKey != "" {
		//start HTTPS server which require user certificates
		server := &http.Server{Addr: addr}
		log.Printf("Starting HTTPs server on %s", addr)
		log.Fatal(server.ListenAndServeTLS(serverCrt, serverKey))
	} else {
		// Start server without user certificates
		log.Printf("Starting HTTP server on %s", addr)
		log.Fatal(http.ListenAndServe(addr, nil))
	}
}

func main() {
	var config string
	flag.StringVar(&config, "config", "", "configuration file")
	flag.Parse()
	err := parseConfig(config)
	if err == nil {
		CMSAuth.Init(Config.Hmac)
		// update periodically cric records
		go func() {
			cricRecords := make(cmsauth.CricRecords)
			var err error
			for {
				interval := Config.UpdateCricInterval
				if interval == 0 {
					interval = 3600
				}
				// parse cric records
				if Config.CricUrl != "" {
					cricRecords, err = cmsauth.GetCricData(Config.CricUrl, Config.Verbose)
					log.Printf("obtain CRIC records from %s, %v", Config.CricUrl, err)
				} else if Config.CricFile != "" {
					cricRecords, err = cmsauth.ParseCric(Config.CricFile, Config.Verbose)
					log.Printf("obtain CRIC records from %s, %v", Config.CricFile, err)
				} else {
					log.Println("Untable to get CRIC records no file or no url was provided")
				}
				if err != nil {
					log.Printf("Unable to update CRIC records: %v", err)
				} else {
					CricRecords = cricRecords
					keys := reflect.ValueOf(CricRecords).MapKeys()
					log.Println("Updated CRIC records", len(keys))
				}
				d := time.Duration(interval) * time.Second
				time.Sleep(d) // sleep for next iteration
			}
		}()
		_, e1 := os.Stat(Config.ServerCrt)
		_, e2 := os.Stat(Config.ServerKey)
		if e1 == nil && e2 == nil {
			auth_proxy_server(Config.ServerCrt, Config.ServerKey)
		} else {
			auth_proxy_server("", "")
		}
	}
}
