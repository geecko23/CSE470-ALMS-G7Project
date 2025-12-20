from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import Optional
import mysql.connector
import os


UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_methods=["*"],
    allow_headers=["*"],
)

# MODELS
class User(BaseModel):
    user_id: str
    name: str
    email: str
    password: str

class LoginUser(BaseModel):
    email: str
    password: str

def json_error(message: str, code: int = 400):
    return JSONResponse(content={"success": False, "error": message}, status_code=code)

# REGISTER 
@app.post("/register")
def register(user: User):
    db = None
    cursor = None
    try:
        db = mysql.connector.connect(
            host="localhost", user="root", password="123", database="project"
        )
        cursor = db.cursor()
        cursor.execute(
            "INSERT INTO users (user_id, name, email, password) VALUES (%s, %s, %s, %s)",
            (user.user_id, user.name, user.email, user.password)
        )
        db.commit()
        return {"success": True, "message": "Registration successful"}
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        if cursor: cursor.close()
        if db: db.close()

# LOGIN
@app.post("/login")
def login(user: LoginUser):
    db = None
    cursor = None
    db_user: Optional[dict] = None
    try:
        db = mysql.connector.connect(
            host="localhost", user="root", password="123", database="project"
        )
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT * FROM users WHERE email=%s", (user.email,))
        db_user = cursor.fetchone()

        if db_user is None:
            return {"success": False, "message": "User not found"}
        if user.password != db_user["password"]:
            return {"success": False, "message": "Incorrect password"}

        return {
            "success": True,
            "message": "Login successful",
            "user": {
                "user_id": db_user["user_id"],
                "name": db_user["name"],
                "email": db_user["email"]
            }
        }
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        if cursor: cursor.close()
        if db: db.close()

#Upload note
@app.post("/api/notes/upload")
async def upload_note(
    title: str = Form(...),
    description: str = Form(""),
    course: str = Form(...),
    uploader_id: str = Form(...),
    file: UploadFile = File(...)
):
    db = None
    cursor = None
    try:
        allowed_courses = ["CSE", "MAT", "PHY"]
        if not any(x in course.upper() for x in allowed_courses):
            return json_error("Invalid course code")


        file_path = os.path.join(UPLOAD_DIR, file.filename)
        with open(file_path, "wb") as f:
            while chunk := await file.read(1024*1024):
                f.write(chunk)


        db = mysql.connector.connect(
            host="localhost", user="root", password="123", database="project"
        )
        cursor = db.cursor()
        cursor.execute(
            "INSERT INTO notes (title, description, course, uploader_id, filename, file_size) VALUES (%s, %s, %s, %s, %s, %s)",
            (title, description, course, uploader_id, file.filename, os.path.getsize(file_path))
        )
        db.commit()

        return {"success": True, "filename": file.filename}
    except Exception as e:
        return json_error(str(e), 500)
    finally:
        if cursor: 
            cursor.close()
        if db: 
            db.close()
