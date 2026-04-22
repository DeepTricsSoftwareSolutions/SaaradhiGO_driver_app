#!/usr/bin/env python3
"""
Mock Backend Server for SaaradhiGO Driver App
Provides API endpoints for development without needing Node.js + Docker + PostgreSQL
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json
import os
import sys

PORT = 8000

# Mock data storage
MOCK_DATA = {
    'drivers': {},
    'rides': {},
    'earnings': {},
    'otps': {},  # phone -> otp
    'payouts': [],  # withdrawal requests
}

class BackendHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        try:
            # Get driver profile
            if path == '/driver/profile/':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                response = {
                    'success': True,
                    'data': {
                        'id': 'DRV123',
                        'name': 'Demo Driver',
                        'phone': '6309736924',
                        'email': 'driver@example.com',
                        'rating': 4.8,
                        'total_rides': 342,
                        'vehicle': {
                            'type': 'Sedan',
                            'number': 'KA01AB1234',
                            'color': 'White'
                        }
                    }
                }
                self.wfile.write(json.dumps(response).encode())
                
            # Get earnings
            elif path == '/driver/earnings/':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                response = {
                    'success': True,
                    'data': {
                        'total_earnings': 5420.50,
                        'today_earnings': 450.00,
                        'this_week_earnings': 2150.00,
                        'this_month_earnings': 8900.00,
                        'total_rides': 342,
                        'today_rides': 5,
                        'rating': 4.8
                    }
                }
                self.wfile.write(json.dumps(response).encode())
                
            # Get ride history
            elif path == '/driver/rides/':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                response = {
                    'success': True,
                    'data': [
                        {
                            'id': 'RIDE001',
                            'date': '2026-04-20',
                            'time': '14:30',
                            'pickup': 'MG Road, Bangalore',
                            'dropoff': 'Indiranagar, Bangalore',
                            'distance': 8.5,
                            'fare': 250.00,
                            'rating': 5,
                            'passenger': 'John Doe',
                            'status': 'completed'
                        },
                        {
                            'id': 'RIDE002',
                            'date': '2026-04-19',
                            'time': '18:45',
                            'pickup': 'Whitefield, Bangalore',
                            'dropoff': 'Koramangala, Bangalore',
                            'distance': 12.3,
                            'fare': 380.00,
                            'rating': 4,
                            'passenger': 'Jane Smith',
                            'status': 'completed'
                        }
                    ]
                }
                self.wfile.write(json.dumps(response).encode())
                
            # Get wallet
            elif path == '/driver/wallet/':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                response = {
                    'success': True,
                    'data': {
                        'balance': 2500.00,
                        'transactions': [
                            {'date': '2026-04-20', 'amount': 450.00, 'type': 'credit', 'description': 'Ride earnings'},
                            {'date': '2026-04-19', 'amount': -500.00, 'type': 'debit', 'description': 'Withdrawal'},
                        ]
                    }
                }
                self.wfile.write(json.dumps(response).encode())
                
            else:
                self.send_response(404)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Not found'}).encode())
                
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def do_POST(self):
        """Handle POST requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode()
        
        try:
            data = json.loads(body) if body else {}
        except:
            data = {}

        try:
            # Send OTP
            if path == '/auth/send-otp':
                phone = data.get('phone', '')
                otp = '123456'  # Demo OTP
                MOCK_DATA['otps'][phone] = otp
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                response = {
                    'success': True,
                    'message': f'OTP sent to {phone}',
                    'dev_otp': otp  # For testing
                }
                self.wfile.write(json.dumps(response).encode())
                
            # Verify OTP
            elif path == '/auth/verify-otp':
                phone = data.get('phone', '')
                otp = data.get('otp', '')
                correct_otp = MOCK_DATA['otps'].get(phone, '')
                
                if otp == correct_otp or otp == '123456':  # Accept dev OTP
                    self.send_response(200)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    response = {
                        'success': True,
                        'token': 'mock_jwt_token_abc123xyz',
                        'driver': {
                            'id': 'DRV123',
                            'phone': phone,
                            'name': 'Demo Driver',
                            'rating': 4.8
                        }
                    }
                    self.wfile.write(json.dumps(response).encode())
                else:
                    self.send_response(401)
                    self.send_header('Content-Type', 'application/json')
                    self.end_headers()
                    self.wfile.write(json.dumps({'success': False, 'error': 'Invalid OTP'}).encode())
                    
            # Start ride
            elif path == '/ride/start':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                response = {
                    'success': True,
                    'ride_id': 'RIDE123',
                    'passenger': {'name': 'John Doe', 'rating': 4.9}
                }
                self.wfile.write(json.dumps(response).encode())
                
            # End ride
            elif path == '/ride/end':
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                response = {
                    'success': True,
                    'fare': 250.00,
                    'distance': 8.5,
                    'duration': 18
                }
                self.wfile.write(json.dumps(response).encode())
                
            # Request withdrawal/payout
            elif path == '/payments/refund/':
                amount = float(data.get('amount', 0))
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                response = {
                    'success': True,
                    'message': f'Withdrawal request for ₹{amount} submitted successfully',
                    'transaction_id': f'WD{len(MOCK_DATA["payouts"]) + 1:04d}',
                    'estimated_settlement': '2-3 business days'
                }
                # Add to payout history
                MOCK_DATA['payouts'].append({
                    'id': response['transaction_id'],
                    'amount': amount,
                    'date': '2026-04-20',
                    'status': 'pending'
                })
                self.wfile.write(json.dumps(response).encode())
                
            # Fallback
            else:
                self.send_response(404)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': 'Not found'}).encode())
                
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'error': str(e)}).encode())

    def do_OPTIONS(self):
        """Handle CORS preflight"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def end_headers(self):
        """Add CORS headers to all responses"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

    def log_message(self, format, *args):
        """Custom logging"""
        print(f"[API] {format % args}")


if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', PORT), BackendHandler)
    print(f"""
╔══════════════════════════════════════════════════════════════╗
║     🚀 SaaradhiGO Mock Backend Server (Python)              ║
╠══════════════════════════════════════════════════════════════╣
║ Running on: http://0.0.0.0:{PORT}                               ║
║ Local:      http://127.0.0.1:{PORT}                             ║
║ Network:    http://<your_ip>:{PORT}                           ║
║                                                              ║
║ Available Endpoints:                                        ║
║ - POST   /auth/send-otp                                     ║
║ - POST   /auth/verify-otp                                   ║
║ - GET    /driver/earnings/                                  ║
║ - GET    /driver/rides/                                     ║
║ - GET    /driver/wallet/                                    ║
║ - POST   /ride/start                                        ║
║ - POST   /ride/end                                          ║
║ - POST   /payments/refund/                                  ║
║                                                              ║
║ Press Ctrl+C to stop                                        ║
╚══════════════════════════════════════════════════════════════╝
""")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[Server] Shutting down...")
        server.shutdown()
