"""
cors_proxy.py
-------------
Tiny pass-through HTTP proxy that adds Access-Control-Allow-* headers to every
response from ORDS. Solves the dashboard's CORS issue without touching ORDS.

Usage:
    python cors_proxy.py
    -> listens on http://localhost:8182, proxies to http://localhost:8181

Then in 4_WEB_Model/index.html, change the ORDS base URL to:
    http://localhost:8182/ords/fdbo/realestate/v1
"""
import http.server
import urllib.request
import urllib.error

UPSTREAM = "http://localhost:8181"
LISTEN_PORT = 8182


class Handler(http.server.BaseHTTPRequestHandler):
    def _proxy(self, method):
        try:
            req = urllib.request.Request(UPSTREAM + self.path, method=method)
            for k, v in self.headers.items():
                if k.lower() not in ("host", "origin"):
                    req.add_header(k, v)
            body = None
            length = self.headers.get("Content-Length")
            if length:
                body = self.rfile.read(int(length))
            with urllib.request.urlopen(req, data=body, timeout=120) as r:
                payload = r.read()
                self.send_response(r.status)
                for k, v in r.getheaders():
                    if k.lower() not in ("transfer-encoding", "connection",
                                         "access-control-allow-origin"):
                        self.send_header(k, v)
                self.send_header("Access-Control-Allow-Origin", "*")
                self.send_header("Access-Control-Allow-Methods",
                                 "GET, POST, PUT, DELETE, OPTIONS")
                self.send_header("Access-Control-Allow-Headers", "*")
                self.end_headers()
                self.wfile.write(payload)
        except urllib.error.HTTPError as e:
            self.send_response(e.code)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(e.read())
        except Exception as e:
            self.send_response(502)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(f"proxy error: {e}".encode())

    def do_GET(self):     self._proxy("GET")
    def do_POST(self):    self._proxy("POST")
    def do_PUT(self):     self._proxy("PUT")
    def do_DELETE(self):  self._proxy("DELETE")

    def do_OPTIONS(self):
        # Browser CORS preflight
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods",
                         "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Access-Control-Max-Age", "3600")
        self.end_headers()

    def log_message(self, fmt, *args):
        # Quiet: only log errors to stderr
        pass


if __name__ == "__main__":
    print(f"CORS proxy: http://localhost:{LISTEN_PORT}  ->  {UPSTREAM}")
    http.server.ThreadingHTTPServer(("0.0.0.0", LISTEN_PORT), Handler).serve_forever()
