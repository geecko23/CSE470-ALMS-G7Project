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

# ===================== MODELS =====================

class User(BaseModel):
    user_id: str
    name: str
    email: str
    password: str

class LoginUser(BaseModel):
    email: str
    password: str

class Consultation(BaseModel):
    student_id: str
    course_name: str
    faculty_name: str
    time_slot: str

class Faculty(BaseModel):
    f_id: str
    f_name: str
    f_initial: str
    con_status: str

# ===================== HELPERS =====================

def json_error(message: str, code: int = 400):
    return JSONResponse(content={"success": False, "error": message}, status_code=code)

def get_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="123",
        database="project"
    )

# ===================== REGISTER =====================

@app.post("/register")
def register(user: User):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "INSERT INTO users (user_id, name, email, password) VALUES (%s, %s, %s, %s)",
            (user.user_id, user.name, user.email, user.password)
        )
        db.commit()
        return {"success": True, "message": "Registration successful"}
    except Exception as e:
        return json_error(str(e))
    finally:
        if cursor: cursor.close()
        if db: db.close()

# ===================== LOGIN =====================

@app.post("/login")
def login(user: LoginUser):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT * FROM users WHERE email=%s", (user.email,))
        db_user = cursor.fetchone()

        if not db_user:
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
        return json_error(str(e))
    finally:
        if cursor: cursor.close()
        if db: db.close()

# ===================== UPLOAD NOTES =====================

@app.post("/api/notes/upload")
async def upload_note(
    title: str = Form(...),
    description: str = Form(""),
    course: str = Form(...),
    uploader_id: str = Form(...),
    file: UploadFile = File(...)
):
    db = cursor = None
    try:
        allowed_courses = ["CSE", "MAT", "PHY"]
        if not any(x in course.upper() for x in allowed_courses):
            return json_error("Invalid course code")

        file_path = os.path.join(UPLOAD_DIR, file.filename)
        with open(file_path, "wb") as f:
            while chunk := await file.read(1024 * 1024):
                f.write(chunk)

        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            """INSERT INTO notes 
            (title, description, course, uploader_id, filename, file_size)
            VALUES (%s, %s, %s, %s, %s, %s)""",
            (
                title,
                description,
                course,
                uploader_id,
                file.filename,
                os.path.getsize(file_path),
            ),
        )
        db.commit()
        return {"success": True, "filename": file.filename}
    except Exception as e:
        return json_error(str(e), 500)
    finally:
        if cursor: cursor.close()
        if db: db.close()

# ===================== CONSULTATIONS =====================

@app.get("/consultations/{student_id}")
def get_consultations(student_id: str):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute(
            """SELECT course_name, faculty_name, time_slot, status
               FROM consultations WHERE student_id=%s""",
            (student_id,)
        )
        consultations = cursor.fetchall()
        return {"success": True, "consultations": consultations}
    except Exception as e:
        return json_error(str(e))
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.post("/consultations")
def book_consultation(cons: Consultation):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            """INSERT INTO consultations
            (student_id, course_name, faculty_name, time_slot)
            VALUES (%s, %s, %s, %s)""",
            (cons.student_id, cons.course_name, cons.faculty_name, cons.time_slot),
        )
        db.commit()
        return {"success": True, "message": "Consultation booked successfully"}
    except Exception as e:
        return json_error(str(e))
    finally:
        if cursor: cursor.close()
        if db: db.close()

# ===================== FACULTIES =====================

# GET available faculties only
@app.get("/faculties")
def get_available_faculties():
    db = None
    cursor = None
    try:
        db = mysql.connector.connect(
            host="localhost", user="root", password="123", database="project"
        )
        cursor = db.cursor(dictionary=True)
        cursor.execute(
            "SELECT f_id, f_name, f_initial FROM faculties WHERE con_status='available'"
        )
        faculties = cursor.fetchall()

        return {"success": True, "faculties": faculties}
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        if cursor: cursor.close()
        if db: db.close()

