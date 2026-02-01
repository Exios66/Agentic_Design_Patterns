#!/usr/bin/env python3
"""
Custom HTTP server for gitmal output with proper MIME type handling.
Handles files without extensions and special characters properly.
"""
import http.server
import socketserver
import mimetypes
import os
import sys

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Add CORS headers for better compatibility
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        super().end_headers()
    
    def guess_type(self, path):
        # Handle files without extensions
        mimetype, encoding = mimetypes.guess_type(path)
        if mimetype is None:
            # Get the full path relative to current directory
            full_path = path.lstrip('/')
            if os.path.exists(full_path) and os.path.isfile(full_path):
                try:
                    with open(full_path, 'rb') as f:
                        content = f.read(100)
                        # Check for JSON-like content (notebooks, JSON files)
                        if content.startswith(b'{') or content.startswith(b'['):
                            return 'application/json', encoding
                        # Check for HTML-like content
                        if content.startswith(b'<'):
                            return 'text/html', encoding
                except:
                    pass
            # Default to text/plain for unknown types
            return 'text/plain', encoding
        return mimetype, encoding
    
    def log_message(self, format, *args):
        # Suppress verbose logging
        pass

if __name__ == "__main__":
    PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    DIRECTORY = sys.argv[2] if len(sys.argv) > 2 else "."
    
    # Change to the output directory
    os.chdir(DIRECTORY)
    
    with socketserver.TCPServer(("", PORT), CustomHTTPRequestHandler) as httpd:
        httpd.serve_forever()
