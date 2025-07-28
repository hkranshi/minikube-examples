# Gmail File Upload System

A **Python-only** file upload system with Gmail validation. Built with **FastAPI backend** and **Flask frontend**.

## 🚀 Features

- **📧 Gmail Only**: Strict `@gmail.com` validation
- **📁 File Upload**: Up to 10MB per file
- **🗃️ Database**: SQLite storage with metadata
- **🌐 Web Interface**: Simple Flask frontend
- **🐍 Python Only**: No JavaScript required

## 🛠️ Quick Start

### 1. Setup
```bash

python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
pip install -r requirements_flask.txt
```

### 3. Start Backend (Terminal 1)
```bash
source venv/bin/activate
python main.py
```
**Backend:** `http://localhost:8000`

### 4. Start Frontend (Terminal 2)
```bash
cd frontend_flask
source ../venv/bin/activate
python app.py
```
**Frontend:** `http://localhost:5001`

### 5. Use the System
1. Visit [http://localhost:5001](http://localhost:5001)
2. Enter your Gmail address
3. Upload and manage files

## 📚 API Endpoints

**Base URL:** `http://localhost:8000/api/v1`

### Validate Email
```http
POST /validate-email
{"email": "user@gmail.com"}
```

### Upload File
```http
POST /upload-file
Form: file + email
```

### Get Files
```http
GET /files/{gmail}
```

### Delete File
```http
DELETE /files/{file_id}
Form: email
```

## 📁 Project Structure

```
├── main.py                    # FastAPI backend
├── app/                       # Backend modules
├── frontend_flask/
│   ├── app.py                 # Flask frontend
│   └── templates/             # HTML templates
├── requirements.txt           # Backend deps
└── requirements_flask.txt     # Frontend deps
```

## 🔧 Configuration

**Backend Settings:**
- Port: 8000
- Database: SQLite (`gmail_files.db`)
- File limit: 10MB
- Storage: `uploads/` directory

**Frontend Settings:**
- Port: 5001
- Backend API: `http://localhost:8000/api/v1`

## 🔄 How It Works

### System Architecture
```
User Browser → Flask Frontend → FastAPI Backend → SQLite Database
                     ↓              ↓              ↓
              HTML Templates    REST APIs     File Storage
```

### User Flow
1. **Email Validation**
   - User enters Gmail address in Flask frontend
   - Frontend sends POST to `/validate-email` API
   - Backend validates `@gmail.com` format
   - User record created in database
   - Redirects to dashboard on success

2. **File Upload**
   - User selects file in dashboard (max 10MB)
   - Frontend sends multipart form to `/upload-file` API
   - Backend saves file with UUID name in `uploads/`
   - File metadata stored in database
   - Success message shown to user

3. **File Management**
   - Dashboard loads user files from `/files/{email}` API
   - Backend queries database for user's files
   - Frontend displays file grid with delete options
   - Users can delete files via `/files/{file_id}` API

### Technical Flow
```
Frontend (Flask)     Backend (FastAPI)      Database (SQLite)
├── Email form  →    ├── Validate email →   ├── Create user
├── File upload →    ├── Save file     →   ├── Store metadata  
├── Dashboard   →    ├── Get files     →   ├── Query files
└── Delete file →    └── Remove file   →   └── Delete record
```

### Data Storage
- **Users Table**: `id`, `email`, `created_at`
- **Files Table**: `id`, `filename`, `original_filename`, `file_size`, `file_path`, `user_id`
- **File System**: Actual files stored in `uploads/` with UUID names

## 🐛 Common Issues

**Port conflicts:**
```bash
# Check ports
lsof -i :8000
lsof -i :5001

# Kill if needed
kill -9 $(lsof -t -i:8000)
```

**Dependencies missing:**
```bash
pip install -r requirements.txt
pip install -r requirements_flask.txt
```

**Backend not connecting:**
```bash
curl http://localhost:8000/health
```



