from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.request import Request, urlopen
from urllib.error import HTTPError

# Our gateway is a small Python HTTP server that acts as a reverse proxy / forwarding service between Mirth and Spring Boot.
# It has one simple job:
# Receive an HTTP request from Mirth and forward it to Spring Boot, then return Spring Boot's HTTP response to Mirth.
BACKEND = "http://ocre-hrm-lab-ocre-api-1:8080"

class Gateway(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/api/reports":
            self.send_error(404)
            return

        length = int(self.headers.get("Content-Length", "0"))
        body = self.rfile.read(length)

        req = Request(
            BACKEND + self.path,
            data=body,
            headers={"Content-Type": "application/json"},
            method="POST"
        )

        try:
            with urlopen(req, timeout=10) as response:
                status = response.status
                result = response.read()
        except HTTPError as e:
            status = e.code
            result = e.read()
        except Exception as e:
            self.send_error(502, str(e))
            return

        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(result)))
        self.end_headers()
        self.wfile.write(result)

print("OCRE test gateway listening on port 8090", flush=True)
ThreadingHTTPServer(("0.0.0.0", 8090), Gateway).serve_forever()
