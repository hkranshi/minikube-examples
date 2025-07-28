from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
import requests
import os
from werkzeug.utils import secure_filename
import threading
import webbrowser
import time

app = Flask(__name__)
app.secret_key = 'your-secret-key-change-in-production'

# Backend API configuration
# Use environment variable for flexibility, default to Kubernetes service name
BACKEND_URL = os.getenv('BACKEND_URL', 'http://backend-service:8000/api/v1')

# Configure upload folder
UPLOAD_FOLDER = 'uploads'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def make_api_request(method, endpoint, data=None, files=None):
    """Helper function to make requests to FastAPI backend"""
    url = f"{BACKEND_URL}{endpoint}"
    try:
        if method == 'GET':
            response = requests.get(url)
        elif method == 'POST':
            if files:
                response = requests.post(url, data=data, files=files)
            else:
                response = requests.post(url, json=data)
        elif method == 'DELETE':
            response = requests.delete(url, data=data)
        
        return response
    except requests.exceptions.ConnectionError:
        return None

@app.route('/')
def index():
    """Home page - email validation"""
    return render_template('index.html')

@app.route('/validate-email', methods=['POST'])
def validate_email():
    """Validate Gmail address"""
    email = request.form.get('email', '').strip().lower()
    
    if not email:
        flash('Please enter an email address', 'error')
        return redirect(url_for('index'))
    
    if not email.endswith('@gmail.com'):
        flash('Only Gmail addresses are allowed', 'error')
        return redirect(url_for('index'))
    
    # Call backend API
    response = make_api_request('POST', '/validate-email', {'email': email})
    
    if response is None:
        flash('Backend server is not running. Please start the FastAPI server.', 'error')
        return redirect(url_for('index'))
    
    if response.status_code == 200:
        return redirect(url_for('dashboard', email=email))
    else:
        try:
            error_data = response.json()
            flash(f"Validation failed: {error_data.get('detail', 'Unknown error')}", 'error')
        except:
            flash('Email validation failed', 'error')
        return redirect(url_for('index'))

@app.route('/dashboard/<email>')
def dashboard(email):
    """Main dashboard for file upload and management"""
    # Get user files
    response = make_api_request('GET', f'/files/{email}')
    
    files = []
    if response and response.status_code == 200:
        data = response.json()
        files = data.get('files', [])
    
    return render_template('dashboard.html', email=email, files=files)

@app.route('/upload-file/<email>', methods=['POST'])
def upload_file(email):
    """Handle file upload"""
    if 'file' not in request.files:
        flash('No file selected', 'error')
        return redirect(url_for('dashboard', email=email))
    
    file = request.files['file']
    if file.filename == '':
        flash('No file selected', 'error')
        return redirect(url_for('dashboard', email=email))
    
    # Prepare file for API
    files = {'file': (file.filename, file.read(), file.content_type)}
    data = {'email': email}
    
    # Call backend API
    response = make_api_request('POST', '/upload-file', data=data, files=files)
    
    if response and response.status_code == 200:
        flash('File uploaded successfully!', 'success')
    else:
        try:
            error_data = response.json()
            flash(f"Upload failed: {error_data.get('detail', 'Unknown error')}", 'error')
        except:
            flash('File upload failed', 'error')
    
    return redirect(url_for('dashboard', email=email))

# @app.route('/delete-file/<email>/<int:file_id>', methods=['POST'])
# def delete_file(email, file_id):
#     """Delete a file"""
#     data = {'email': email}
#     
#     # Call backend API
#     response = make_api_request('DELETE', f'/files/{file_id}', data=data)
#     
#     if response and response.status_code == 200:
#         flash('File deleted successfully!', 'success')
#     else:
#         try:
#             error_data = response.json()
#             flash(f"Delete failed: {error_data.get('detail', 'Unknown error')}", 'error')
#         except:
#             flash('File deletion failed', 'error')
#     
#     return redirect(url_for('dashboard', email=email))

@app.route('/health')
def health():
    """Health check endpoint"""
    # Check backend health
    response = make_api_request('GET', '/../health')  # Backend health endpoint
    
    if response and response.status_code == 200:
        return jsonify({
            'status': 'healthy',
            'frontend': 'Flask',
            'backend': 'connected'
        })
    else:
        return jsonify({
            'status': 'error',
            'frontend': 'Flask',
            'backend': 'disconnected'
        }), 503

def format_file_size(bytes):
    """Helper function to format file size"""
    if bytes == 0:
        return "0 Bytes"
    k = 1024
    sizes = ["Bytes", "KB", "MB", "GB"]
    i = int(len(str(bytes)) // 4) if bytes > 0 else 0
    if i >= len(sizes):
        i = len(sizes) - 1
    return f"{round(bytes / (k ** i), 2)} {sizes[i]}"

def format_date(date_string):
    """Helper function to format date"""
    from datetime import datetime
    try:
        date = datetime.fromisoformat(date_string.replace('Z', '+00:00'))
        return date.strftime('%Y-%m-%d %H:%M')
    except:
        return date_string

# Make helper functions available in templates
app.jinja_env.globals.update(format_file_size=format_file_size)
app.jinja_env.globals.update(format_date=format_date)

if __name__ == '__main__':
    # Ensure uploads directory exists
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)

    def open_browser():
        time.sleep(1)  # Wait a moment for the server to start
        webbrowser.open('http://localhost:5001')

    threading.Thread(target=open_browser, daemon=True).start()

    print("🐍 Flask Frontend Server Starting...")
    print("📧 Gmail File Upload - Python Frontend")
    print("🌐 Visit: http://localhost:5001")
    print("⚠️  Make sure FastAPI backend is running on http://localhost:8000")
    
    app.run(debug=True, host='0.0.0.0', port=5001) 