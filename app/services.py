import os
import uuid
from pathlib import Path
from sqlalchemy.orm import Session
from fastapi import UploadFile
import aiofiles
from typing import List, Optional

from .models import User, File
from .schemas import EmailValidationRequest, FileMetadata

# Configuration
UPLOAD_DIR = "uploads"
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB limit

# Ensure upload directory exists
Path(UPLOAD_DIR).mkdir(exist_ok=True)

class UserService:
    @staticmethod
    def get_or_create_user(db: Session, email: str) -> User:
        """Get existing user or create new one"""
        user = db.query(User).filter(User.email == email).first()
        if not user:
            user = User(email=email, is_validated=True)
            db.add(user)
            db.commit()
            db.refresh(user)
        return user
    
    @staticmethod
    def get_user_by_email(db: Session, email: str) -> Optional[User]:
        """Get user by email"""
        return db.query(User).filter(User.email == email).first()

class FileService:
    @staticmethod
    async def save_file(upload_file: UploadFile, user: User, db: Session) -> File:
        """Save uploaded file to disk and create database record"""
        
        # Validate file size
        content = await upload_file.read()
        if len(content) > MAX_FILE_SIZE:
            raise ValueError(f"File size exceeds maximum limit of {MAX_FILE_SIZE // (1024*1024)}MB")
        
        # Generate unique filename
        file_extension = Path(upload_file.filename).suffix
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        file_path = Path(UPLOAD_DIR) / unique_filename
        
        # Save file to disk
        async with aiofiles.open(file_path, 'wb') as f:
            await f.write(content)
        
        # Create database record
        db_file = File(
            filename=unique_filename,
            original_filename=upload_file.filename,
            file_path=str(file_path),
            file_size=len(content),
            content_type=upload_file.content_type,
            user_id=user.id
        )
        
        db.add(db_file)
        db.commit()
        db.refresh(db_file)
        
        return db_file
    
    @staticmethod
    def get_user_files(db: Session, email: str) -> List[File]:
        """Get all files for a user"""
        user = UserService.get_user_by_email(db, email)
        if not user:
            return []
        
        return db.query(File).filter(File.user_id == user.id).order_by(File.uploaded_at.desc()).all()
    
    # @staticmethod
    # def delete_file(db: Session, file_id: int, user_email: str) -> bool:
    #     """Delete a file (both from disk and database)"""
    #     user = UserService.get_user_by_email(db, user_email)
    #     if not user:
    #         return False
    #     
    #     file_record = db.query(File).filter(
    #         File.id == file_id, 
    #         File.user_id == user.id
    #     ).first()
    #     
    #     if not file_record:
    #         return False
    #     
    #     # Delete from disk
    #     try:
    #         os.remove(file_record.file_path)
    #     except FileNotFoundError:
    #         pass  # File already deleted from disk
    #     
    #     # Delete from database
    #     db.delete(file_record)
    #     db.commit()
    #     
    #     return True 