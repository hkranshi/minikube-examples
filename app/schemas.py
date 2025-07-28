from pydantic import BaseModel, EmailStr, validator
from datetime import datetime
from typing import List, Optional

class EmailValidationRequest(BaseModel):
    email: EmailStr
    
    @validator('email')
    def validate_gmail(cls, v):
        if not v.endswith('@gmail.com'):
            raise ValueError('Only Gmail addresses are allowed')
        return v

class EmailValidationResponse(BaseModel):
    email: str
    is_valid: bool
    message: str

class FileUploadResponse(BaseModel):
    id: int
    filename: str
    original_filename: str
    file_size: int
    content_type: Optional[str]
    uploaded_at: datetime
    message: str
    
    class Config:
        from_attributes = True

class FileMetadata(BaseModel):
    id: int
    filename: str
    original_filename: str
    file_size: int
    content_type: Optional[str]
    uploaded_at: datetime
    
    class Config:
        from_attributes = True

class UserFilesResponse(BaseModel):
    email: str
    total_files: int
    files: List[FileMetadata]
    
class ErrorResponse(BaseModel):
    error: str
    detail: Optional[str] = None 