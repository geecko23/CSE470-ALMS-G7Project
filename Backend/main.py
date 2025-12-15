from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import mysql.connector

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic model for JSON body
class User(BaseModel):
    user_id: str
    name: str
    email: str
    password: str

@app.post("/register")
def register(user: User):
    try:
        db = mysql.connector.connect(
            host="localhost",
            user="root",
            password="123",
            database="project"
        )
        cursor = db.cursor()
        cursor.execute(
            "INSERT INTO users (user_id, name, email, password) VALUES (%s, %s, %s, %s)",
            (user.user_id, user.name, user.email, user.password)
        )
        db.commit()
        return {"success": True}
    except Exception as e:
        return {"success": False, "error": str(e)}
