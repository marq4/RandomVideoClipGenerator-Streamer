""" Simple HTTP server with CORS support. """

from http.server import HTTPServer, SimpleHTTPRequestHandler


class CORSRequestHandler(SimpleHTTPRequestHandler):
    """ Allows requests from any origin """
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

if __name__ == '__main__':
    HTTPServer(('0.0.0.0', 8080), CORSRequestHandler).serve_forever()
