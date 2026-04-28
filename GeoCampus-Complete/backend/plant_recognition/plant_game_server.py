#!/usr/bin/env python3
import os
import json
import socket
import socketserver
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler

from plantnet_client import PlantNetRecognizer

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(BASE_DIR, 'uploads')

recognizer = PlantNetRecognizer()


def get_ip_address():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        return s.getsockname()[0]
    finally:
        s.close()


class PlantRequestHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        if self.path not in ('/', '/upload'):
            self.send_response(404)
            self.send_header('Content-Type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'Not Found')
            return
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        html = f"""
        <html>
        <head><title>Plant Game Server</title></head>
        <body style="background:#121212;color:#E0E0E0;font-family:Arial,sans-serif;">
          <h1>Plant Game Server</h1>
          <p>Upload endpoint: <strong>/upload</strong></p>
          <p>Server is running on <strong>{get_ip_address()}:8888</strong></p>
        </body>
        </html>
        """
        self.wfile.write(html.encode('utf-8'))

    def do_POST(self):
        if self.path != '/upload':
            self.send_response(404)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Connection', 'close')
            self.end_headers()
            self.wfile.write(json.dumps({'success': False, 'match': False, 'message': 'Not Found'}).encode('utf-8'))
            return

        content_length = int(self.headers.get('Content-Length', 0))
        file_type = self.headers.get('X-File-Type', 'Plant')
        raw_data = self.rfile.read(content_length)

        os.makedirs(UPLOAD_DIR, exist_ok=True)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        file_name = f'plant_{timestamp}.jpg'
        file_path = os.path.join(UPLOAD_DIR, file_name)

        with open(file_path, 'wb') as f:
            f.write(raw_data)

        print(f'📥 Received {file_type} upload: {file_path}')

        try:
            result = recognizer.recognize(file_path)
        except Exception as e:
            result = {
                'plant': None,
                'match': False,
                'confidence': 0.0,
                'message': f'Recognition error: {e}',
                'scores': {'overall': 0.0, 'hist': 0.0, 'orb': 0.0},
            }

        try:
            plant = result.get('plant')
            conf = result.get('confidence')
            scores = result.get('scores')
            print(f'🔎 Result: match={result.get("match")} plant={plant} confidence={conf} scores={scores}')
        except Exception:
            pass
        response = {
            'success': result['match'],
            'plant': result.get('plant'),
            'match': result['match'],
            'confidence': result['confidence'],
            'message': result.get('message'),
            'scores': result.get('scores'),
            'uploaded_file': file_name,
        }

        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Connection', 'close')
        self.end_headers()
        self.wfile.write(json.dumps(response).encode('utf-8'))


class ThreadedHTTPServer(socketserver.ThreadingMixIn, HTTPServer):
    daemon_threads = True


if __name__ == '__main__':
    ip_address = get_ip_address()
    print('============================================')
    print('  Plant Game Recognition Server')
    print('============================================')
    print(f'  Listening on http://{ip_address}:8888')
    print(f'  Upload folder: {UPLOAD_DIR}')
    print('  Add reference plant images to plant_recognition/smartlock_server/plant_reference/')
    print('============================================')

    ThreadedHTTPServer(('0.0.0.0', 8888), PlantRequestHandler).serve_forever()
