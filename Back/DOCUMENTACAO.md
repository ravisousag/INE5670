# API Backend - Documentação Técnica Completa

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Dependências e Versões](#dependências-e-versões)
3. [Configuração e Instalação](#configuração-e-instalação)
4. [Modelos de Dados](#modelos-de-dados)
5. [Rotas da API](#rotas-da-api)
6. [Lógica de Pareamento NFC](#lógica-de-pareamento-nfc)
7. [Responses por Rota](#responses-por-rota)

---

## 🎯 Visão Geral

**API Backend** é uma aplicação Flask que fornece um serviço RESTful para gerenciamento de usuários e integração com cartões NFC. O sistema permite:

- ✅ Gerenciar usuários (CRUD completo)
- ✅ Validar e registrar cartões NFC
- ✅ Realizar pareamento entre usuários e cartões NFC
- ✅ Manter logs de acesso
- ✅ Suporte a CORS para requisições do frontend

**Linguagem**: Python 3.x  
**Framework**: Flask  
**Banco de Dados**: SQLite  
**URL Base**: `http://127.0.0.1:5000`

---

## 📦 Dependências e Versões

### Arquivo: `requirements.txt`

```
Flask==3.0.0
Flask-SQLAlchemy==3.1.1
flask-cors==6.0.1
SQLAlchemy==2.0.44
python-dotenv==1.1.1
gunicorn==20.1.0
```

### Descrição das Dependências

| Dependência | Versão | Finalidade |
|-------------|--------|-----------|
| **Flask** | 3.0.0 | Framework web para criar a API RESTful |
| **Flask-SQLAlchemy** | 3.1.1 | ORM para gerenciar banco de dados SQLite |
| **flask-cors** | 6.0.1 | Habilita CORS (Cross-Origin Resource Sharing) |
| **SQLAlchemy** | 2.0.44 | Engine SQL para abstração do banco de dados |
| **python-dotenv** | 1.1.1 | Carregamento de variáveis de ambiente (.env) |
| **gunicorn** | 20.1.0 | Servidor WSGI para produção |

### Instalação de Dependências

```bash
pip install -r requirements.txt
```

---

## ⚙️ Configuração e Instalação

### 1. Criar ambiente virtual

```bash
python3 -m venv venv
source venv/bin/activate  # Linux/macOS
# ou
venv\Scripts\activate     # Windows
```

### 2. Instalar dependências

```bash
pip install -r requirements.txt
```

### 3. Estrutura de diretórios

```
Back/
├── requirements.txt              # Dependências Python
├── src/
│   ├── app.py                   # Aplicação principal Flask
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py              # Modelo User
│   │   ├── log.py               # Modelo Log
│   │   └── pairing.py           # Modelo PairingSession
│   └── arduino/
│       └── sketch_nov17a/
│           └── sketch_nov17a.ino # Código Arduino para leitura NFC
├── database.sqlite              # Banco de dados (criado automaticamente)
└── README.md                    # Guia geral
```

### 4. Executar a aplicação

```bash
cd src
python app.py
```

A API estará disponível em: `http://127.0.0.1:5000`

---

## 🗄️ Modelos de Dados

### **User** (`models/user.py`)

Representa um usuário do sistema.

```python
class User(db.Model):
    id              : Integer (PK)
    name            : String(100)
    cpf             : String(11) - UNIQUE
    email           : String(120) - UNIQUE
    phone           : String(20)
    nfc_card_uuid   : String(36) - UNIQUE - NULLABLE
    created_at      : DateTime
    updated_at      : DateTime
```

**Validações:**
- CPF: 11 dígitos numéricos, único
- Email: formato válido, único
- Phone: aceita vários formatos

**Serialização:**
```python
def to_dict() -> {
    'id': int,
    'name': str,
    'cpf': str,
    'email': str,
    'phone': str,
    'nfc_card_uuid': str | None,
    'created_at': ISO-8601,
    'updated_at': ISO-8601
}
```

---

### **Log** (`models/log.py`)

Registra todas as ações e acessos no sistema.

```python
class Log(db.Model):
    id              : Integer (PK)
    user_id         : Integer (FK) - NULLABLE
    nfc_uuid        : String(36)
    user_exists     : Boolean
    action          : String(50) - valores: LINK, UNLINK, ACCESS_GRANTED, ACCESS_DENIED, SYNC_NO_SESSION
    timestamp       : DateTime
```

**Tipos de Ação:**
- `LINK` - Cartão vinculado a usuário
- `UNLINK` - Cartão desvinculado
- `ACCESS_GRANTED` - Acesso autorizado com cartão válido
- `ACCESS_DENIED` - Acesso negado (cartão não encontrado)
- `SYNC_NO_SESSION` - Tentativa de pareamento sem sessão ativa

**Serialização:**
```python
def to_dict() -> {
    'id': int,
    'user_id': int | None,
    'nfc_uuid': str,
    'user_exists': bool,
    'action': str,
    'timestamp': ISO-8601
}
```

---

### **PairingSession** (`models/pairing.py`)

Gerencia sessões temporárias de pareamento entre usuário e cartão NFC.

```python
class PairingSession(db.Model):
    id              : Integer (PK)
    pair_token      : String(64) - UNIQUE
    user_id         : Integer (FK)
    created_at      : DateTime
    expires_at      : DateTime
    vinculado       : Boolean - default: False
```

**Comportamento:**
- Token criado no formato `XXXX-XXXX-XXXX`
- Expira em 60 segundos
- `vinculado` muda para `True` quando Arduino detecta o cartão NFC

**Serialização:**
```python
def to_dict() -> {
    'id': int,
    'pair_token': str,
    'user_id': int,
    'created_at': ISO-8601,
    'expires_at': ISO-8601,
    'vinculado': bool
}
```

---

## 🔄 Lógica de Pareamento NFC

### Visão Geral do Fluxo

O pareamento é um processo assíncrono em 3 etapas:

```
1. App solicita pareamento      → pair_start()
                                   ↓
2. App faz polling de status    → pair_status() (a cada 500ms)
                                   ↓
3. Arduino detecta NFC          → nfc_sync()
   (enquanto polling está ativo)
                                   ↓
4. App detecta mudança          → Modal fecha
   (polling retorna vinculado=true)
```

### Passo 1: Iniciar Sessão de Pareamento

**Fluxo:**
```
POST /api/nfc/pair_start
  ├─ Frontend fornece CPF do usuário
  ├─ Backend valida se usuário existe
  ├─ Verifica se usuário já tem cartão vinculado
  ├─ Gera token único (16 caracteres hexadecimais)
  ├─ Cria PairingSession com:
  │   - pair_token
  │   - user_id
  │   - expires_at = now + 60 segundos
  │   - vinculado = False
  └─ Retorna token e detalhes da sessão
```

**Código Backend:**
```python
@app.route('/api/nfc/pair_start', methods=['POST'])
def pair_start():
    # Validar CPF
    # Buscar usuário
    # Se usuário já tem NFC → retorna erro 409
    # Gerar token
    # Criar PairingSession
    # Retornar pair_token + expires_at
```

### Passo 2: App Faz Polling do Status

**Fluxo:**
```
GET /api/nfc/pair_status/{pair_token}
  ├─ Frontend chama a cada 500ms
  ├─ Backend retorna estado atual:
  │   - pair_token
  │   - vinculado (bool)
  │   - expired (bool)
  │   - user (dados do usuário se vinculado)
  │   - expires_at
  └─ Quando vinculado == True → Modal fecha automaticamente
```

**Código Backend:**
```python
@app.route('/api/nfc/pair_status/<string:pair_token>', methods=['GET'])
def pair_status(pair_token):
    # Buscar sessão pelo token
    # Verificar se expirou
    # Retornar estado atual
```

### Passo 3: Arduino Detecta NFC e Sincroniza

**Fluxo:**
```
POST /api/nfc/sync (chamado por Arduino)
  ├─ Arduino detecta UUID do cartão
  ├─ Envia POST com nfc_card_uuid
  ├─ Backend busca PairingSession:
  │   - Ativa (vinculado == False)
  │   - Não expirada
  │   - Mais recente (ORDER BY created_at DESC)
  ├─ Se encontrar:
  │   - Vincular UUID ao user da sessão
  │   - Marcar session.vinculado = True
  │   - Gravar Log de LINK
  │   - Retorna sucesso
  └─ Se não encontrar:
      - Gravar Log de SYNC_NO_SESSION
      - Retorna erro 404
```

**Código Backend:**
```python
@app.route('/api/nfc/sync', methods=['POST'])
def nfc_sync():
    # Receber nfc_card_uuid do Arduino
    # Buscar PairingSession ativa não expirada
    # Se encontrar:
    #   - Vincular user.nfc_card_uuid = nfc_uuid
    #   - session.vinculado = True
    #   - Gravar Log
    # Se não encontrar:
    #   - Gravar Log de rejeição
    #   - Retornar erro
```

### Diagrama de Fluxo Completo

```
┌─────────────────────────────────────────────────────┐
│              FRONTEND (Flutter App)                 │
└─────────────────────────────────────────────────────┘
           │
           │ 1. POST /api/nfc/pair_start
           ├────────────────────────────────→ BACKEND
           │                                    │
           │ 2a. Retorna pair_token           │
           │    + expires_at                  │
           ←────────────────────────────────  │
           │                                  │
           │ 2. GET /api/nfc/pair_status     │
           ├──────→ (polling cada 500ms)     │
           │         ←─────────────────      │
           │         [vinculado=false]       │
           │                                  │
           │        ←─────────────────       │
           │        [vinculado=false]        │
           │                                  │
    ┌──────────────────────────────────────────────┐
    │ HARDWARE (Arduino + Leitor NFC)              │
    │                                              │
    │ 3. POST /api/nfc/sync                       │
    │    (detecta cartão NFC)                     │
    │                                              │
    └──────────────────────────────────────────────┘
           │                                  │
           │ 3. POST /api/nfc/sync           │
           │    { "nfc_card_uuid": "..." }   │
           │                                  │
           │ 4. Backend vincula:             │
           │    - user.nfc_card_uuid = uuid  │
           │    - session.vinculado = True   │
           │    - Grava Log                  │
           ←────────────────────────────────
           │ 4. Retorna: { linked: true }
           │
           │ 2. GET /api/nfc/pair_status    │
           ├──────→ (próximo polling)        │
           │                                  │
           │        ←─────────────────       │
           │        [vinculado=true]  ← MUDANÇA!
           │        [user: {...}]     ← MUDANÇA!
           │
           ✓ Modal fecha automaticamente
           ✓ Usuário vê sucesso
```

### Timeline Temporal

```
T+0s   → App: POST /api/nfc/pair_start
T+0.1s → Backend cria PairingSession (expira em 60s)
T+0.2s → App: GET /api/nfc/pair_status (1º polling)
         Backend: vinculado=false
T+0.7s → App: GET /api/nfc/pair_status (2º polling)
         Backend: vinculado=false
T+1.2s → App: GET /api/nfc/pair_status (3º polling)
         Backend: vinculado=false
...
T+15s  → Arduino detecta NFC
         Arduino: POST /api/nfc/sync
         Backend: vincula UUID, marca vinculado=true
T+15.5s → App: GET /api/nfc/pair_status (29º polling)
         Backend: vinculado=true ← SUCESSO!
         Modal fecha automaticamente
```

### Tratamento de Erros no Pareamento

| Cenário | Status | Resposta |
|---------|--------|----------|
| Usuário não encontrado | 404 | `{'error': 'Usuário não encontrado'}` |
| Usuário já tem NFC | 409 | `{'error': 'Usuário já possui cartão'}` |
| Token expirado | 404 | Retorna expired=true |
| Nenhuma sessão ativa | 404 | Arduino recebe erro, Log criado |
| UUID já vinculado | 409 | `{'error': 'UUID já vinculado'}` |

---

## 📡 Rotas da API

### 1. Gerenciamento de Usuários

#### **POST** `/api/users` - Criar Usuário
Cria um novo usuário no sistema.

**Request:**
```json
{
  "name": "João Silva",
  "cpf": "12345678900",
  "email": "joao@example.com",
  "phone": "11999999999"
}
```

**Response 201 (Sucesso):**
```json
{
  "message": "Usuário criado com sucesso",
  "user": {
    "id": 1,
    "name": "João Silva",
    "cpf": "12345678900",
    "email": "joao@example.com",
    "phone": "11999999999",
    "nfc_card_uuid": null,
    "created_at": "2024-11-30T15:30:00-03:00",
    "updated_at": "2024-11-30T15:30:00-03:00"
  }
}
```

**Response 400 (Validação):**
```json
{
  "error": "O campo name é obrigatório"
}
```
```json
{
  "error": "CPF inválido. Deve conter 11 dígitos numéricos"
}
```
```json
{
  "error": "Email inválido"
}
```
```json
{
  "error": "CPF já cadastrado"
}
```
```json
{
  "error": "Email já cadastrado"
}
```

**Response 500 (Erro Servidor):**
```json
{
  "error": "Descrição do erro interno"
}
```

---

#### **GET** `/api/users` - Listar Usuários
Retorna lista de todos os usuários.

**Response 200:**
```json
{
  "users": [
    {
      "id": 1,
      "name": "João Silva",
      "cpf": "12345678900",
      "email": "joao@example.com",
      "phone": "11999999999",
      "nfc_card_uuid": null,
      "created_at": "2024-11-30T15:30:00-03:00",
      "updated_at": "2024-11-30T15:30:00-03:00"
    }
  ],
  "total": 1
}
```

**Response 500:**
```json
{
  "error": "Descrição do erro"
}
```

---

#### **GET** `/api/users/cpf/{cpf}` - Obter Usuário
Busca um usuário específico pelo CPF.

**Parâmetro:**
- `cpf` (string): CPF do usuário (com ou sem formatação)

**Response 200:**
```json
{
  "user": {
    "id": 1,
    "name": "João Silva",
    "cpf": "12345678900",
    "email": "joao@example.com",
    "phone": "11999999999",
    "nfc_card_uuid": null,
    "created_at": "2024-11-30T15:30:00-03:00",
    "updated_at": "2024-11-30T15:30:00-03:00"
  }
}
```

**Response 404:**
```json
{
  "error": "Usuário não encontrado"
}
```

**Response 400:**
```json
{
  "error": "CPF inválido. Deve conter 11 dígitos numéricos"
}
```

---

#### **PUT** `/api/users/cpf/{cpf}` - Editar Usuário
Atualiza dados de um usuário.

**Request (todos os campos são opcionais):**
```json
{
  "name": "João Silva Santos",
  "email": "novo_email@example.com",
  "phone": "11988888888",
  "cpf": "98765432100",
  "nfc_card_uuid": "uuid-do-cartao"
}
```

**Response 200:**
```json
{
  "message": "Usuário atualizado com sucesso",
  "user": {
    "id": 1,
    "name": "João Silva Santos",
    "cpf": "98765432100",
    "email": "novo_email@example.com",
    "phone": "11988888888",
    "nfc_card_uuid": "uuid-do-cartao",
    "created_at": "2024-11-30T15:30:00-03:00",
    "updated_at": "2024-11-30T16:45:00-03:00"
  }
}
```

**Response 400:**
```json
{
  "error": "CPF inválido. Deve conter 11 dígitos numéricos"
}
```
```json
{
  "error": "Email já cadastrado"
}
```
```json
{
  "error": "UUID do cartão NFC já cadastrado"
}
```

**Response 404:**
```json
{
  "error": "Usuário não encontrado"
}
```

---

#### **DELETE** `/api/users/cpf/{cpf}` - Deletar Usuário
Remove um usuário do sistema.

**Response 200:**
```json
{
  "message": "Usuário deletado com sucesso"
}
```

**Response 404:**
```json
{
  "error": "Usuário não encontrado"
}
```

**Response 400:**
```json
{
  "error": "CPF inválido. Deve conter 11 dígitos numéricos"
}
```

---

### 2. Gerenciamento de NFC

#### **POST** `/api/nfc/pair_start` - Iniciar Pareamento
Cria uma sessão de pareamento entre usuário e cartão NFC.

**Request:**
```json
{
  "cpf": "12345678900"
}
```

**Response 201 (Sucesso):**
```json
{
  "pair_token": "AB12-CD34-EF56",
  "expires_at": "2024-11-30T15:31:00-03:00",
  "vinculado": false,
  "user_id": 1
}
```

**Response 400:**
```json
{
  "error": "cpf é obrigatório"
}
```

**Response 404:**
```json
{
  "error": "Usuário não encontrado"
}
```

**Response 409 (Conflito):**
```json
{
  "error": "Usuário já possui um cartão NFC vinculado"
}
```

---

#### **GET** `/api/nfc/pair_status/{pair_token}` - Status do Pareamento
Consulta o status atual de uma sessão de pareamento.

**Parâmetro:**
- `pair_token` (string): Token retornado por `pair_start`

**Response 200 (Aguardando):**
```json
{
  "pair_token": "AB12-CD34-EF56",
  "vinculado": false,
  "expired": false,
  "user": {
    "id": 1,
    "name": "João Silva",
    "cpf": "12345678900",
    "email": "joao@example.com",
    "phone": "11999999999",
    "nfc_card_uuid": null,
    "created_at": "2024-11-30T15:30:00-03:00",
    "updated_at": "2024-11-30T15:30:00-03:00"
  },
  "expires_at": "2024-11-30T15:31:00-03:00"
}
```

**Response 200 (Vinculado com Sucesso):**
```json
{
  "pair_token": "AB12-CD34-EF56",
  "vinculado": true,
  "expired": false,
  "user": {
    "id": 1,
    "name": "João Silva",
    "cpf": "12345678900",
    "email": "joao@example.com",
    "phone": "11999999999",
    "nfc_card_uuid": "abc123xyz789",
    "created_at": "2024-11-30T15:30:00-03:00",
    "updated_at": "2024-11-30T15:30:15-03:00"
  },
  "expires_at": "2024-11-30T15:31:00-03:00"
}
```

**Response 200 (Token Expirado):**
```json
{
  "pair_token": "AB12-CD34-EF56",
  "vinculado": false,
  "expired": true,
  "user": null,
  "expires_at": "2024-11-30T15:31:00-03:00"
}
```

**Response 404:**
```json
{
  "error": "Token de pareamento não encontrado"
}
```

---

#### **POST** `/api/nfc/sync` - Sincronizar NFC (Arduino)
Endpoint chamado pelo Arduino quando detecta um cartão NFC durante pareamento.

**Request (do Arduino):**
```json
{
  "nfc_card_uuid": "abc123xyz789"
}
```

**Response 200 (Sucesso):**
```json
{
  "linked": true,
  "user": {
    "id": 1,
    "name": "João Silva",
    "cpf": "12345678900",
    "email": "joao@example.com",
    "phone": "11999999999",
    "nfc_card_uuid": "abc123xyz789",
    "created_at": "2024-11-30T15:30:00-03:00",
    "updated_at": "2024-11-30T15:30:15-03:00"
  },
  "pair_token": "AB12-CD34-EF56"
}
```

**Response 400:**
```json
{
  "error": "nfc_card_uuid é obrigatório"
}
```

**Response 404 (Sem sessão ativa):**
```json
{
  "linked": false,
  "message": "Nenhuma sessão de pareamento ativa"
}
```

**Response 409 (UUID já vinculado):**
```json
{
  "error": "UUID já vinculado a outro usuário"
}
```

---

#### **PUT** `/api/nfc/link` - Vincular NFC Manualmente
Vincula um cartão NFC a um usuário sem pareamento.

**Request:**
```json
{
  "nfc_card_uuid": "abc123xyz789",
  "cpf": "12345678900"
}
```

**Response 200:**
```json
{
  "message": "Cartão NFC vinculado com sucesso",
  "user": {
    "id": 1,
    "name": "João Silva",
    "cpf": "12345678900",
    "email": "joao@example.com",
    "phone": "11999999999",
    "nfc_card_uuid": "abc123xyz789",
    "created_at": "2024-11-30T15:30:00-03:00",
    "updated_at": "2024-11-30T15:30:15-03:00"
  },
  "log_id": 42
}
```

**Response 400:**
```json
{
  "error": "nfc_card_uuid e cpf são obrigatórios"
}
```

**Response 404:**
```json
{
  "error": "Usuário não encontrado"
}
```

**Response 409 (Usuário já tem NFC):**
```json
{
  "error": "Usuário já possui um cartão NFC registrado",
  "nfc_card_uuid": "outro_uuid_anterior"
}
```

**Response 409 (UUID já vinculado):**
```json
{
  "error": "UUID do cartão NFC já está registrado em outro usuário"
}
```

---

#### **PUT** `/api/nfc/unlink` - Desvinculcar NFC
Remove a associação de um cartão NFC de um usuário.

**Request:**
```json
{
  "cpf": "12345678900"
}
```

**Response 200:**
```json
{
  "message": "Cartão NFC desvinculado com sucesso",
  "user": {
    "id": 1,
    "name": "João Silva",
    "cpf": "12345678900",
    "email": "joao@example.com",
    "phone": "11999999999",
    "nfc_card_uuid": null,
    "created_at": "2024-11-30T15:30:00-03:00",
    "updated_at": "2024-11-30T15:31:45-03:00"
  },
  "log_id": 43
}
```

**Response 400 (Sem NFC vinculado):**
```json
{
  "error": "Usuário não possui cartão NFC vinculado"
}
```

**Response 404:**
```json
{
  "error": "Usuário não encontrado"
}
```

---

#### **GET** `/api/nfc/validate/{nfc_uuid}` - Validar Cartão NFC
Valida um cartão NFC e registra acesso no log.

**Parâmetro:**
- `nfc_uuid` (string): UUID do cartão NFC

**Response 200 (Cartão Válido):**
```json
{
  "authorized": true,
  "message": "Acesso permitido para João Silva",
  "user": {
    "id": 1,
    "name": "João Silva",
    "cpf": "12345678900",
    "email": "joao@example.com",
    "phone": "11999999999",
    "nfc_card_uuid": "abc123xyz789",
    "created_at": "2024-11-30T15:30:00-03:00",
    "updated_at": "2024-11-30T15:30:15-03:00"
  },
  "log_id": 44
}
```

**Response 404 (Cartão Inválido):**
```json
{
  "authorized": false,
  "message": "Cartão NFC não cadastrado",
  "log_id": 45
}
```

---

### 3. Logs

#### **GET** `/api/logs` - Listar Logs
Retorna todos os logs em ordem decrescente de data.

**Response 200:**
```json
{
  "logs": [
    {
      "id": 45,
      "user_id": null,
      "nfc_uuid": "unknown_card_123",
      "user_exists": false,
      "action": "ACCESS_DENIED",
      "timestamp": "2024-11-30T15:32:00-03:00"
    },
    {
      "id": 44,
      "user_id": 1,
      "nfc_uuid": "abc123xyz789",
      "user_exists": true,
      "action": "ACCESS_GRANTED",
      "timestamp": "2024-11-30T15:31:50-03:00"
    },
    {
      "id": 43,
      "user_id": 1,
      "nfc_uuid": "abc123xyz789",
      "user_exists": true,
      "action": "UNLINK",
      "timestamp": "2024-11-30T15:31:45-03:00"
    },
    {
      "id": 42,
      "user_id": 1,
      "nfc_uuid": "abc123xyz789",
      "user_exists": true,
      "action": "LINK",
      "timestamp": "2024-11-30T15:30:15-03:00"
    }
  ],
  "total": 4
}
```

**Response 500:**
```json
{
  "error": "Descrição do erro"
}
```

---

## 🚀 Executando a API

### Desenvolvimento

```bash
cd src
python app.py
```

Saída esperada:
```
* Running on http://127.0.0.1:5000
* Debug mode: on
```

### Produção

```bash
cd src
gunicorn --bind 0.0.0.0:5000 app:app
```

---

## ✅ Checklist de Funcionalidades

- [x] CRUD de usuários
- [x] Validação de CPF e email
- [x] Vinculação manual de cartão NFC
- [x] Desvinculação de cartão NFC
- [x] Pareamento via token (pair_start)
- [x] Polling de status (pair_status)
- [x] Sincronização com Arduino (nfc_sync)
- [x] Validação de cartão NFC (nfc_validate)
- [x] Sistema de logs
- [x] CORS habilitado
- [x] Banco de dados SQLite

---

## 📊 Formato de Respostas

Todas as respostas da API seguem este padrão:

### Sucesso (2xx)
```json
{
  "message": "Descrição da ação bem-sucedida",
  "data": { /* dados específicos */ }
}
```

### Erro (4xx/5xx)
```json
{
  "error": "Descrição do erro"
}
```

### Status HTTP Utilizados

| Código | Significado | Quando Usar |
|--------|-------------|------------|
| 200 | OK | Requisição bem-sucedida |
| 201 | Created | Recurso criado com sucesso |
| 400 | Bad Request | Validação falhou ou parâmetros inválidos |
| 404 | Not Found | Recurso não encontrado |
| 409 | Conflict | Conflito (ex: duplicação, estado inválido) |
| 500 | Server Error | Erro interno do servidor |

---

## 🔐 Segurança

### Validações Implementadas

- ✅ Validação de formato de CPF (11 dígitos)
- ✅ Validação de formato de email
- ✅ Unicidade de CPF, email e UUID de NFC
- ✅ Sanitização de entrada (remoção de caracteres especiais)
- ✅ Verificação de sessões expiradas
- ✅ Prevenção de duplicação de UUID

### Recomendações para Produção

1. Adicionar autenticação (JWT)
2. Adicionar autorização baseada em roles
3. Implementar rate limiting
4. Usar HTTPS
5. Adicionar logs de auditoria
6. Validar CORS com domínios específicos

---
 
**Versão da Documentação:** 1.0  
**Desenvolvido por:** Ravi de Sousa Garcindo e Gabriel Sampaio
