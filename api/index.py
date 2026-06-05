from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import os

app = FastAPI()

# Configuração de CORS para permitir que o app Flutter (hospedado no Cloudflare) acesse a API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Em produção, substitua pelo domínio do Cloudflare Pages
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Modelos de Dados (Baseados nos modelos do seu app Flutter)
class Product(BaseModel):
    id: Optional[int] = None
    name: str
    brand: str
    price: float
    stock: int

class Client(BaseModel):
    id: Optional[int] = None
    name: str
    phone: str
    email: Optional[str] = None

@app.get("/api/health")
def health_check():
    return {"status": "ok", "message": "Jennifer Félix API is running"}

@app.get("/api/products", response_model=List[Product])
def get_products():
    # Placeholder: Aqui conectaremos ao Vercel Postgres futuramente
    return [
        {"id": 1, "name": "Batom Matte", "brand": "Natura", "price": 29.90, "stock": 10},
        {"id": 2, "name": "Perfume Kaiak", "brand": "Natura", "price": 120.00, "stock": 5}
    ]

@app.get("/api/clients", response_model=List[Client])
def get_clients():
    return [
        {"id": 1, "name": "Maria Silva", "phone": "11999999999"},
        {"id": 2, "name": "João Santos", "phone": "11888888888"}
    ]
