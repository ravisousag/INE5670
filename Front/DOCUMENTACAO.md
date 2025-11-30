# NFC Reader App - Documentação Técnica Completa

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Dependências e Versões](#dependências-e-versões)
3. [Arquitetura do Projeto](#arquitetura-do-projeto)
4. [Principais Componentes](#principais-componentes)
5. [Fluxo do Front](#fluxo-do-front)
6. [Modelos de Dados](#modelos-de-dados)
7. [Serviços de API](#serviços-de-api)

---

## 🎯 Visão Geral

**NFC Reader App** é uma aplicação Flutter/Dart que funciona como sistema de gerenciamento de usuários com integração de cartões NFC. A aplicação permite:

- ✅ Gerenciar usuários (CRUD)
- ✅ Associar/desassociar cartões NFC a usuários
- ✅ Visualizar logs de acesso NFC
- ✅ Interface intuitiva com navegação por abas

**Plataformas suportadas**: Android, iOS, Web, Windows, Linux, macOS

**URL Base Backend**: `http://127.0.0.1:5000`

---

## 📦 Dependências e Versões

### Versão do Aplicativo
- **Nome**: `nfc_reader_app`
- **Versão**: `0.1.0`

### Ambiente Dart/Flutter
```yaml
environment:
  sdk: ^3.10.0
```

### Dependências Principais

| Dependência | Versão | Finalidade |
|-------------|--------|-----------|
| `flutter` | SDK | Framework de UI multiplataforma |
| `http` | ^1.4.0 | Requisições HTTP para API REST |
| `intl` | ^0.18.0 | Formatação de data/hora internacionalizadas |
| `flutter_lints` | ^6.0.0 | Regras de linting para análise estática |
| `flutter_test` | SDK | Framework para testes unitários |

### Resumo de Dependências
```yaml
# pubspec.yaml - Production Dependencies
dependencies:
  flutter:
    sdk: flutter
  http: ^1.4.0          # Comunicação HTTP com backend
  intl: ^0.18.0         # Formatação de datas/horas

# Development Dependencies
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0 # Análise estática de código
```

---

## 🏗️ Arquitetura do Projeto

### Estrutura de Diretórios

```
Front/
├── lib/                          # Código fonte principal
│   ├── main.dart                 # Ponto de entrada da aplicação
│   ├── app.dart                  # Widget raiz (NFCApp)
│   ├── api_service.dart          # Serviço centralizado de API
│   │
│   ├── models/                   # Modelos de dados
│   │   ├── user.dart             # Modelo de usuário
│   │   └── log_entry.dart        # Modelo de entrada de log
│   │
│   ├── pages/                    # Páginas/Telas
│   │   ├── home_page.dart        # Tela inicial
│   │   ├── users_page.dart       # Gerenciamento de usuários
│   │   └── logs_page.dart        # Visualização de logs
│   │
│   ├── widgets/                  # Componentes reutilizáveis
│   │   ├── user_modal.dart       # Modal para criar/editar/visualizar usuários
│   │   └── user_nfc_modal.dart   # Modal para vincular cartão NFC
│   │
│   └── services/
│       └── nfc_service.dart      # Serviço de integração NFC
│
├── android/                      # Configuração Android
├── ios/                          # Configuração iOS
├── web/                          # Arquivos web
├── windows/                      # Configuração Windows
├── linux/                        # Configuração Linux
├── macos/                        # Configuração macOS
│
├── pubspec.yaml                  # Configuração de dependências
├── analysis_options.yaml         # Regras de análise estática
├── README.md                     # Guia geral
└── DOCUMENTACAO.md              # Esta documentação
```

### Padrões Arquiteturais

A aplicação segue uma arquitetura **em camadas**:

1. **Camada de Apresentação (UI/Widgets)**
   - `app.dart` - Aplicação principal com navegação
   - `pages/` - Telas e páginas
   - `widgets/` - Componentes reutilizáveis

2. **Camada de Lógica (Services)**
   - `api_service.dart` - Requisições HTTP
   - `nfc_service.dart` - Integração NFC

3. **Camada de Dados (Models)**
   - `models/` - Estruturas de dados (User, LogEntry)

---

## 🎨 Principais Componentes

### 1. **NFCApp** (`app.dart`)
Widget raiz da aplicação que gerencia a navegação.

```dart
class NFCApp extends StatefulWidget
```

**Responsabilidades:**
- Gerenciar índice da aba ativa
- Controlar navegação entre páginas
- Fornecer método `goTo()` para navegação programática
- Construir interface com AppBar, BottomNavigationBar

**Props:**
- `_currentIndex` - Índice da aba ativa (0=Home, 1=Users, 2=Logs)
- `_pages` - Lista de páginas renderizadas

---

### 2. **HomePage** (`lib/pages/home_page.dart`)
Tela inicial com menu de navegação.

```dart
class HomePage extends StatelessWidget
```

**Funcionalidades:**
- Exibe título e descrição do sistema
- Apresenta 2 cards de menu:
  - Gerenciar Usuários
  - Logs de Acesso

**Props:**
- `goTo: Function(String)` - Callback para navegar

---

### 3. **UsersPage** (`lib/pages/users_page.dart`)
Gerenciamento completo de usuários com CRUD.

```dart
class UsersPage extends StatefulWidget
```

**Funcionalidades:**
- ✅ Listar usuários com busca por nome/CPF/email
- ✅ Criar novo usuário (botão "Novo Usuário")
- ✅ Editar usuário (ícone de edição)
- ✅ Visualizar detalhes (ícone de olho)
- ✅ Deletar usuário (ícone de lixo)
- ✅ Filtro em tempo real

**Estado:**
- `users` - Lista de todos os usuários
- `filtered` - Lista filtrada por busca
- `loading` - Estado de carregamento
- `search` - Texto de busca

---

### 4. **LogsPage** (`lib/pages/logs_page.dart`)
Visualização de logs de acesso NFC.

```dart
class LogsPage extends StatefulWidget
```

**Funcionalidades:**
- Listar todos os logs de acesso
- Exibir UUID do cartão NFC
- Mostrar data/hora formatada (dd/MM/yyyy HH:mm)
- Status visual (Sucesso/Não encontrado)

**Estado:**
- `logs` - Lista de registros de acesso
- `loading` - Estado de carregamento

---

### 5. **UserModal** (`lib/widgets/user_modal.dart`)
Modal para criar, editar ou visualizar usuários.

```dart
class UserModal extends StatefulWidget
```

**Modos:**
- `create` - Criar novo usuário
- `edit` - Editar usuário existente
- `view` - Visualizar detalhes (read-only)

**Funcionalidades:**
- Campos: Nome, CPF, Email, Telefone
- Seção NFC com:
  - Indicador visual de cartão associado
  - Botão para associar cartão (modo edit/create)
  - Botão para remover cartão vinculado
- Validação de campos obrigatórios

**Callbacks:**
- `onSuccess` - Chamado após sucesso (atualiza lista)

---

### 6. **UserNfcModal** (`lib/widgets/user_nfc_modal.dart`)
Modal para vincular cartão NFC a um usuário.

```dart
class UserNfcModal extends StatefulWidget
```

**Funcionalidades:**
- Iniciar processo de pareamento
- Consultar status de pareamento
- Permitir usuário scanear cartão NFC
- Exibir progresso com spinner

**Props:**
- `cpf` - CPF do usuário para vincular
- `onSuccess` - Callback após sucesso

---

### 7. **ApiService** (`lib/api_service.dart`)
Serviço centralizado de requisições HTTP.

```dart
class ApiService
```

**Métodos de Usuários:**
- `getUsers()` - GET `/api/users`
- `createUser(body)` - POST `/api/users`
- `updateUser(cpf, body)` - PUT `/api/users/cpf/{cpf}`
- `deleteUser(cpf)` - DELETE `/api/users/cpf/{cpf}`

**Métodos de Logs:**
- `getLogs()` - GET `/api/logs`

**Métodos NFC:**
- `linkNfcToUser(uuid, cpf)` - Vincular cartão
- `unlinkNfcFromUser(cpf)` - Desvinculcar cartão

**Tratamento de Erros:**
- Status codes 200-299: sucesso
- Caso contrário: lança `Exception` com mensagem de erro

---

### 8. **NfcService** (`lib/services/nfc_service.dart`)
Serviço de integração com backend para operações NFC.

```dart
class NfcService
```

**Métodos:**
- `linkNfcToUser(uuid, cpf)` - PUT `/api/nfc/link`
- `unlinkNfcFromUser(cpf)` - PUT `/api/nfc/unlink`
- `startPairing(cpf)` - POST `/api/nfc/pair_start`
- `getPairStatus(token)` - GET `/api/nfc/pair_status/{token}`

**Retornos:**
- `Map<String, dynamic>` com resposta do backend

---

## 🔄 Fluxo do Front

### 1. **Inicialização da Aplicação**

```
main.dart
    ↓
runApp(NFCApp)
    ↓
NFCApp._NFCAppState.initState()
    ↓
Constrói lista de páginas:
  - HomePage
  - UsersPage
  - LogsPage
    ↓
MaterialApp com BottomNavigationBar
```

### 2. **Fluxo de Navegação**

```
BottomNavigationBar (3 abas)
    │
    ├─→ Home (index 0)
    │       └─ HomePage
    │           ├─ Card: "Gerenciar Usuários" → go('users')
    │           └─ Card: "Logs de Acesso" → go('logs')
    │
    ├─→ Usuários (index 1)
    │       └─ UsersPage
    │           ├─ Listar usuários
    │           ├─ Filtro em tempo real
    │           ├─ Botão "Novo Usuário" → openModal(create)
    │           └─ Ações por usuário:
    │               ├─ Visualizar → openModal(view)
    │               ├─ Editar → openModal(edit)
    │               └─ Deletar → delete
    │
    └─→ Logs (index 2)
            └─ LogsPage
                └─ Listar logs com status
```

### 3. **Fluxo de Gerenciamento de Usuários**

#### **Criar Usuário:**
```
"Novo Usuário" button
    ↓
UserModal(mode: create)
    ↓
Preencher campos (Nome, CPF, Email, Telefone)
    ↓
Botão "Criar"
    ↓
ApiService.createUser(body)
    ↓ POST /api/users
    ↓
Sucesso? 
  ├─ SIM → Dialog: "Deseja associar cartão NFC?"
  │         ├─ SIM → UserNfcModal
  │         └─ NÃO → Fecha modal
  └─ NÃO → Exibe erro em SnackBar
    ↓
UsersPage.fetchUsers() (atualiza lista)
```

#### **Editar Usuário:**
```
Botão "Editar" na lista
    ↓
UserModal(mode: edit, user: user)
    ↓
Campos editáveis: Nome, Email, Telefone
(CPF é read-only)
    ↓
Seção NFC:
  ├─ Sem cartão: Botão "Associar Cartão"
  └─ Com cartão: Botão "Remover Cartão"
    ↓
Botão "Salvar"
    ↓
ApiService.updateUser(cpf, body)
    ↓ PUT /api/users/cpf/{cpf}
    ↓
Sucesso? 
  ├─ SIM → Fechar modal
  └─ NÃO → Exibe erro
    ↓
UsersPage.fetchUsers() (atualiza)
```

#### **Deletar Usuário:**
```
Botão "Deletar" na lista
    ↓
AlertDialog de confirmação
    ↓
Usuário confirma?
  ├─ SIM → ApiService.deleteUser(cpf)
  │         ↓ DELETE /api/users/cpf/{cpf}
  │         ↓
  │         └─ UsersPage.fetchUsers()
  └─ NÃO → Cancela operação
```

#### **Visualizar Usuário:**
```
Botão "Visualizar (olho)" na lista
    ↓
UserModal(mode: view, user: user)
    ↓
Todos os campos em read-only
    ↓
Botão "Fechar" (sem ações)
```

### 4. **Fluxo de Associação de Cartão NFC**

```
Usuário novo criado OU Botão "Associar Cartão"
    ↓
UserNfcModal aberto
    ↓
NfcService.startPairing(cpf)
    ↓ POST /api/nfc/pair_start
    ↓ Retorna: {pair_token, expires_at, vinculado, user_id}
    ↓
Exibe mensagem: "Aproxime o cartão"
Spinner de carregamento inicia
    ↓
Pool de requisições: NfcService.getPairStatus(pair_token)
    ↓ GET /api/nfc/pair_status/{pair_token}
    ↓ A cada 500ms
    ↓
Quando backend detecta NFC:
    ├─ Cartão vinculado com sucesso
    ├─ Backend retorna: {status: "linked", nfc_uuid: "..."}
    └─ Modal fecha e atualiza usuário
```

### 5. **Fluxo de Visualização de Logs**

```
Aba "Logs" ou Card na Home
    ↓
LogsPage.initState()
    ↓
ApiService.getLogs()
    ↓ GET /api/logs
    ↓ Retorna lista de LogEntry
    ↓
Renderiza ListView com:
  ├─ UUID do cartão NFC
  ├─ Data/Hora formatada
  └─ Status visual:
      ├─ Verde (sucesso): Usuário encontrado
      └─ Vermelho (erro): Cartão não vinculado/usuário não existe
```

---

## 📊 Modelos de Dados

### **User** (`lib/models/user.dart`)

```dart
class User {
  final int id;              // ID único do usuário
  final String name;         // Nome completo
  final String cpf;          // CPF (documento único)
  final String email;        // Email
  final String phone;        // Telefone
  final String? nfcCardUuid; // UUID do cartão NFC (opcional)
}
```

**Factory:**
```dart
User.fromJson(Map<String, dynamic> json)
```

---

### **LogEntry** (`lib/models/log_entry.dart`)

```dart
class LogEntry {
  final int id;              // ID do log
  final String nfcUuid;      // UUID do cartão NFC
  final bool userExists;     // Cartão vinculado a usuário?
  final int? userId;         // ID do usuário (se existir)
  final String timestamp;    // Data/hora em ISO 8601
}
```

**Factory:**
```dart
LogEntry.fromJson(Map<String, dynamic> json)
```

---

## 🔌 Serviços de API

### **Base URL**
```
http://127.0.0.1:5000
```

### **Endpoints de Usuários**

#### GET `/api/users`
Retorna lista de usuários

**Response:**
```json
{
  "users": [
    {
      "id": 1,
      "name": "João Silva",
      "cpf": "12345678900",
      "email": "joao@example.com",
      "phone": "11999999999",
      "nfc_card_uuid": null
    }
  ]
}
```

#### POST `/api/users`
Criar novo usuário

**Body:**
```json
{
  "name": "João Silva",
  "cpf": "12345678900",
  "email": "joao@example.com",
  "phone": "11999999999"
}
```

**Response (201/200):**
```json
{
  "message": "Usuário criado com sucesso",
  "user": { /* User object */ }
}
```

#### PUT `/api/users/cpf/{cpf}`
Atualizar usuário

**Body:**
```json
{
  "name": "Novo Nome",
  "email": "novo@example.com",
  "phone": "11888888888"
}
```

**Response:**
```json
{
  "message": "Usuário atualizado com sucesso"
}
```

#### DELETE `/api/users/cpf/{cpf}`
Deletar usuário

**Response:**
```json
{
  "message": "Usuário deletado com sucesso"
}
```

### **Endpoints de NFC**

#### POST `/api/nfc/pair_start`
Iniciar processo de pareamento

**Body:**
```json
{
  "cpf": "12345678900"
}
```

**Response (201):**
```json
{
  "pair_token": "abc123...",
  "expires_at": "2024-11-30T15:30:00",
  "vinculado": false,
  "user_id": 1
}
```

#### GET `/api/nfc/pair_status/{pair_token}`
Consultar status do pareamento

**Response (200):**
```json
{
  "status": "linked",
  "nfc_uuid": "uuid-do-cartao",
  "user_id": 1
}
```

#### PUT `/api/nfc/link`
Vincular cartão NFC a usuário

**Body:**
```json
{
  "nfc_card_uuid": "uuid-do-cartao",
  "cpf": "12345678900"
}
```

**Response (200):**
```json
{
  "message": "Cartão vinculado com sucesso"
}
```

#### PUT `/api/nfc/unlink`
Desvinculcar cartão NFC

**Body:**
```json
{
  "cpf": "12345678900"
}
```

**Response (200):**
```json
{
  "message": "Cartão desvinculado com sucesso"
}
```

### **Endpoints de Logs**

#### GET `/api/logs`
Retorna lista de logs de acesso

**Response:**
```json
{
  "logs": [
    {
      "id": 1,
      "nfc_uuid": "uuid-123",
      "user_exists": true,
      "user_id": 1,
      "timestamp": "2024-11-30T15:25:00"
    }
  ]
}
```

---

## 🚀 Executando a Aplicação

```bash
# Instalar dependências
flutter pub get

# Executar em desenvolvimento
flutter run

# Executar em plataforma específica
flutter run -d chrome      # Web
flutter run -d emulator-5554  # Android

# Build para produção
flutter build apk --release
flutter build ios --release
flutter build web
```

---

## ✅ Checklist de Funcionalidades

- [x] Listar usuários
- [x] Criar usuários
- [x] Editar usuários
- [x] Deletar usuários
- [x] Buscar/filtrar usuários
- [x] Associar cartão NFC
- [x] Desassociar cartão NFC
- [x] Visualizar logs
- [x] Navegação entre telas
- [x] Tratamento de erros
- [x] Estados de carregamento

---

**Data:** 30 de novembro de 2024  
**Versão da Documentação:** 1.0  
**Desenvolvido por:** Ravi de Sousa Garcindo e Gabriel Sampaio
