from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List
import re

from .database import get_db
from .schemas import (
    EmailValidationRequest, 
    EmailValidationResponse, 
    FileUploadResponse, 
    UserFilesResponse,
    FileMetadata,
    ErrorResponse
)
from .services import UserService, FileService

router = APIRouter()

def validate_gmail_format(email: str) -> bool:
    """Validate Gmail format using regex"""
    gmail_pattern = r'^[a-zA-Z0-9._%+-]+@gmail\.com$'
    return re.match(gmail_pattern, email) is not None

@router.post("/validate-email", response_model=EmailValidationResponse)
async def validate_email(request: EmailValidationRequest, db: Session = Depends(get_db)):
    """
    Validate if the provided email is a valid Gmail address
    """
    try:
        email = request.email.lower()
        
        # Additional validation beyond Pydantic
        if not validate_gmail_format(email):
            return EmailValidationResponse(
                email=email,
                is_valid=False,
                message="Invalid Gmail format"
            )
        
        # Get or create user in database
        user = UserService.get_or_create_user(db, email)
        
        return EmailValidationResponse(
            email=email,
            is_valid=True,
            message="Valid Gmail address"
        )
    
    except ValueError as e:
        return EmailValidationResponse(
            email=request.email,
            is_valid=False,
            message=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.post("/upload-file", response_model=FileUploadResponse)
async def upload_file(
    file: UploadFile = File(...),
    email: str = Form(...),
    db: Session = Depends(get_db)
):
    """
    Upload a file for a validated Gmail user
    """
    try:
        # Validate email format
        email = email.lower().strip()
        if not validate_gmail_format(email):
            raise HTTPException(status_code=400, detail="Invalid Gmail format")
        
        # Check if user exists (should be validated first)
        user = UserService.get_user_by_email(db, email)
        if not user:
            raise HTTPException(
                status_code=400, 
                detail="Email not validated. Please validate email first."
            )
        
        # Validate file
        if not file.filename:
            raise HTTPException(status_code=400, detail="No file provided")
        
        # Save file
        saved_file = await FileService.save_file(file, user, db)
        
        return FileUploadResponse(
            id=saved_file.id,
            filename=saved_file.filename,
            original_filename=saved_file.original_filename,
            file_size=saved_file.file_size,
            content_type=saved_file.content_type,
            uploaded_at=saved_file.uploaded_at,
            message="File uploaded successfully"
        )
    
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/files/{gmail}", response_model=UserFilesResponse)
async def get_user_files(gmail: str, db: Session = Depends(get_db)):
    """
    Get all files metadata for a specific Gmail user
    """
    try:
        email = gmail.lower().strip()
        
        # Validate email format
        if not validate_gmail_format(email):
            raise HTTPException(status_code=400, detail="Invalid Gmail format")
        
        # Get user files
        files = FileService.get_user_files(db, email)
        
        # Convert to response format
        file_metadata = [
            FileMetadata(
                id=f.id,
                filename=f.filename,
                original_filename=f.original_filename,
                file_size=f.file_size,
                content_type=f.content_type,
                uploaded_at=f.uploaded_at
            )
            for f in files
        ]
        
        return UserFilesResponse(
            email=email,
            total_files=len(file_metadata),
            files=file_metadata
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.delete("/files/{file_id}")
async def delete_file(file_id: int, email: str = Form(...), db: Session = Depends(get_db)):
    """
    Delete a specific file for a user
    """
    try:
        email = email.lower().strip()
        
        # Validate email format
        if not validate_gmail_format(email):
            raise HTTPException(status_code=400, detail="Invalid Gmail format")
        
        # Delete file
        success = FileService.delete_file(db, file_id, email)
        
        if not success:
            raise HTTPException(status_code=404, detail="File not found or access denied")
        
        return {"message": "File deleted successfully"}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}") 