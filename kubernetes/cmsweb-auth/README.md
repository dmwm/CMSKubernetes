This area is a clone of [cmsweb](../cmsweb) except ingress controllers.
It provides a new reverse proxy with CERN SSO OAuth2 OICD authentication
mechanism for cmsweb. Therefore, to setup cmsweb cluster we don't need
apache frontends (and frontend cluster), instead we can deploy
[auth-proxy-server](https://github.com/dmwm/CMSKubernetes/blob/master/docker/auth-proxy-server/proxy_auth_server.go)
and use it for authentication of all CMS users.

### auth-proxy-server
The new auth-proxy-server is a new reverse proxy with CERN SSO OAuth2 OICD
authentication. This server should be configured at
[CERN application portal](https://application-portal.web.cern.ch/)
has the following config upon start-up:
```
{
    "base": "",
    "client_id": "cms-go",
    "client_secret": "SECRET"
    "oauth_url": "https://auth.cern.ch/auth/realms/cern",
    "server_cert": "/path/tls.crt",
    "server_key": "/path/tls.key",
    "redirect_url": "https://xxx.cern.ch/callback",
    "hmac": "/path/hmac",
    "cric_file": "/path/cric.json",
    "update_cric": 60,
    "ingress": [ {"path":"/bla", "service_url":"URL"}, ... ],
    "verbose": true,
    "port": 8181
}
```
The ingrss entries can point to existing cmsweb services using
k8s cluster urls, e.g. `http://httpgo.http.svc.cluster.local:PORT`.
