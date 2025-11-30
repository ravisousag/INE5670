# Documentação - Código Arduino (PN532 NFC Reader)

## 📋 Índice
1. [Visão Geral](#visão-geral)
2. [Hardware Utilizado](#hardware-utilizado)
3. [Configuração Inicial](#configuração-inicial)
4. [Bibliotecas Utilizadas](#bibliotecas-utilizadas)
5. [Pinagem e Componentes](#pinagem-e-componentes)
6. [Fluxo Principal](#fluxo-principal)
7. [Funções Principais](#funções-principais)
8. [Sistema de Feedback](#sistema-de-feedback)
9. [Comunicação com API](#comunicação-com-api)
10. [Tratamento de Erros](#tratamento-de-erros)
11. [Modo de Operação](#modo-de-operação)

---

## 🎯 Visão Geral

O código Arduino implementa um **leitor NFC (Near Field Communication)** baseado no chip PN532 que se comunica com a API Flask através de requisições HTTP. O sistema possui dois modos:

1. **Modo de Verificação**: Valida se um cartão está autorizado
2. **Modo de Cadastro**: Registra um novo cartão na API

**Plataforma**: ESP8266 (Wemos D1 Mini ou similar)  
**Comunicação**: WiFi (2.4GHz)  
**Leitor NFC**: PN532 via I2C  
**API Backend**: Flask em `http://172.20.10.8:5000`

---

## 🔧 Hardware Utilizado

### ESP8266 (Microcontrolador Principal)
- **Processador**: Tensilica L106 32-bit
- **Frequência**: 80/160 MHz
- **Memória RAM**: 160 KB
- **Flash**: 4 MB
- **Conectividade**: WiFi 802.11 b/g/n

### PN532 (Leitor NFC)
- **Protocolo**: I2C (comunicação com ESP8266)
- **Frequência NFC**: 13.56 MHz
- **Tipo de Tag**: Suporta ISO14443A (Mifare Classic, DESFire, etc.)
- **Distância**: ~10 cm

### Periféricos
- **2x LEDs**: Verde e Vermelho (feedback visual)
- **1x Buzzer**: Feedback sonoro
- **1x Botão**: Ativar modo cadastro

---

## ⚙️ Configuração Inicial

### WiFi
```cpp
const char *ssid = "RaviPhone";      // SSID da rede
const char *pass = "12345678";       // Senha
```

### API Backend
```cpp
const char *api_server = "http://172.20.10.8:5000";
```

**⚠️ Importante**: Substituir `172.20.10.8` pelo IP da máquina com o backend Flask

### Configuração PN532 via I2C
```cpp
#define PN532_IRQ -1      // Pino de interrupção (não utilizado)
#define PN532_RESET -1    // Pino de reset (não utilizado)
Adafruit_PN532 nfc(PN532_IRQ, PN532_RESET);
```

---

## 📚 Bibliotecas Utilizadas

| Biblioteca | Versão | Função |
|------------|--------|--------|
| **ESP8266WiFi** | Built-in | Conectar ao WiFi |
| **ESP8266HTTPClient** | Built-in | Fazer requisições HTTP |
| **WiFiClient** | Built-in | Cliente WiFi para HTTP |
| **Wire** | Built-in | Protocolo I2C (PN532) |
| **Adafruit_PN532** | ^1.2.0 | Driver do leitor NFC PN532 |
| **ArduinoJson** | ^6.19.0 | Parse/serialização de JSON |

### Instalação no Arduino IDE
```
Sketch → Include Library → Manage Libraries
```

Buscar e instalar:
- `Adafruit PN532` (by Adafruit)
- `ArduinoJson` (by Benoit Blanchon)

---

## 🔌 Pinagem e Componentes

### Mapeamento de Pinos ESP8266

```
┌──────────────────────────────────────┐
│         ESP8266 (Wemos D1)           │
├──────────────────────────────────────┤
│ GPIO2  (D4)  → LED VERDE             │
│ GPIO12 (D6)  → LED VERMELHO          │
│ GPIO14 (D5)  → BUZZER                │
│ GPIO13 (D7)  → BOTÃO (INPUT_PULLUP)  │
│ GPIO4  (D2)  → I2C SDA (PN532)       │
│ GPIO5  (D1)  → I2C SCL (PN532)       │
│ GND    → GND (comum a todos)         │
│ 3V3    → 3V3 (alimentação)           │
└──────────────────────────────────────┘
```

### Componentes Eletrônicos

**LEDs:**
- Cátodo → GND (terra)
- Ânodo → Pino GPIO (através de resistor 220Ω)

**Buzzer:**
- Polo positivo → GPIO14 (D5)
- Polo negativo → GND

**Botão:**
- Um terminal → GPIO13 (D7)
- Outro terminal → GND
- Resistor pull-up interno habilitado

**PN532 (I2C):**
- SDA → GPIO4 (D2)
- SCL → GPIO5 (D1)
- GND → GND
- 3V3 → 3V3

---

## 🔄 Fluxo Principal

```
┌─────────────────────────────────────┐
│         INICIALIZAÇÃO (setup)       │
├─────────────────────────────────────┤
│ 1. Inicializar pinos (LEDs, Buzzer) │
│ 2. Conectar ao WiFi                 │
│ 3. Inicializar PN532                │
│ 4. Exibir mensagem de pronto        │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│      LOOP PRINCIPAL (loop)          │
├─────────────────────────────────────┤
│                                     │
│ ┌─ Verificar botão de cadastro ──┐ │
│ │ ├─ Pressionado?                │ │
│ │ │  └─ Ativar modo_cadastro     │ │
│ │ │  └─ Feedback verde + buzzer  │ │
│ │ └─ Debouncing: 300ms           │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ┌─ Ler cartão NFC ─────────────────┐ │
│ │ ├─ Cartão detectado?             │ │
│ │ │  ├─ Novo ou intervalo > 2s?    │ │
│ │ │  │  ├─ Modo cadastro?          │ │
│ │ │  │  │  ├─ Cadastrar (POST)     │ │
│ │ │  │  │  └─ Feedback OK/Erro     │ │
│ │ │  │  └─ Modo verificação        │ │
│ │ │  │     ├─ Validar (GET)        │ │
│ │ │  │     └─ Feedback Autorizado/ │ │
│ │ │  │        Negado               │ │
│ │ │  └─ Atualizar timestamps       │ │
│ │ └─ Cartão removido?              │ │
│ │    └─ Resetar flag card_present  │ │
│ └─────────────────────────────────┘ │
│                                     │
│ delay(100ms)                        │
└─────────────────────────────────────┘
              ↓
        (repete continuamente)
```

---

## 🔧 Funções Principais

### 1. **setup()**

Inicializa todos os componentes na inicialização.

```cpp
void setup()
```

**Operações:**
1. ✅ Inicia comunicação serial (115200 baud)
2. ✅ Configura pinos como OUTPUT (LEDs, Buzzer)
3. ✅ Configura pino botão como INPUT_PULLUP
4. ✅ Conecta ao WiFi (loop até conectar)
5. ✅ Inicializa PN532 (até 5 tentativas)
6. ✅ Configura PN532 em modo SAM (Single Activation Mode)
7. ✅ Exibe mensagem de sucesso

**Saída Serial Esperada:**
```
Connecting to RaviPhone
.....
WiFi connected!
IP Address: 192.168.x.x
Iniciando PN532 via I2C...
Buscando PN532...
Tentativa 1/5... Encontrado!
✓ PN532 inicializado com sucesso!

===========================================
SISTEMA PRONTO!
Aproxime um cartão para verificar acesso.
Pressione o botão para modo cadastro.
===========================================
```

---

### 2. **checkCardInAPI(String uid)**

Verifica se um cartão está autorizado consultando a API.

```cpp
bool checkCardInAPI(String uid)
```

**Parâmetros:**
- `uid` (String): UID do cartão em hexadecimal (ex: "a1b2c3d4")

**Requisição HTTP:**
```
GET http://172.20.10.8:5000/api/nfc/validate/{uid}
```

**Response Esperado (200 OK):**
```json
{
  "authorized": true,
  "message": "Acesso permitido para João Silva",
  "user": { /* dados do usuário */ },
  "log_id": 44
}
```

**Response Esperado (404 Not Found):**
```json
{
  "authorized": false,
  "message": "Cartão NFC não cadastrado",
  "log_id": 45
}
```

**Lógica:**
1. Verifica conexão WiFi
2. Monta URL com UID do cartão
3. Faz GET request
4. Parse do JSON com buffer 1024 bytes
5. Retorna `authorized`

**Retorno:**
- `true` → Cartão autorizado
- `false` → Cartão não autorizado ou erro

---

### 3. **addCardToAPI(String uid)**

Cadastra um novo cartão na API (modo cadastro).

```cpp
bool addCardToAPI(String uid)
```

**Parâmetros:**
- `uid` (String): UID do cartão em hexadecimal

**Requisição HTTP:**
```
POST http://172.20.10.8:5000/api/nfc/sync
Content-Type: application/json

{
  "nfc_card_uuid": "a1b2c3d4e5f6g7h8"
}
```

**Response Esperado (200 OK):**
```json
{
  "linked": true,
  "user": { /* dados do usuário */ },
  "pair_token": "AB12-CD34-EF56"
}
```

**Response Esperado (404 Not Found):**
```json
{
  "linked": false,
  "message": "Nenhuma sessão de pareamento ativa"
}
```

**Lógica:**
1. Verifica conexão WiFi
2. Cria JSON com UUID do cartão
3. Envia POST request
4. Parse do JSON do response
5. Retorna resultado

**Retorno:**
- `true` → Cadastro bem-sucedido
- `false` → Erro no cadastro

**⚠️ Importante:**
- Buffer JSON reduzido (128 bytes) para POST
- Leitura do stream direto (evita overflow de heap)
- Verifica `httpCode == 200 || 201`

---

### 4. **feedbackAutorizado()**

Feedback visual/sonoro para acesso autorizado.

```cpp
void feedbackAutorizado()
```

**Comportamento:**
- 🟢 LED Verde acende (100ms)
- 🔊 Buzzer toca 3 vezes (120ms ligado + 120ms desligado)
- ⏰ Permanece aceso por 1200ms total

**Padrão:**
```
tempo: 0────150────300────450────1650ms
LED:   ─────███████████████───────────
BUZ:   ─███─███─███─────────────────
```

---

### 5. **feedbackNegado()**

Feedback visual/sonoro para acesso negado.

```cpp
void feedbackNegado()
```

**Comportamento:**
- 🔴 LED Vermelho acende
- 🔊 Buzzer toca 2 vezes (400ms ligado + 250ms desligado)

**Padrão:**
```
tempo: 0────400────650────1050────1300ms
LED:   ─────████████████───────────
BUZ:   ─████████──────████████──────
```

---

### 6. **feedbackCadastroSucesso()**

Feedback de cadastro bem-sucedido.

```cpp
void feedbackCadastroSucesso()
```

**Comportamento:**
- 🟢 LED Verde pisca 5 vezes (100ms ligado + 100ms desligado)

---

### 7. **feedbackCadastroErro()**

Feedback de erro no cadastro.

```cpp
void feedbackCadastroErro()
```

**Comportamento:**
- 🔴 LED Vermelho pisca 3 vezes (250ms ligado + 200ms desligado)

---

### 8. **feedbackModoCadastro()**

Feedback ao ativar modo cadastro.

```cpp
void feedbackModoCadastro()
```

**Comportamento:**
- 🟢 LED Verde desliga
- 🔴 LED Vermelho liga (indicação contínua)

---

## 🎨 Sistema de Feedback

### Estados de LED

| Estado | LED Verde | LED Vermelho | Significado |
|--------|-----------|--------------|------------|
| Pronto | 🟢 LIGADO | 🔴 LIGADO | Sistema aguardando |
| Modo Cadastro | 🟢 DESLIGADO | 🔴 LIGADO | Aguardando cartão para cadastro |
| Autorizado (ativo) | 🟢 DESLIGADO | 🔴 DESLIGADO | Acesso concedido |
| Negado (ativo) | 🟢 DESLIGADO | 🔴 DESLIGADO | Acesso negado |
| Cadastro OK | 🟢 PISCANDO | 🔴 LIGADO | Cadastro realizado |
| Cadastro Erro | 🟢 LIGADO | 🔴 PISCANDO | Erro no cadastro |

### Padrões de Buzzer

| Evento | Padrão | Duração |
|--------|--------|---------|
| Autorizado | ✅✅✅ (curto) | 3x 120ms |
| Negado | ❌❌ (longo) | 2x 400ms |
| Cadastro OK | Silêncio + LED | N/A |
| Cadastro Erro | Silêncio + LED | N/A |
| Botão Pressionado | Continua | Contínuo |

---

## 📡 Comunicação com API

### Fluxo de Requisições

#### Modo Verificação
```
Arduino detecta cartão
    ↓
Converte UID para string hexadecimal
    ↓
GET /api/nfc/validate/{uid}
    ↓
Backend valida no banco de dados
    ↓
Retorna { authorized: true/false }
    ↓
Arduino toca feedback apropriado
```

#### Modo Cadastro
```
Botão pressionado
    ↓
modo_cadastro = true
    ↓
Arduino aguarda detecção de cartão
    ↓
Cartão detectado
    ↓
POST /api/nfc/sync com UUID
    ↓
Backend vincula UUID à sessão de pareamento
    ↓
Retorna { linked: true/false }
    ↓
Arduino toca feedback apropriado
    ↓
modo_cadastro = false
```

### Conversão de UID para String Hexadecimal

```cpp
String uidStr = "";
for (int i = 0; i < uidLength; i++) {
  if (uid[i] < 0x10) uidStr += "0";  // Padding com zero
  uidStr += String(uid[i], HEX);      // Converte para hex
}
// Exemplo: uid[] = {0xA1, 0xB2, 0xC3, 0xD4}
// Resultado: uidStr = "a1b2c3d4"
```

### Tamanho dos Buffers JSON

| Operação | Buffer | Razão |
|----------|--------|-------|
| POST /nfc/sync | 128 bytes | JSON pequeno (apenas UUID) |
| GET /nfc/validate | 1024 bytes | Response com dados de usuário |
| Response parsing | Stream direto | Evita overflow de heap |

---

## ⚠️ Tratamento de Erros

### Erros de Conexão WiFi

```cpp
if (WiFi.status() != WL_CONNECTED) {
  Serial.println("WiFi não conectado!");
  return false;
}
```

**Ação**: Retorna `false` e não faz requisição

---

### Erros de Conexão HTTP

```cpp
if (!http.begin(client, url)) {
  Serial.println("Erro ao iniciar conexão HTTP!");
  return false;
}

int httpCode = http.GET();
if (httpCode <= 0) {
  Serial.printf("Erro GET: %s\n", http.errorToString(httpCode).c_str());
  http.end();
  return false;
}
```

**Códigos de Erro:**
- Negativo: Erro de conexão
- 0: Timeout
- 1: Erro de conexão
- 2: Envio falhou
- 3: Resposta inválida

---

### Erros de Parse JSON

```cpp
StaticJsonDocument<1024> json;
DeserializationError err = deserializeJson(json, payload);

if (err) {
  Serial.print("Erro ao decodificar JSON: ");
  Serial.println(err.f_str());
  return false;
}
```

**Erros Possíveis:**
- `NoMemory`: Buffer muito pequeno
- `IncompleteInput`: JSON incompleto
- `InvalidInput`: JSON malformado
- `EmptyInput`: Sem dados

---

## 🔄 Modo de Operação

### Modo Verificação (Normal)

**Fluxo:**
```
Cartão aproximado
    ↓
PN532 detecta (readPassiveTargetID)
    ↓
Extrai UID
    ↓
Verifica intervalo (2s desde última leitura)
    ↓
Valida com API (/nfc/validate)
    ↓
Toca feedback apropriado
    ↓
Aguarda remoção do cartão
```

**Código:**
```cpp
if (!card_present || (t - last_read_time > READ_INTERVAL)) {
  // Processa cartão
  bool authorized = checkCardInAPI(uidStr);
  if (authorized) feedbackAutorizado();
  else feedbackNegado();
}
```

---

### Modo Cadastro (Pareamento)

**Fluxo:**
```
1. Usuário abre app e tapa em "Associar Cartão"
2. App chama POST /api/nfc/pair_start
3. Backend gera pair_token e aguarda pareamento
4. App entra em polling de status
5. Usuário pressiona botão (BOTAO_CADASTRO)
6. modo_cadastro = true
7. Arduino aguarda cartão
8. Cartão aproximado
9. Arduino chama POST /api/nfc/sync
10. Backend vincula UUID ao usuário
11. Arduino toca feedback de sucesso
12. modo_cadastro = false
13. App detecta vinculado = true
14. Modal fecha
```

**Código:**
```cpp
if (digitalRead(BOTAO_CADASTRO) == LOW && !modo_cadastro) {
  if (t - last_button_time > DEBOUNCE_DELAY) {
    modo_cadastro = true;
    Serial.println("\n=== MODO CADASTRO ATIVADO! ===");
    feedbackModoCadastro();
  }
}

if (found) {
  if (modo_cadastro) {
    bool ok = addCardToAPI(uidStr);
    if (ok) feedbackCadastroSucesso();
    else feedbackCadastroErro();
    modo_cadastro = false;
  }
}
```

---

## 🔐 Segurança e Boas Práticas

### Implementado

✅ Debouncing do botão (300ms)  
✅ Intervalo de leitura mínimo (2000ms)  
✅ Verificação de conexão WiFi antes de requisições  
✅ Tratamento de erros HTTP  
✅ Buffers estáticos para evitar overflow  
✅ Serial debug para troubleshooting  

### Recomendações para Produção

⚠️ **WiFi**: Usar WPA2 (trocar credenciais hardcoded)  
⚠️ **API**: Usar HTTPS em produção  
⚠️ **Timeouts**: Adicionar timeout nas requisições HTTP  
⚠️ **Reconexão**: Implementar auto-reconexão WiFi  
⚠️ **EEPROM**: Armazenar credenciais de forma segura  

---

## 🐛 Troubleshooting

| Problema | Causa | Solução |
|----------|-------|---------|
| PN532 não encontrado | I2C não conectado | Verificar fiação SDA/SCL |
| WiFi não conecta | SSID/Senha incorretos | Alterar const ssid/pass |
| API retorna 404 | URL ou IP incorretos | Verificar `api_server` |
| LED não acende | Pino GPIO incorreto | Revisar #define LED_* |
| Botão não funciona | Pino invertido | Verificar digitalRead |
| JSON parse falha | Buffer muito pequeno | Aumentar CAPACITY |

---

## 📊 Consumo de Recursos

| Recurso | Uso |
|---------|-----|
| Memória RAM | ~50-80 KB |
| Flash Program | ~300 KB |
| Pinos GPIO usados | 6 (D1-D7) |
| Protocolo I2C | Sim (PN532) |
| Baud Rate Serial | 115200 |

---

## 🚀 Como Compilar e Enviar

### 1. Configurar Arduino IDE
```
Boards → Board Manager
Buscar: ESP8266
Instalar: esp8266 by ESP8266 Community
```

### 2. Selecionar Placa
```
Tools → Board → ESP8266 Boards → Wemos D1 Mini (ou similar)
Tools → Upload Speed → 115200
Tools → CPU Frequency → 80 MHz
```

### 3. Selecionar Porta
```
Tools → Port → /dev/ttyUSB0 (Linux/Mac) ou COM3 (Windows)
```

### 4. Compilar e Enviar
```
Sketch → Upload
ou Ctrl+U
```

### 5. Abrir Serial Monitor
```
Tools → Serial Monitor → 115200 Baud
```

---

**Data:** 30 de novembro de 2024  
**Versão:** 1.0  
**Hardware**: ESP8266 + PN532  
**Framework**: Arduino IDE 1.8.19+
