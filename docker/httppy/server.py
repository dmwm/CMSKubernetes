#!/usr/bin/env python

import time
import cherrypy

class HelloWorld(object):
    @cherrypy.expose
    def index(self):
        out = "CherryPy response headesr"
        headers = cherrypy.response.headers
        for hdr in cherrypy.response.headers:
            out += "\n" + hdr
        out += "CherryPy request headesr"
        for hdr in cherrypy.request.headers:
            out += "\n" + hdr
        return "Hello from CherryPy\n"+out
    @cherrypy.expose
    def healthz(self):
        return "ok"

def application(environ, start_response):
    cherrypy.tree.mount(HelloWorld(), '/', None)
    return cherrypy.tree(environ, start_response)

if __name__ == '__main__':
#     cherrypy.config.update({'server.thread_pool': 2, 'server.socket_timeout': 0})
    cherrypy.quickstart(HelloWorld())
