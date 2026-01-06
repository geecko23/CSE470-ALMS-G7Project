from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, FileResponse
from pydantic import BaseModel, field_validator

import mysql.connector
import os
import shutil
import uvicorn
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
    @field_validator('email')
    @classmethod
    def validate_email(cls, v):
        if not v.endswith('bracu.ac.bd'):
            raise ValueError('Email must end with bracu.ac.bd')
        return v

    @field_validator('password')
    @classmethod
    def validate_password(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters long')
        return v

class LoginUser(BaseModel):
    email: str
    password: str

class Consultation(BaseModel):
    student_id: str
    course_name: str
    faculty_name: str
    day: str
    time_slot: str


class Faculty(BaseModel):
    f_id: str
    f_name: str
    f_initial: str
    con_status: str

class SaveNote(BaseModel):
    user_id: str
    note_id: int

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
            "SELECT id, course_name, faculty_name, day, time_slot, status FROM consultations WHERE student_id=%s",
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
            "INSERT INTO consultations (student_id, course_name, faculty_name, day, time_slot) VALUES (%s,%s,%s,%s,%s)",
            (cons.student_id, cons.course_name, cons.faculty_name, cons.day, cons.time_slot)
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

@app.get("/role/{user_id}")
def check_role(user_id: str):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)

        #Faculty check
        cursor.execute(
            "SELECT f_id AS id, f_name AS name, f_initial AS initial, con_status AS con_status, 'faculty' AS role "
            "FROM faculties WHERE f_id=%s",
            (user_id,)
        )
        faculty = cursor.fetchone()
        if faculty:
            return {"success": True, "role": faculty["role"], "person": faculty}

        #st check 
        cursor.execute(
            "SELECT st_id AS id, st_name AS name, st_initial AS initial, st_con_status AS con_status, 'tutor' AS role "
            "FROM student_tutors WHERE st_id=%s",
            (user_id,)
        )
        tutor = cursor.fetchone()
        if tutor:
            return {"success": True, "role": tutor["role"], "person": tutor}

        #student
        return {"success": False, "message": "Not a manager"}  # student

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
            "SELECT id, student_id, course_name, faculty_name, day, time_slot, status FROM consultations WHERE faculty_name=%s"
            (f_initial,)
        )
        consultations = cursor.fetchall()
        return {"success": True, "consultations": consultations}
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.get("/consultation-managers")
def get_available_managers():
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)

        # available faculty initials
        cursor.execute("SELECT f_initial AS initial FROM faculties WHERE con_status='available'")
        fac = cursor.fetchall()

        # available tutor initials (YOUR table/columns)
        cursor.execute("SELECT st_initial AS initial FROM student_tutors WHERE st_con_status='available'")
        tut = cursor.fetchall()

        initials = [x["initial"] for x in fac] + [x["initial"] for x in tut]
        return {"success": True, "initials": initials}

    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.delete("/consultations/{consultation_id}")
def delete_consultation(consultation_id: int):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor()

        cursor.execute("DELETE FROM consultations WHERE id=%s", (consultation_id,))
        db.commit()

        if cursor.rowcount == 0:
            return {"success": False, "message": "Consultation not found"}

        return {"success": True, "message": "Consultation deleted successfully"}
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

#save
@app.post("/api/notes/save")
def save_note(data: SaveNote):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "SELECT id FROM saved_notes WHERE user_id=%s AND note_id=%s",
            (data.user_id, data.note_id)
        )
        if cursor.fetchone():
            return {"success": False, "message": "Note already saved"}
        
        cursor.execute(
            "INSERT INTO saved_notes (user_id, note_id) VALUES (%s, %s)",
            (data.user_id, data.note_id)
        )
        db.commit()
        return {"success": True, "message": "Note saved successfully"}
    except Exception as e:
        return json_error(str(e))
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.delete("/api/notes/unsave/{user_id}/{note_id}")
def unsave_note(user_id: str, note_id: int):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor()
        cursor.execute(
            "DELETE FROM saved_notes WHERE user_id=%s AND note_id=%s",
            (user_id, note_id)
        )
        db.commit()
        return {"success": True, "message": "Note removed from saved"}
    except Exception as e:
        return json_error(str(e))
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.get("/api/notes/saved/{user_id}")
def get_saved_notes(user_id: str):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT n.id, n.title, n.description, n.course, n.filename, 
                   n.uploader_id, n.file_size, u.name AS uploader_name
            FROM saved_notes sn
            JOIN notes n ON sn.note_id = n.id
            JOIN users u ON n.uploader_id = u.user_id
            WHERE sn.user_id = %s
            ORDER BY sn.id DESC
            """,
            (user_id,)
        )
        notes = cursor.fetchall()
        return {"success": True, "notes": notes}
    except Exception as e:
        return json_error(str(e))
    finally:
        if cursor: cursor.close()
        if db: db.close()

@app.delete("/api/notes/delete/{user_id}/{note_id}")
def delete_note(user_id: str, note_id: int):
    db = cursor = None
    try:
        db = get_db()
        cursor = db.cursor(dictionary=True)
        
        cursor.execute(
            "SELECT filename, uploader_id FROM notes WHERE id=%s",
            (note_id,)
        )
        note = cursor.fetchone()
        
        if not note:
            return {"success": False, "message": "Note not found"}
        
        if note['uploader_id'] != user_id:
            return {"success": False, "message": "Unauthorized"}
        

        file_path = os.path.join(UPLOAD_DIR, note['filename'])
        if os.path.exists(file_path):
            os.remove(file_path)
        
  
        cursor.execute("DELETE FROM saved_notes WHERE note_id=%s", (note_id,))
        

        cursor.execute("DELETE FROM notes WHERE id=%s", (note_id,))
        
        db.commit()
        return {"success": True, "message": "Note deleted successfully"}
    except Exception as e:
        return {"success": False, "error": str(e)}
    finally:
        if cursor: cursor.close()
        if db: db.close()