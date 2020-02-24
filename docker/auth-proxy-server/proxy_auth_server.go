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
- /token returns user based token
- /callback handles the callback authentication requests
- /clear clears global session
- /server can be used to update server settings, e.g.
  curl -X POST -H"Content-type: application/json" -d '{"verbose":true}' https://a.b.com/server
  will update verbose level of the server
- / performs reverse proxy redirects to user based path

Clients may obtain a token, see /token path, and use it in CLI access to the
service, e.g.
curl -v -H "Authorization: Bearer $token" https://xxx.cern.ch/<path>

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
	"crypto/tls"
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

// Ingress configuration
type Ingress struct {
	Path       string `json:"path"`        // url path to the service
	ServiceUrl string `json:"service_url"` // service url
}

// Configuration stores server configuration parameters
type Configuration struct {
	Port               int       `json:"port"`           // server port number
	Base               string    `json:"base"`           // base URL
	ClientID           string    `json:"client_id"`      // OICD client id
	ClientSecret       string    `json:"client_secret"`  // OICD client secret
	TargetUrl          string    `json:"target_url"`     // proxy target url (where requests will go)
	OAuthUrl           string    `json:"oauth_url"`      // CERN SSO OAuth2 realm url
	AuthTokenUrl       string    `json:"auth_token_url"` // CERN SSO OAuth2 OICD Token url
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

// TokenAttributes contains structure of valid token attributes
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

// CricEntry represents structure in CRIC
type CricEntry struct {
	DN    string              `json:"DN"`    // CRIC DN
	DNs   []string            `json:"DNs"`   // List of all DNs assigned to user
	ID    int64               `json:"ID"`    // CRIC ID
	Login string              `json:"LOGIN"` // CRIC Login name
	Name  string              `json:"NAME"`  // CRIC user name
	Roles map[string][]string `json:"ROLES"` // CRIC user roles
}

// String returns string representation of CricEntry
func (c *CricEntry) String() string {
	var roles string
	for _, r := range c.Roles {
		for _, v := range r {
			roles = fmt.Sprintf("%s\n%v", roles, v)
		}
	}
	r := fmt.Sprintf("ID: %d\nLogin: %s\nName: %s\nDN: %s\nDNs: %v\nRoles: %s", c.ID, c.Login, c.Name, c.DN, c.DNs, roles)
	return r
}

// CMSAuth structure to create CMS Auth headers
var CMSAuth cmsauth.CMSAuth

// globalSession manager for our HTTP requests
var globalSessions *session.Manager

// Config variable represents configuration object
var Config Configuration

// CricRecords list to hold CMS CRIC entries
var CricRecords map[string]CricEntry
var CricFileInfo os.FileInfo

// initialize global session manager
func init() {
	globalSessions, _ = session.NewManager("memory", "gosessionid", 3600)
	go globalSessions.GC()
}

// ParseConfig parse given config file
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
		fmt.Println(msg)
	}
	var out []byte
	var err error
	out, err = json.MarshalIndent(j, "", "    ")
	if err == nil {
		fmt.Println(string(out))
	}

	return err
}

// helper function to print HTTP requests
func printHTTPRequest(w http.ResponseWriter, r *http.Request, msg string) {
	log.Printf("user request info: %s\n", msg)
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

// getCricData helper function to download CRIC data
func getCricData(rurl string) (map[string]CricEntry, error) {
	cricRecords := make(map[string]CricEntry)
	var entries []CricEntry
	tr := &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
	}
	client := http.Client{Transport: tr}
	req, err := http.NewRequest("GET", rurl, nil)
	if err != nil {
		return cricRecords, err
	}
	req.Header.Set("Accept", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Unable to place client request, %v", req)
		return cricRecords, err
	}
	defer resp.Body.Close()
	if Config.Verbose {
		dump, err := httputil.DumpRequestOut(req, true)
		log.Printf("http request: headers %v, request %v, response %s, error %v", req.Header, req, string(dump), err)
	}
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Unable to read response, %v", resp)
		return cricRecords, err
	}
	err = json.Unmarshal(body, &entries)
	if err != nil {
		return cricRecords, err
	}
	if Config.Verbose {
		log.Printf("obtained %d records", len(entries))
	}
	// convert list of entries into a map
	for _, rec := range entries {
		recDNs := rec.DNs
		if r, ok := cricRecords[rec.Login]; ok {
			recDNs = r.DNs
			recDNs = append(recDNs, rec.DN)
			rec.DNs = recDNs
			if Config.Verbose {
				fmt.Printf("\nFound duplicate CRIC record\n%s\n%s\n", rec.String(), r.String())
			}
		} else {
			recDNs = append(recDNs, rec.DN)
			rec.DNs = recDNs
		}
		cricRecords[rec.Login] = rec
	}
	return cricRecords, nil
}

// parseCric helper function to parse cric file
func parseCric(fname string) (map[string]CricEntry, error) {
	cricRecords := make(map[string]CricEntry)
	var entries []CricEntry
	if fileInfo, err := os.Stat(fname); err == nil {
		if CricFileInfo == nil || CricRecords == nil {
			CricFileInfo = fileInfo
		} else {
			// check if file has changed, if not return all cric records
			if fileInfo.Size() == CricFileInfo.Size() && fileInfo.ModTime() == CricFileInfo.ModTime() {
				return CricRecords, nil
			}
		}
		CricFileInfo = fileInfo
		jsonFile, err := os.Open(fname)
		if err != nil {
			fmt.Println(err)
			return cricRecords, err
		}
		defer jsonFile.Close()
		byteValue, err := ioutil.ReadAll(jsonFile)
		if err != nil {
			fmt.Println(err)
			return cricRecords, err
		}
		json.Unmarshal(byteValue, &entries)
		// convert list of entries into a map
		for _, rec := range entries {
			recDNs := rec.DNs
			if r, ok := cricRecords[rec.Login]; ok {
				recDNs = r.DNs
				recDNs = append(recDNs, rec.DN)
				rec.DNs = recDNs
				if Config.Verbose {
					fmt.Printf("\nFound duplicate CRIC record\n%s\n%s\n", rec.String(), r.String())
				}
			} else {
				recDNs = append(recDNs, rec.DN)
				rec.DNs = recDNs
			}
			cricRecords[rec.Login] = rec
		}
	}
	return cricRecords, nil
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
func introspectToken(authTokenUrl, token string) (TokenAttributes, error) {
	verifyUrl := fmt.Sprintf("%s/introspect", authTokenUrl)
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

// helper function to check access token of the client
func checkAccessToken(authTokenUrl string, r *http.Request) bool {
	// extract token from a request
	tokenStr := r.Header.Get("Authorization")
	if tokenStr == "" {
		return false
	}
	// token is last part of Authorization header
	arr := strings.Split(tokenStr, " ")
	token := arr[len(arr)-1]
	// verify token
	attrs, err := introspectToken(authTokenUrl, token)
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
		if err := printJSON(attrs, "### token attributes"); err != nil {
			msg := fmt.Sprintf("Failed to output token attributes: %v", err)
			log.Println(msg)
		}
	}
	r.Header.Set("cms-scope", attrs.Scope)
	r.Header.Set("cms-host", attrs.ClientHost)
	r.Header.Set("cms-client-id", attrs.ClientID)
	return true
}

// helper function to set headers based on provider user data
func setHeaders(userData map[string]interface{}, r *http.Request) {
	if Config.Verbose {
		if err := printJSON(userData, "### user data"); err != nil {
			log.Println("unable to print user data")
		}
		fmt.Println("### r.URL", r.URL)
	}
	// set cms auth headers
	r.Header.Set("cms-auth-status", "ok")
	r.Header.Set("cms-authn-name", iString(userData["name"]))
	login := iString(userData["cern_upn"])
	if rec, ok := CricRecords[login]; ok {
		// set DN
		r.Header.Set("cms-authn-dn", rec.DN)
		r.Header.Set("cms-auth-cert", rec.DN)
		// set group roles
		for k, v := range rec.Roles {
			key := fmt.Sprintf("cms-authz-%s", k)
			val := strings.Join(v, " ")
			r.Header.Set(key, val)
		}
	}
	r.Header.Set("cms-authn-login", login)
	r.Header.Set("cms-authn-method", "X509Cert")
	r.Header.Set("cms-cern-id", iString(userData["cern_person_id"]))
	r.Header.Set("cms-email", iString(userData["email"]))
	r.Header.Set("cms-auth-time", iString(userData["auth_time"]))
	r.Header.Set("cms-auth-expire", iString(userData["exp"]))
	r.Header.Set("cms-session", iString(userData["session_state"]))
	r.Header.Set("cms-request-uri", r.URL.Path)
	hmac, err := CMSAuth.GetHmac(r, Config.Verbose)
	if err == nil {
		r.Header.Set("cms-authn-hmac", hmac)
	}
}

// helper function to return string representation of interface value
func iString(v interface{}) string {
	switch t := v.(type) {
	case []byte:
		return string(t)
	case int, int8, int16, int32, int64, uint, uint8, uint16, uint32, uint64:
		return fmt.Sprintf("%d", t)
	case float32, float64:
		return fmt.Sprintf("%d", int64(t.(float64)))
	default:
		return fmt.Sprintf("%v", t)
	}
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
	authTokenUrl := fmt.Sprintf("%s/protocol/openid-connect/token", Config.OAuthUrl)
	if Config.AuthTokenUrl != "" {
		authTokenUrl = Config.AuthTokenUrl
	}

	// Provider is a struct in oidc package that represents
	// an OpenID Connect server's configuration.
	ctx := context.Background()
	provider, err := oidc.NewProvider(ctx, Config.OAuthUrl)
	if err != nil {
		panic(err)
	}

	// Configure an OpenID Connect aware OAuth2 client.
	oauth2Config := oauth2.Config{
		ClientID:     Config.ClientID,
		ClientSecret: Config.ClientSecret,
		RedirectURL:  redirectUrl,
		// Discovery returns the OAuth2 endpoints.
		Endpoint: provider.Endpoint(),
		// "openid" is a required scope for OpenID Connect flows.
		Scopes: []string{oidc.ScopeOpenID, "profile", "email"},
	}
	state := "somestate"
	oidcConfig := &oidc.Config{
		ClientID: Config.ClientID,
	}
	verifier := provider.Verifier(oidcConfig)

	// handling the callback authentication requests
	u := fmt.Sprintf("%s/server", Config.Base)
	http.HandleFunc(u, func(w http.ResponseWriter, r *http.Request) {
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
	})

	// handling the callback authentication requests
	u = fmt.Sprintf("%s/callback", Config.Base)
	http.HandleFunc(u, func(w http.ResponseWriter, r *http.Request) {
		sess := globalSessions.SessionStart(w, r)
		if Config.Verbose {
			msg := fmt.Sprintf("call from '/callback', r.URL %s, sess.path %v", r.URL, sess.Get("path"))
			printHTTPRequest(w, r, msg)
		}
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
		if Config.Verbose {
			fmt.Println("### oauth2Token", oauth2Token)
		}
		rawIDToken, ok := oauth2Token.Extra("id_token").(string)
		if !ok {
			http.Error(w, "No id_token field in oauth2 token.", http.StatusInternalServerError)
			return
		}
		if Config.Verbose {
			fmt.Println("### rawIDToken", rawIDToken)
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
		if Config.Verbose {
			fmt.Println("### session data", string(data))
			fmt.Println("### redirect to", urlPath)
		}
		http.Redirect(w, r, urlPath, http.StatusFound)
		return
	})

	// handling the clearance of user session
	u = fmt.Sprintf("%s/clear", Config.Base)
	http.HandleFunc(u, func(w http.ResponseWriter, r *http.Request) {
		sess := globalSessions.SessionStart(w, r)
		sess.Delete("userinfo")
		sess.Delete("rawIDToken")
		sess.Delete(state)
		globalSessions.SessionDestroy(w, r)
		msg := "User session is cleared"
		data := []byte(msg)
		w.Write(data)
		return
	})

	// handling the user request
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		sess := globalSessions.SessionStart(w, r)
		if Config.Verbose {
			msg := fmt.Sprintf("call from '/', r.URL %s, sess.Path %v", r.URL, sess.Get("path"))
			printHTTPRequest(w, r, msg)
		}
		oauthState := uuid.New().String()
		sess.Set(state, oauthState)
		if sess.Get("path") == nil || sess.Get("path") == "" {
			sess.Set("path", r.URL.Path)
		}
		// checking the userinfo in the session or if client provides valid access token.
		// if either is present we'll allow user request
		userInfo := sess.Get("userinfo")
		hasToken := checkAccessToken(authTokenUrl, r)
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
			setHeaders(userData, r)
			if r.URL.Path == fmt.Sprintf("%s/token", Config.Base) {
				msg := fmt.Sprintf("%s", sess.Get("rawIDToken"))
				if Config.Verbose {
					printJSON(r.Header, "### request headers")
				}
				data := []byte(msg)
				w.Write(data)
				return
			}
			for _, rec := range Config.Ingress {
				if strings.Contains(r.URL.Path, rec.Path) {
					if Config.Verbose {
						fmt.Println("ingress match", r.URL.Path, rec.Path, rec.ServiceUrl)
					}
					//                     url := fmt.Sprintf("%s/%s", rec.ServiceUrl, r.URL.Path)
					url := rec.ServiceUrl
					fmt.Println("### serveReverseProxy", url)
					serveReverseProxy(url, w, r)
					return
				}
			}
			if Config.TargetUrl == "" {
				msg := fmt.Sprintf("Hello %s", r.URL.Path)
				data := []byte(msg)
				w.Write(data)
			} else {
				serveReverseProxy(Config.TargetUrl, w, r)
			}
			return
		}
		// there is no proper authentication, redirect users to auth callback
		aurl := oauth2Config.AuthCodeURL(oauthState)
		if Config.Verbose {
			fmt.Println("### redirect", aurl)
		}
		http.Redirect(w, r, aurl, http.StatusFound)
		return
	})

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
			cricRecords := make(map[string]CricEntry)
			var err error
			for {
				interval := Config.UpdateCricInterval
				if interval == 0 {
					interval = 3600
				}
				// parse cric records
				if Config.CricUrl != "" {
					cricRecords, err = getCricData(Config.CricUrl)
					log.Printf("obtain CRIC records from %s, %v", Config.CricUrl, err)
				} else if Config.CricFile != "" {
					cricRecords, err = parseCric(Config.CricFile)
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
