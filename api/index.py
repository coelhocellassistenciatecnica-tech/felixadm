from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os
import psycopg2
from psycopg2.extras import RealDictCursor
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db_connection():
    postgres_url = os.environ.get('POSTGRES_URL')
    print(f"POSTGRES_URL: {postgres_url}")
    conn = psycopg2.connect(postgres_url, cursor_factory=RealDictCursor)
    return conn

@app.on_event("startup")
def setup_database():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # Clients
        cur.execute("""
            CREATE TABLE IF NOT EXISTS clients (
                id SERIAL PRIMARY KEY,
                name TEXT NOT NULL,
                phone TEXT,
                email TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Products
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
        
        # Sales
        cur.execute("""
            CREATE TABLE IF NOT EXISTS sales (
                id SERIAL PRIMARY KEY,
                client_id INTEGER REFERENCES clients(id),
                total_amount DECIMAL(10,2) NOT NULL,
                status TEXT DEFAULT 'pending',
                sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Sale Items
        cur.execute("""
            CREATE TABLE IF NOT EXISTS sale_items (
                id SERIAL PRIMARY KEY,
                sale_id INTEGER REFERENCES sales(id) ON DELETE CASCADE,
                product_id INTEGER REFERENCES products(id),
                quantity INTEGER NOT NULL,
                unit_price DECIMAL(10,2) NOT NULL
            )
        """)
        
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

# Models
class ClientBase(BaseModel):
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None

class ProductBase(BaseModel):
    name: str
    brand: Optional[str] = None
    price: float
    stock: int

class SaleItemBase(BaseModel):
    product_id: int
    quantity: int
    unit_price: float

class SaleBase(BaseModel):
    client_id: int
    total_amount: float
    items: List[SaleItemBase]

# --- ENDPOINTS ---

@app.get("/api/health")
def health(): return {"status": "ok"}

# Clients
@app.get("/api/clients")
def list_clients():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM clients ORDER BY name")
    res = cur.fetchall()
    cur.close()
    conn.close()
    return res

@app.post("/api/clients")
def create_client(client: ClientBase):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO clients (name, phone, email) VALUES (%s, %s, %s) RETURNING *", (client.name, client.phone, client.email))
    res = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()
    return res

# Products
@app.get("/api/products")
def list_products():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM products ORDER BY name")
    res = cur.fetchall()
    cur.close()
    conn.close()
    return res

@app.post("/api/products")
def create_product(product: ProductBase):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO products (name, brand, price, stock) VALUES (%s, %s, %s, %s) RETURNING *", (product.name, product.brand, product.price, product.stock))
    res = cur.fetchone()
    conn.commit()
    cur.close()
    conn.close()
    return res

# Sales
@app.get("/api/sales")
def list_sales():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT s.*, c.name as client_name 
        FROM sales s 
        LEFT JOIN clients c ON s.client_id = c.id 
        ORDER BY s.sale_date DESC
    """)
    res = cur.fetchall()
    cur.close()
    conn.close()
    return res

@app.post("/api/sales")
def create_sale(sale: SaleBase):
    conn = get_db_connection()
    cur = conn.cursor()
    try:
        cur.execute("INSERT INTO sales (client_id, total_amount) VALUES (%s, %s) RETURNING id", (sale.client_id, sale.total_amount))
        sale_id = cur.fetchone()['id']
        
        for item in sale.items:
            cur.execute(
                "INSERT INTO sale_items (sale_id, product_id, quantity, unit_price) VALUES (%s, %s, %s, %s)",
                (sale_id, item.product_id, item.quantity, item.unit_price)
            )
            # Update stock
            cur.execute("UPDATE products SET stock = stock - %s WHERE id = %s", (item.quantity, item.product_id))
            
        conn.commit()
        return {"id": sale_id, "message": "Sale created successfully"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close()
        conn.close()

# Dashboard Stats
@app.get("/api/stats")
def get_stats():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT COUNT(*) as total_clients FROM clients")
    total_clients = cur.fetchone()['total_clients']
    cur.execute("SELECT COUNT(*) as total_products FROM products")
    total_products = cur.fetchone()['total_products']
    cur.execute("SELECT SUM(total_amount) as total_revenue FROM sales")
    total_revenue = cur.fetchone()['total_revenue'] or 0
    cur.close()
    conn.close()
    return {
        "total_clients": total_clients,
        "total_products": total_products,
        "total_revenue": float(total_revenue)
    }
