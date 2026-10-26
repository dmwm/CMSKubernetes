# htdocs

Static HTML served at the root of `cmsweb.cern.ch` (e.g. `index.html` is the CMSWEB landing page, `help.html` is the Help and Support page). CSS lives in `css/`, images in `img/`.

## Previewing locally

The pages use absolute paths (`/css/cmsweb.css`, `/img/title.gif`, `/favicon.ico`), so opening a file directly (e.g. via `file://` or double-clicking) won't load the CSS/images correctly — those paths need to resolve from a server root.

Serve this directory over a local HTTP server instead:

```bash
cd docker/htdocs/htdocs
python3 -m http.server 8000
```

Then open `http://localhost:8000/help.html` (or `index.html`) in a browser. `Ctrl+C` stops the server.

## Building and deploying

Editing the HTML files alone doesn't change what's live on `cmsweb.cern.ch`. The `docker/htdocs/` directory has to be rebuilt into the `registry.cern.ch/cmsweb/htdocs` image and pushed (manual, no CI). The new tag is then rolled out by updating it in the auth-proxy-server Helm values on the `aps` branch (test7 first); ArgoCD deploys it automatically.

For the full steps, see [Building and deploying the change](https://cms-http-group.docs.cern.ch/git_repositories/cmskubernetes/#building-and-deploying-the-change).
