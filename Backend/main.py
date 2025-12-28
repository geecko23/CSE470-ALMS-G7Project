from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from pydantic import BaseModel
import mysql.connector
import os
import shutil

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

# ===================== USER SYSTEM =====================
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

# ===================== CONSULTATIONS =====================
@app.get("/consultations/{student_id}")
def get_consultations(student_id: str):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute(
            "SELECT id, course_name, faculty_name, time_slot, status FROM consultations WHERE student_id=%s",
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
            "INSERT INTO consultations (student_id, course_name, faculty_name, time_slot) VALUES (%s,%s,%s,%s)",
            (cons.student_id, cons.course_name, cons.faculty_name, cons.time_slot)
        )
        db.commit()
        return {"success": True, "message": "Consultation booked successfully"}
    except Exception as e:
        return json_error(str(e))
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.put("/consultations/update_status")
def update_status(consultation_id: int, status: str):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "UPDATE consultations SET status=%s WHERE id=%s",
            (status, consultation_id)
        )
        db.commit()
        return {"success": True, "message": "Status updated"}
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.get("/faculty/{f_id}")
def check_faculty(f_id: str):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT f_id, f_name, f_initial, con_status FROM faculties WHERE f_id=%s", (f_id,))
        faculty = cursor.fetchone()
        if faculty:
            return {"success": True, "faculty": faculty}
        return {"success": False, "message": "Not a faculty"}
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.get("/consultations/faculty/{f_initial}")
def get_faculty_consultations(f_initial: str):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute(
            "SELECT id, student_id, course_name, faculty_name, time_slot, status FROM consultations WHERE faculty_name=%s",
            (f_initial,)
        )
        consultations = cursor.fetchall()
        return {"success": True, "consultations": consultations}
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.get("/faculties")
def get_available_faculties():
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute("SELECT f_id, f_name, f_initial FROM faculties WHERE con_status='available'")
        faculties = cursor.fetchall()
        return {"success": True, "faculties": faculties}
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        if cursor: cursor.close()
        if db: db.close()

# ===================== NOTES SYSTEM =====================
@app.post("/api/notes/upload")
async def upload_note(
    title: str = Form(...),
    description: str = Form(...),
    course: str = Form(...),
    uploader_id: str = Form(...),
    file: UploadFile = File(...)
):
    db = cursor = None
    try:
        # Save file
        file_location = os.path.join(UPLOAD_DIR, file.filename)
        with open(file_location, "wb") as f:
            shutil.copyfileobj(file.file, f)

        # Save metadata to DB
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "INSERT INTO notes (title, description, course, filename, uploader_id, file_size) VALUES (%s,%s,%s,%s,%s,%s)",
            (title, description, course, file.filename, uploader_id, os.path.getsize(file_location))
        )
        db.commit()
        return {"success": True, "message": "Note uploaded successfully"}
    except Exception as e:
        return json_error(str(e))
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.get("/api/notes/user/{user_id}")
def get_user_notes(user_id: str):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute(
            "SELECT id, title, description, course, filename, uploader_id, file_size FROM notes WHERE uploader_id=%s",
            (user_id,)
        )
        notes = cursor.fetchall()
        return {"success": True, "notes": notes}
    except Exception as e:
        return json_error(str(e))
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.get("/api/notes/all")
def get_all_notes():
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute(
            "SELECT n.id, n.title, n.description, n.course, n.filename, n.uploader_id, n.file_size, u.name AS uploader_name FROM notes n JOIN users u ON n.uploader_id = u.user_id"
        )
        notes = cursor.fetchall()
        return {"success": True, "notes": notes}
    except Exception as e:
        return json_error(str(e))
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.get("/api/notes/download/{filename}")
def download_note(filename: str):
    file_path = os.path.join(UPLOAD_DIR, filename)
    if os.path.exists(file_path):
        return FileResponse(file_path, media_type="application/octet-stream", filename=filename)
    return json_error("File not found", 404)
