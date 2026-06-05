from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Conexão com o Banco de Dados
def get_db_connection():
    # A Vercel injeta automaticamente POSTGRES_URL se você conectar o Storage
    conn = psycopg2.connect(os.environ.get('POSTGRES_URL'), cursor_factory=RealDictCursor)
    return conn

# Inicialização do Banco (Criação de Tabelas)
@app.on_event("startup")
def setup_database():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Tabela de Clientes
        cur.execute("""
            CREATE TABLE IF NOT EXISTS clients (
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL,
                phone TEXT,
                email TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Tabela de Produtos
        cur.execute("""
            CREATE TABLE IF NOT EXISTS products (
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL,
                brand TEXT,
                price DECIMAL(10,2) NOT NULL,
                stock INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Tabela de Vendas
        cur.execute("""
            CREATE TABLE IF NOT EXISTS sales (
                id SERIAL PRIMARY KEY,
                client_id INTEGER REFERENCES clients(id),
                total_amount DECIMAL(10,2) NOT NULL,
                sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        conn.commit()
        cur.close()
        conn.close()
        print("Database setup complete.")
    except Exception as e:
        print(f"Error setting up database: {e}")

# Modelos Pydantic
class ClientBase(BaseModel):
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None

class ProductBase(BaseModel):
    name: str
    brand: Optional[str] = None
    price: float
    stock: int

# Endpoints de Saúde
@app.get("/api/health")
def health():
    return {"status": "ok"}

# --- CLIENTS ---
@app.get("/api/clients")
def list_clients():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM clients ORDER BY name")
    clients = cur.fetchall()
    cur.close()
    conn.close()
    return clients

@app.post("/api/clients")
def create_client(client: ClientBase):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO clients (name, phone, email) VALUES (%s, %s, %s) RETURNING *",
        (client.name, client.phone, client.email)
    )
    new_client = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()
    return new_client

# --- PRODUCTS ---
@app.get("/api/products")
def list_products():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM products ORDER BY name")
    products = cur.fetchall()
    cur.close()
    conn.close()
    return products

@app.post("/api/products")
def create_product(product: ProductBase):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO products (name, brand, price, stock) VALUES (%s, %s, %s, %s) RETURNING *",
        (product.name, product.brand, product.price, product.stock)
    )
    new_product = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()
    return new_product
