#!/usr/bin/env python3

import os
import time
import cherrypy

class Main(object):
    @cherrypy.expose
    def index(self):
        out = "CherryPy response headesr"
        if cherrypy.response and cherrypy.response.headers:
            for hdr in cherrypy.response.headers:
                out += "\n" + hdr
            out += "CherryPy request headesr"
        if cherrypy.request and cherrypy.request.headers:
            for hdr in cherrypy.request.headers:
                out += "\n" + hdr
        return "Hello from CherryPy\n"+out
    @cherrypy.expose
    def healthz(self):
        return "ok"

if __name__ == '__main__':
    cherrypy.config.update({
        'server.thread_pool': 20,
        'server.socket_host': '0.0.0.0'
    })
#     cherrypy.quickstart(Main())
    cherrypy.tree.mount(Main(), '/httppy')
    if hasattr(cherrypy.engine, 'block'):
        # 3.1 syntax
        cherrypy.engine.start()
        cherrypy.engine.block()
    else:
        # 3.0 syntax
        cherrypy.server.quickstart()
        cherrypy.engine.start()
