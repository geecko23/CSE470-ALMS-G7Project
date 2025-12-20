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

# MODELS 

class User(BaseModel):
    user_id: str
    name: str
    email: str
    password: str


class LoginUser(BaseModel):
    email: str
    password: str

# REGISTER 

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
        return {"success": True, "message": "Registration successful"}

    except Exception as e:
        return {"success": False, "error": str(e)}

    finally:
        cursor.close()
        db.close()

# LOGIN 

@app.post("/login")
def login(user: LoginUser):
    try:
        db = mysql.connector.connect(
            host="localhost",
            user="root",
            password="123",
            database="project"
        )
        cursor = db.cursor(dictionary=True)

        cursor.execute(
            "SELECT * FROM users WHERE email = %s",
            (user.email,)
        )
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
        cursor.close()
        db.close()
